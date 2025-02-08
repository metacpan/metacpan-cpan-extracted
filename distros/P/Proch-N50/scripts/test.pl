#!/usr/bin/env perl
use 5.016;
use FindBin qw($Bin);
use lib "$Bin/../lib/";
use Proch::N50 qw(getStats getN50);
use Data::Dumper;
use Term::ANSIColor;

say STDERR " TEST FASTA/FASTQ STATS";

my $filepath = $ARGV[0];

if (!defined $filepath) {

  die " Please specify a FASTA/FASTQ file as input.\n";
} else {
  my $seq_stats = getStats($filepath);
  unless ($seq_stats->{status}) {
    die $seq_stats->{message}, "\n";
  } else {
    say color('bold'), "N50 only:\t",color('reset'),  ,getN50($filepath);
    say color('bold'), "Full stats:",color('reset');
    say Data::Dumper->Dump( [ $seq_stats ], [ qw(*FASTA_stats) ] );
    say color('bold'), "JSON",color('reset');
    my $seq_stats_json = getStats($filepath, 'JSON');
    say $seq_stats_json->{json};
  }
}
