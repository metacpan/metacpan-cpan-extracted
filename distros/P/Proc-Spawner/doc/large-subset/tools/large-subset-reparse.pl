#!/usr/bin/perl
# Refresh the parser fields (large, why, pm) of large-scan.jsonl after a parser change, without rerunning the shells
# or ShellCheck. Usage: perl -Ilib large-subset-reparse.pl samples.jsonl large-scan.jsonl > new.jsonl
use strict; use warnings; use Proc::ShellSubset::Large; use JSON::PP;
my $J = JSON::PP->new->canonical->utf8; $ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my ($samples, $scan) = @ARGV; my %text;
open my $s, '<', $samples or die; while (<$s>) { my $h = decode_json $_; $text{"$h->{src}\0$h->{id}"} //= $h->{text} }
open my $in, '<', $scan or die;
while (<$in>) { my $r = decode_json $_; my $lg = Proc::ShellSubset::Large::parse($text{"$r->{src}\0$r->{id}"}, empty => 1);
  $r->{large} = ref $lg eq 'ARRAY' ? 1 : 0; $r->{why} = ref $lg eq 'HASH' ? $lg->{error} : ''; $r->{pm} = $r->{why} =~ /bash/ ? 1 : 0;
  print $J->encode($r), "\n" }
