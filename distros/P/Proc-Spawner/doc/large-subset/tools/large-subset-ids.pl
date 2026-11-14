#!/usr/bin/perl
# large-subset-ids.pl (post-0.11): the snippet IDs of large-subset-provenance.tsv whose code names any of CODEs (one per
# line, for large-subset-runcompare.pl -only @FILE), as large-subset-environment.md, section 9, chose the samples of an
# environment variant.  Usage: perl large-subset-ids.pl large-subset-provenance.tsv CODE [CODE...]
use strict; use warnings;
@ARGV >= 2 or die "usage: $0 large-subset-provenance.tsv CODE...\n";
my $P = shift; my %want = map +($_ => 1), @ARGV;
open my $in, '<', $P or die "$P: $!";
while (<$in>) { next if /^#/; chomp; my ($id, $code) = split /\t/; next unless defined $code;
  my (undef, @c) = split /[:,\/()]/, $code;   # (2026-11-13) also the codes inside passthrough(...), since step 3
  print "$id\n" if grep $want{$_}, @c }
