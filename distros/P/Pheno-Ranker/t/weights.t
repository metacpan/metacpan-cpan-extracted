#!/usr/bin/env perl
use strict;
use warnings;
use lib ( './lib', '../lib' );
use Test::Exception tests => 2;
use Pheno::Ranker;

my %err = (
    '1' => 'Expected integer - got string',
    '2' =>
'String not allowed - phenotypicFeatures;NCIT:C2985.featureType.id.NCIT:C2985'
);

for my $err ( sort keys %err ) {
    my $ranker = Pheno::Ranker->new(
        {
            reference_file => 't/individuals.json',
            weights_file   => qq(t/weights_err$err.yaml),
            config_file    => undef
        }
    );
    dies_ok { $ranker->run }
    'expecting to die by error: ' . $err{$err};
}
