#!/usr/bin/perl
# Write shell-subset-corpus-tests.pl from groups.tsv (in the current directory), and, given a file of hand-written
# tests (perl gentests.pl HANDWRITTEN), give those without one an OWN:n ID.
# Test line format: "ok|rej  OPTIONS  ID  TEXT"; in TEXT, @N, @T and @R stand for newline, tab and CR.
use strict; use warnings;
my $harness = <<'H';
use strict; use warnings; use FindBin; use lib "$FindBin::Bin/../../lib"; use Proc::ShellSubset; use Data::Dumper;
$Data::Dumper::Indent = 0; $Data::Dumper::Terse = 1; $Data::Dumper::Sortkeys = 1; $Data::Dumper::Useqq = 1;
$ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my ($bad, $n) = (0, 0);
while (<DATA>) {
  chomp; next unless /\S/ && !/^#/;
  my ($exp, $opt, $id, $s) = /^(ok|rej)\s+(\S+)\s+(\S+)\s+(.*)$/ or die "bad line $_";
  $s =~ s/\@N/\n/g; $s =~ s/\@T/\t/g; $s =~ s/\@R/\r/g;
  my %o = map +($_ => 1), grep length && $_ ne '-', split /,/, $opt;
  my $t = Proc::ShellSubset::parse($s, %o); my $ok = ref $t eq 'ARRAY'; $n++;
  my $m = $ok eq ($exp eq 'ok') ? '  ' : '!!'; $bad++ if $m eq '!!';
  (my $show = $s) =~ s/\n/\\n/g;
  printf "%s %-22s %-38s %s\n", $m, $id, $show, $ok ? Dumper($t) : "REJ $t->{error} \@$t->{pos}";
}
print "$bad of $n unexpected\n";
H
# corpus tests
open my $g, '<', 'groups.tsv' or die; my @L;
while (<$g>) { chomp; my ($v, $n, $srcs, $sig, $id, $t) = split /\t/; $t =~ s/\t/\@T/g; $t =~ s/\r/\@R/g;
  push @L, "# $sig  ($n samples: $srcs)\n" . sprintf("%-3s -  %s  %s\n", $v, $id, $t) }
open my $o, '>', 'shell-subset-corpus-tests.pl' or die;
print $o "# Corpus regression tests: one sample per group of very similar commands. Each test carries the\n",
  "# snippet ID of its source (see doc/parsers/shell-subset-test-provenance.md); each '# ...' line names the group: its features (accepted)\n",
  "# or its error and the construct at the error (rejected), and how many samples it has in which sources.\n",
  $harness, "__DATA__\n", @L;
print scalar(@L), " corpus tests\n";
# hand-written tests: add OWN:n to lines without an ID (done once, 2026-10-29; later tests take the next free number by hand)
my $f = shift // exit; open my $h, '<', $f or die "$f: $!"; my ($pre, @d) = ('');
while (<$h>) { $pre .= $_; last if /^__DATA__/ } @d = <$h>; my $i = 0;
for (@d) { next unless /^(ok|rej)\s+(\S*)\s+(.*)$/; my ($v, $opt, $t) = ($1, $2, $3);
  next if $t =~ /^OWN:\d+\s/; $_ = sprintf("%-3s %s  OWN:%d  %s\n", $v, $opt, ++$i, $t) }
open $o, '>', 'shell-subset-tests.pl' or die;
print $o "# Hand-written tests, one rule of shell-subset-spec.md per line; IDs OWN:n (see doc/parsers/shell-subset-test-provenance.md).\n", $harness, "__DATA__\n", @d;
print "$i hand-written tests\n";
