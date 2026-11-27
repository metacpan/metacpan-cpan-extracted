#!/usr/bin/perl
# large-subset-bgjobs.pl (post-0.12, K5): the ids of the samples with a background job (an and-or list ending in &, as
# the parser gives it), one a line: the samples whose result can depend on ShellSpawn's wait at exit (PROC_SHELLSPAWN_END).
# Usage: perl -Ilib large-subset-bgjobs.pl samples.jsonl [samples.tsv] > bg.ids
#   samples.tsv: only the samples the large subset accepts (column large = 1: the ones the runner takes).
use strict; use warnings; use JSON::PP; use Proc::ShellSubset::Large;
my ($SJ, $ST) = @ARGV; defined $SJ or die "usage: $0 samples.jsonl [samples.tsv]\n";
my %take; if (defined $ST) { open my $in, "<", $ST or die "$ST: $!"; my @h = split /\t/, scalar <$in>; chomp @h; my ($L) = grep $h[$_] eq "large", 0..$#h; defined $L or die "$ST: no column large\n";
  while (<$in>) { chomp; my @f = split /\t/, $_, -1; $take{$f[1]} = 1 if ($f[$L] // '') eq '1' } }
sub bg { my $x = shift; my $r = ref $x;
  if ($r eq 'ARRAY') { return 1 if @$x && defined $x->[-1] && !ref $x->[-1] && $x->[-1] eq '&'; bg($_) and return 1 for @$x }
  elsif ($r eq 'HASH') { bg($_) and return 1 for values %$x }
  0 }
open my $in, '<', $SJ or die "$SJ: $!"; my $n = 0;
while (<$in>) { my $s = decode_json $_; next if %take && !$take{$s->{id}};
  my $t = eval { Proc::ShellSubset::Large::parse($s->{text}) }; next unless ref $t;
  if (bg($t)) { print "$s->{id}\n"; $n++ } }
print STDERR "$n samples with a background job\n";
