#!/usr/bin/perl
# flavors-compare.pl (post-0.12; the user, 2026-11-18): the records of t/flavors-outcomes.pl, one per flavor, side by
# side: each flavor's counts by outcome, then every test whose outcome is not the same in all of them (absent: the test
# does not exist in that flavor).  Tests are matched by file and description (a skip by its reason), not by number: a
# flavor may run more tests in one place (t/windows.t under system1).
# Usage: perl t/flavors-compare.pl A.tsv B.tsv ...
use strict; use warnings; binmode STDOUT, ':utf8';
my (@fl, %st, %why, @order, %seen, %cnt);
for my $f (@ARGV) { open my $in, '<:utf8', $f or die; my ($label, %occ);
  while (<$in>) { chomp; my ($l, $file, $n, $s, $d, $w) = split /\t/, $_, 6; $label = $l; $file =~ s{\\}{/}g;
    $d =~ s/ \([0-9.]+ s; two\)$//;   # (at-exit.t: the time measured is part of its description)
    my $k = "$file\t" . (length $d ? $d : $s eq 'SKIP' ? "skip: $w" : "#$n"); $k .= '#' . $occ{$k} if $occ{$k}++;
    push @order, $k unless $seen{$k}++; $st{$k}{$l} = $s; $why{$k}{$l} = $w // ''; $cnt{$l}{$s}++ }
  push @fl, $label }
my @S = qw(ok FAILED TODO-FAILED TODO-PASSED SKIP FILE-SKIPPED FILE-FAILED);
printf "%-22s %s\n", 'flavor', join ' ', map sprintf('%11s', $_), @S;
for my $l (@fl) { printf "%-22s %s\n", $l, join ' ', map sprintf('%11d', $cnt{$l}{$_} // 0), @S }
print "\nTests whose outcome differs between the flavors (absent: the test does not exist in that flavor):\n";
for my $k (@order) { my @v = map $st{$k}{$_} // 'absent', @fl; my %u = map +($_ => 1), @v; next if keys %u == 1;
  my ($file, $d) = split /\t/, $k, 2; printf "%-14s %s\n", $file, $d;
  printf "    %-22s %-12s %s\n", $fl[$_], $v[$_], $why{$k}{$fl[$_]} // '' for 0 .. $#fl }
