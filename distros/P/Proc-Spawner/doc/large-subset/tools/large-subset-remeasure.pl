#!/usr/bin/perl
# large-subset-remeasure.pl (version of 2026-11-02; see doc/large-subset/large-subset-ceiling.md (in Proc-Spawner 0.03)). Reads large-scan.jsonl of
# large-subset-scan.pl and prints, per source: acceptance by Proc::ShellSubset (all options) and Proc::ShellSubset::Large, and the
# POSIX ceiling: dash -n and bash --posix -n accept the sample and ShellCheck (-s dash) gives no SC3xxx warning.
# Cross-checks: the ceiling by the regex scan instead of ShellCheck, where the two detectors disagree, and how
# many samples the large grammar accepts outside the ceiling. With -v: the reasons for rejections inside the ceiling.
# With -d drops.tsv (large-subset-drops.pl): the samples listed there are left out, and counted by reason.
# Usage: perl large-subset-remeasure.pl [-v] [-d drops.tsv] [large-scan.jsonl]
use strict; use warnings; use JSON::PP;
my ($V, %drop, %reason);
while (@ARGV && $ARGV[0] =~ /^-[vd]\z/) { my $o = shift;
  if ($o eq '-v') { $V = 1; next }
  open my $d, '<', shift or die; while (<$d>) { chomp; my ($src, $id, $why) = split /\t/; $drop{"$src\0$id"} = 1;
    $why =~ s/^duplicate of .*/duplicate/; $reason{$why}++ } }
my (%S, %why, %ex);
open my $in, '<', shift // 'large-scan.jsonl' or die;
while (<$in>) { my $r = decode_json $_; next if $drop{"$r->{src}\0$r->{id}"}; my $src = $r->{src} . ($r->{tag} ? ":$r->{tag}" : '');
  my $syn = $r->{dash} && $r->{bash}; my $c = $syn && !@{$r->{sc}}; my $x = $S{$src} //= {};
  $x->{n}++; $x->{cur} += $r->{cur}; $x->{lg} += $r->{large}; $x->{c} += $c; $x->{crx} += $syn && !@{$r->{rx}};
  $x->{out} += $r->{large} && !$c; $x->{in_rej} += $c && !$r->{large};
  $x->{sc_only} += $syn && @{$r->{sc}} && !@{$r->{rx}}; $x->{rx_only} += $syn && !@{$r->{sc}} && @{$r->{rx}};
  $x->{pm_only} += $syn && !@{$r->{sc}} && $r->{pm};
  if ($c && !$r->{large}) { (my $w = $r->{why}) =~ s/'[^']*'/'…'/g; $why{$src}{$w}++; push @{$ex{$src}{$w}}, $r->{id} if @{$ex{$src}{$w} // []} < 2 } }
printf "%-24s %6s %8s %8s %8s %8s %6s %6s %7s %7s %7s\n", qw(source n subset large ceiling ceil-rx out in-rej sc-only rx-only pm-only);
for my $src (sort keys %S) { my $x = $S{$src}; my $p = sub { sprintf '%.1f%%', 100 * ($x->{$_[0]} // 0) / $x->{n} };
  printf "%-24s %6d %8s %8s %8s %8s %6d %6d %7d %7d %7d\n", $src, $x->{n}, map($p->($_), qw(cur lg c crx)),
    map $x->{$_} // 0, qw(out in_rej sc_only rx_only pm_only);
  next unless $V; my $w = $why{$src};
  printf "    %4d  %s  (%s)\n", $$w{$_}, $_, join ' ', @{$ex{$src}{$_}} for grep defined, (sort { $$w{$b} <=> $$w{$a} } keys %$w)[0 .. 7] }
print "\nLeft out (-d): ", join('; ', map "$reason{$_} $_", sort { $reason{$b} <=> $reason{$a} } keys %reason), "\n" if %reason;
