#!/usr/bin/perl
# Run ShellSubset over samples.jsonl. One-liners are parsed whole; scripts are cut into accepted chunks
# and skipped regions. Accepted text is cross-checked with dash -n and bash -n.
# Writes results.jsonl (one record per one-liner, chunk or skipped region) and prints a summary.
use strict; use warnings; use Proc::ShellSubset; use JSON::PP;   # run with perl -Ilib (the distribution's lib/)
my $J = JSON::PP->new->canonical; $ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my (%seen, %st, %why, %ex, %bad);
open my $res, '>', 'results.jsonl' or die $!;

sub syn {   # does $sh -n accept the text?
  my ($sh, $t) = @_; local $SIG{__WARN__} = sub {};
  open my $save, '>&', \*STDERR; open STDERR, '>', '/dev/null';
  my $ok = system($sh, '-n', '-c', $t) == 0; open STDERR, '>&', $save; $ok }
sub lines { scalar grep /\S/ && !/^\s*#/, split /\n/, shift }
sub reason { my $e = shift; $e =~ s/ \@\d+$//; $e }

sub accepted {
  my ($src, $id, $t, $n, $l, $part) = @_;   # $l: for a script chunk, its "<pre>:<first line>" (lines of it get IDs in group.pl)
  my @no = grep !syn($_, $t), qw(dash bash);
  $bad{$src}{"@no"}++, push @{$ex{$src}{"!! accepted, rejected by @no"}}, $t if @no;
  $st{$src}{ok}++; $st{$src}{okl} += $n;
  print $res $J->encode({ src => $src, id => $id, v => 'ok', shells => "@no", text => $t, defined $l ? (l => $l) : (), $part ? (part => 1) : () }), "\n" }
sub rejected {
  my ($src, $id, $e, $t, $n) = @_; my $r = reason($e);
  $why{$src}{$r}{n}++; $why{$src}{$r}{l} += $n; push @{$ex{$src}{$r}}, $t;
  $st{$src}{rej}++; $st{$src}{rejl} += $n;
  print $res $J->encode({ src => $src, id => $id, v => 'rej', why => $r, text => $t }), "\n" }

sub chunks {   # script: accepted prefixes up to the last top-level terminator, then skip the failing line
  my ($src, $id, $s, $loc) = @_; my ($k, $base, $all) = (0, 0, $s);
  my $at = sub {   # absolute offset -> [line, column] in the source
    my $o = shift; my $pre = substr $all, 0, $o; my $nl = ($pre =~ tr/\n//);
    [ $loc->{line0} + $nl, $o - (rindex($pre, "\n") + 1) + 1 ] };
  my $pid = sub {   # ID of the piece [a, b): <pre>:<line>[c<col>][-<end line>]
    my ($a, $b) = @_; $b-- while $b > $a + 1 && substr($all, $b - 1, 1) =~ /\s/;
    my ($l, $c) = @{$at->($a)}; my ($e) = @{$at->($b - 1)};
    "$loc->{pre}:$l" . ($c > 1 ? "c$c" : '') . ($e > $l ? "-$e" : '') };
  while ($s =~ /\S/) {
    my $r = Proc::ShellSubset::parse($s, empty => 1);
    if (ref $r eq 'ARRAY') { accepted($src, "$id#" . $k++, $s, lines($s), "$loc->{pre}:" . $at->($base)[0]) if lines($s); last }
    my ($last, $pos, $err) = @$r{qw(last pos error)};
    my $pre = substr $s, 0, $last;
    accepted($src, "$id#" . $k++, $pre, lines($pre), "$loc->{pre}:" . $at->($base)[0],
             $last < length $s && substr($s, $last - 1, 1) ne "\n") if lines($pre);   # ends inside a line
    my $end;
    if ($err eq 'here-document' and substr($s, $pos) =~ /\A<<-?[ \t]*(["']?)\\?(\w+)\1/
        and substr($s, $pos) =~ /^\t*\Q$2\E[ \t]*(?:\n|\z)/m) { $end = $pos + $+[0] }
    else { substr($s, $pos) =~ /\A(?:[^\n]*\\\n)*[^\n]*(?:\n|\z)/; $end = $pos + $+[0] }
    $end = $last + 1 if $end <= $last;
    my $skip = substr $s, $last, $end - $last;
    (my $lead = $skip) =~ s/\S.*//s;   # the ID starts at the first non-blank character
    rejected($src, $pid->($base + $last + length $lead, $base + $end), $err, $skip, lines($skip) || 1);
    $base += $end; $s = substr $s, $end } }

while (<>) {
  my $h = $J->decode($_); my ($src, $t) = @$h{qw(src text)};
  $src .= ":$h->{tag}" if $h->{tag} && $src eq 'shellcheck';
  next if $seen{"$src\0$t"}++;
  $st{$src}{n}++;
  if ($h->{kind} eq 'script') { chunks($src, $h->{id}, $t, $h->{loc}); next }
  my $r = Proc::ShellSubset::parse($t);
  ref $r eq 'ARRAY' ? accepted($src, $h->{id}, $t, 1) : rejected($src, $h->{id}, $r->{error}, $t, 1) }

for my $src (sort keys %st) {
  my $s = $st{$src}; $s->{$_} //= 0 for qw(ok rej okl rejl);
  printf "\n=== %s: %d samples; accepted %d pieces (%d lines), rejected %d pieces (%d lines)\n",
    $src, $s->{n}, @$s{qw(ok okl rej rejl)};
  printf "    accepted but rejected by %s: %d\n", $_, $bad{$src}{$_} for sort keys %{$bad{$src} // {}};
  my $w = $why{$src} // {};
  for my $r (sort { $w->{$b}{l} <=> $w->{$a}{l} || $a cmp $b } keys %$w) {
    my @e = sort { length $a <=> length $b } @{$ex{$src}{$r}};
    printf "  %5d lines %5d pieces  %s\n", $w->{$r}{l}, $w->{$r}{n}, $r;
    printf "               | %s\n", substr($_ =~ s/\n/\\n/gr, 0, 100) for @e[0 .. ($#e < 2 ? $#e : 2)] } }
