#!/usr/bin/perl
# large-subset-yardsticks.pl (2026-11-02, second version; see doc/large-subset/large-subset-state.md). Two yardsticks
# per source, decided by the SHELLS only, never by our parser:
#   upper ("nothing bogus found"): dash -n and bash --posix -n both accept the sample, and it uses no blatant difference;
#   lower ("compatible"): within the upper yardstick, and it uses no subtle difference either.
# The differences of a sample come from large-subset-features.pl: its text detector, and ShellCheck's portability codes
# (SC3xxx, from large-scan.jsonl) mapped to a verdict there. Differences of class X (the subset runs a program in place
# of both shells' builtin) exclude nothing: the program beats blatant. The first version (until 2026-11-02) sorted our
# parser's rejection messages instead, which made the yardsticks depend on the parser they measure.
# Verdicts kept by hand (-r FILE, default large-subset-verdicts.txt next to this script) override the detector's: per
# feature ("feature:ID") or per sample ("sample:SOURCE:ID"). A verdict is short (B, S, X or -, optionally followed by
# its basis, e.g. "B M:24") or free-form text: a postponed decision, counted as open (O) until rewritten in short form.
# Changing a verdict needs no rescan: rerun this script.
# Usage: perl large-subset-yardsticks.pl [-v] [-o samples.tsv] [-r verdicts.txt] [-c sc-cache.jsonl] samples.jsonl large-scan.jsonl drops.tsv
#   -v: also the features, by how many samples use them;  -o: one line per sample (source, ID, both, verdict,
#   features, large, why, note) for later analysis;  -c: cache of ShellCheck's messages for the codes SC3044 and
#   SC3045 (read if present, written otherwise), so that no rerun needs ShellCheck.
use strict; use warnings; use JSON::PP; use File::Temp 'tempfile'; use FindBin;
require "$FindBin::Bin/large-subset-features.pl";
my ($V, $O, $C, $R) = (0, '', '', "$FindBin::Bin/large-subset-verdicts.txt");
while (@ARGV && $ARGV[0] =~ /^-/) { my $o = shift; $V = 1 if $o eq '-v'; $O = shift if $o eq '-o'; $C = shift if $o eq '-c'; $R = shift if $o eq '-r' }
my %VD;   # key -> [short verdict or 'O', basis or the free text]
if (open my $h, '<:utf8', $R) { my $k;
  while (<$h>) { chomp; next if /^#/; if (/^(feature|sample):(\S+)\t(.*)$/) { $k = "$1:$2"; my $t = $3;
      $VD{$k} = $t =~ /^([BSX-])(?:\s+(\S+))?\s*$/ ? [$1, $2 // 'user'] : ['O', $t] }
    elsif (/^\t(.*)$/ && $k && $VD{$k}[0] eq 'O') { $VD{$k}[1] .= "\n$1" } } }   # a free-form verdict may go on, on lines starting with a tab
my %CACHE; my $cw;
if ($C && -e $C) { open my $h, '<', $C or die "$C: $!"; while (<$h>) { my $r = decode_json $_; $CACHE{"$r->{src}\0$r->{id}"} = $r->{m} } }
elsif ($C) { open $cw, '>', $C or die "$C: $!" }
my ($samples, $scan, $drops) = @ARGV; my (%t, %drop, %S, %feat);
open my $s, '<', $samples or die "$samples: $!"; while (<$s>) { my $h = decode_json $_; $t{"$h->{src}\0$h->{id}"} //= $h->{text} }
open my $d, '<', $drops or die "$drops: $!"; while (<$d>) { my ($src, $id) = split /\t/; $drop{"$src\0$id"} = 1 }
my $out; if ($O) { open $out, '>:utf8', $O or die "$O: $!"; print $out join("\t", qw(source id both verdict features large why note)), "\n" }
sub scmsgs {   # SC3044, SC3045 are families (one code, many builtins or flags): their messages name which
  my $text = shift; my ($fh, $fn) = tempfile(); binmode $fh, ':utf8'; print $fh $text; close $fh;
  my %m; for (`shellcheck -s dash -f gcc $fn 2>/dev/null`) { $m{$2} .= "$1 " if /: (?:warning|error|note): (.*?) \[(SC30\d\d)\]$/ }
  unlink $fn; %m }
open my $in, '<', $scan or die "$scan: $!";
while (<$in>) { my $r = decode_json $_; my $k = "$r->{src}\0$r->{id}"; next if $drop{$k}; my $text = $t{$k} // next;
  my %sc = map +($_ => ''), @{$r->{sc}};
  if (grep /^SC304[45]$/, keys %sc) {
    my $m = $CACHE{$k} //= { scmsgs($text) }; %sc = (%sc, %$m);
    print $cw JSON::PP->new->canonical->encode({ src => $r->{src}, id => $r->{id}, m => $m }), "\n" if $cw }
  my @f = (features($text), sc_features(map +($_ => $sc{$_}), grep /^SC3/, keys %sc));
  my %seen; @f = grep !$seen{$$_[0]}++, @f;
  for (@f) { my $o = $VD{"feature:$$_[0]"} or next; @$_[1, 2] = ($$o[0], $$o[0] eq 'O' ? 'open' : $$o[1]) }
  my $both = $r->{dash} && $r->{bash} ? 1 : 0;
  push @f, ['parse', 'B', 'P:-n'] unless $both;   # a shell refuses to parse it (both refusing: we refuse too)
  my $v = verdict(@f); my $note = '';
  $v = 'O' if $v ne 'B' && grep $$_[1] eq 'O', @f;
  if (my $o = $VD{"sample:$r->{src}:$r->{id}"}) { $v = $$o[0]; $note = $$o[1] }
  my $up = $v ne 'B'; my $low = $up && $v !~ /^[SO]$/;   # open: outside lower, inside upper, until decided
  my $src = $r->{src} . ($r->{tag} ? ":$r->{tag}" : ''); my $x = $S{$src} //= {};
  $x->{n}++; $x->{lg} += $r->{large}; $x->{up} += $up; $x->{low} += $low;
  $x->{rejlow} += $low && !$r->{large}; $x->{rejsub} += $up && !$low && !$r->{large};
  $x->{accout} += !$up && $r->{large}; $x->{none} += !$r->{dash} && !$r->{bash} && $r->{large};
  $x->{X} += !!grep $$_[1] eq 'X', @f; $x->{open} += $v eq 'O';
  $feat{$$_[1]}{"$$_[0] ($$_[2])"}++ for @f;
  print $out join("\t", $r->{src}, $r->{id}, $both, $v, join(',', map join(':', @$_), @f), $r->{large}, $r->{why} // '', $note =~ s/\n/ \/ /gr), "\n" if $out }
printf "%-20s %6s %8s %8s %8s %9s %9s %9s %9s %5s\n", qw(source n large lower upper rej-lower rej-subtl acc-out acc-none open);
for (sort keys %S) { my $x = $S{$_}; my $p = sub { sprintf '%.1f%%', 100 * ($x->{$_[0]} // 0) / $x->{n} };
  printf "%-20s %6d %8s %8s %8s %9d %9d %9d %9d %5d\n", $_, $x->{n}, map($p->($_), qw(lg low up)), map $x->{$_} // 0, qw(rejlow rejsub accout none open) }
print "\nOpen verdicts (free-form, postponed):\n", map("  $_: $VD{$_}[1]\n", grep $VD{$_}[0] eq 'O', sort keys %VD) if $V;
if ($V) { for my $v (qw(B S X O)) { print "\n$v:\n"; printf "  %5d  %s\n", $feat{$v}{$_}, $_ for sort { $feat{$v}{$b} <=> $feat{$v}{$a} } keys %{$feat{$v}} } }
