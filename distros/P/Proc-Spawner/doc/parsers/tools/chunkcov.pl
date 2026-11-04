#!/usr/bin/perl
# Chunk coverage of scripts: cut each script into maximal accepted runs and rejected top-level constructs,
# then measure what an executor that runs accepted runs itself and hands the rest to sh would get.
# A rejected construct ends at the shortest run of whole lines from the failure's chain start that
# bash -n accepts without complaint (so an if ... fi or a here-document is one rejected piece).
use strict; use warnings; use Proc::ShellSubset; use JSON::PP;   # run with perl -Ilib (the distribution's lib/)
$ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my %ALL = map +($_ => 1), qw(assign param_ops if while for case read);

sub bash_ok {   # bash -n accepts the text, with nothing on stderr (a cut here-document only warns)
  my $t = shift; my $pid = open my $h, '-|' // die "fork: $!";
  if (!$pid) { open STDERR, '>&', \*STDOUT; exec 'bash', '-n', '-c', $t; exit 127 }
  local $/; my $o = <$h>; close $h; !$? && !length $o }
sub lines { scalar grep /\S/ && !/^\s*#/, split /\n/, shift }

sub pieces {   # [accepted?, text], in order
  my ($s, %o) = @_; my @p;
  while ($s =~ /\S/) {
    my $r = Proc::ShellSubset::parse($s, empty => 1, %o);
    if (ref $r eq 'ARRAY') { push @p, [1, $s]; last }
    push @p, [1, substr $s, 0, $r->{last}] if $r->{last};
    my $rest = substr $s, $r->{last}; my @L = split /(?<=\n)/, $rest; my $end = length $rest;
    for my $k (1 .. @L) { my $t = join '', @L[0 .. $k - 1]; if (bash_ok($t)) { $end = length $t; last } }
    push @p, [0, substr $rest, 0, $end]; $s = substr $rest, $end }
  grep lines($_->[1]), @p }

my $STATE = qr/(?:^|[;&|({]\s*|\b(?:then|do|else)\s+)(?:cd|export|unset|set|shift|local|read|source|\.|trap|umask|ulimit|readonly|declare|typeset|eval)\b/m;
sub defines {   # names a rejected piece may set (heuristic)
  my $t = shift; my %n;
  $n{$1}++ while $t =~ /(?:^|[\s;&|(])([A-Za-z_]\w*)\+?=/g;
  $n{$_}++ for map { split ' ' } $t =~ /\bread\s+(?:-\w+\s+)*((?:[A-Za-z_]\w*\s*)+)/g;
  $n{$1}++ while $t =~ /\bfor\s+([A-Za-z_]\w*)/g;
  $n{$1}++ while $t =~ /^\s*(?:function\s+)?([A-Za-z_][\w-]*)\s*\(\s*\)/mg;
  keys %n }

my (%seen, %T, %A);
open my $h, '<', 'samples.jsonl' or die;
while (<$h>) { my $x = decode_json($_); next unless $x->{kind} eq 'script'; (my $src = $x->{src}) =~ s/^(\w+).*/$1/;
  $src = { 'pure' => 'pure-*-bible' }->{$src} // $src;
  next if $seen{$x->{text}}++; my $n = lines($x->{text}) or next;
  for my $mode (qw(default options)) {
    my @p = pieces($x->{text}, $mode eq 'options' ? %ALL : ());
    my $ok = 0; $ok += lines($_->[1]) for grep $_->[0], @p;
    my $pre = 0; for (@p) { last unless $_->[0]; $pre += lines($_->[1]) }
    my $sw = grep { !$p[$_][0] && ($_ == 0 || $p[$_ - 1][0]) } 0 .. $#p;   # handoffs to sh: runs of rejected pieces
    my $comp = 0; $comp += lines($_->[1]) for grep { !$_->[0] && lines($_->[1]) > 1 } @p;
    my ($hz, $cdh) = (0, 0);   # a rejected piece sets something a later accepted piece uses
    for my $i (grep !$p[$_][0], 0 .. $#p) {
      my @later = map $_->[1], grep $_->[0], @p[$i + 1 .. $#p] or next;
      my @d = defines($p[$i][1]); my $lt = join "\n", @later;
      $hz ||= grep { $lt =~ /\$\{?\Q$_\E\b|(?:^|[;&|]\s*)\Q$_\E\b/m } @d;
      $cdh ||= $p[$i][1] =~ /(?:^|[;&|({]\s*|\b(?:then|do|else)\s+)cd\b/m }
    $A{$mode}{$src}++;   # all scripts, for "N of M"
    next if $ENV{PARTIAL_ONLY} && $ok == $n;   # only scripts not translatable as a whole
    my $t = $T{$mode}{$src} //= {}; $t->{s}++; $t->{swm} += $sw, $t->{nm}++ if $ok && $ok < $n; $t->{n} += $n; $t->{ok} += $ok; $t->{pre} += $pre; $t->{sw} += $sw; $t->{comp} += $comp;
    $t->{full}++ if $ok == $n; $t->{none}++ if !$ok; $t->{half}++ if $ok && $ok < $n && 2 * $ok >= $n;
    $t->{hz}++ if $hz; $t->{cdh}++ if $cdh; $t->{mixed}++ if $ok && $ok < $n } }

for my $mode (qw(default options)) {
  print "\n== $mode\n";
  printf "%-14s %9s %6s %8s %8s %6s %6s %6s %8s %9s %7s %7s %7s\n", qw(source scripts lines accepted prefix full none >=half handoffs h(mixed) multi dep cd-dep);
  for my $src (sort keys %{$T{$mode}}) { my $t = $T{$mode}{$src}; $t->{$_} //= 0 for qw(full none half hz cdh mixed);
    printf "%-14s %9s %6d %7.0f%% %7.0f%% %6d %6d %6d %8.1f %9s %6.0f%% %7d %7d\n", $src, "$t->{s}/$A{$mode}{$src}", $t->{n},
      100 * $t->{ok} / $t->{n}, 100 * $t->{pre} / $t->{n}, $t->{full}, $t->{none}, $t->{half},
      $t->{sw} / $t->{s}, $t->{nm} ? sprintf('%.1f', $t->{swm} / $t->{nm}) : '-', 100 * $t->{comp} / ($t->{n} - $t->{ok} || 1), $t->{hz}, $t->{cdh} } }
