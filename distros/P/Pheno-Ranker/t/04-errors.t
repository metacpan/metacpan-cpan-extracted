#!/usr/bin/env perl
use strict;
use warnings;
use lib qw(./lib ../lib t/lib);
use Test::Exception tests => 1;
use Test::PhenoRanker qw(fixture);
use Pheno::Ranker;

{
    my $expected_error =
      qq/--include-terms <geographicOrigin> does not exist in the cohort(s)\n/;
    my $ranker = Pheno::Ranker->new(
        {
            reference_files => [ fixture('individuals.json') ],
            include_terms   => ['geographicOrigin']
        }
    );

    # Test that Pheno::Ranker throws an exception with the specific expected error message
    throws_ok { $ranker->run } qr/\Q$expected_error\E/,
"Pheno::Ranker throws the expected error when non-existent include_terms are used";

    # Debugging: Print the length of the error message and any non-printable characters
    #if ($@) {
    #    print "String length"  . length($expected_error) . "\n";
    #    print "Error Length: " . length($@) . "\n";
    #    print "Error Dump: " . unpack("H*", $@) . "\n";
    #}
}
