#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use OTRS::OPM::Parser;

use File::Basename;
use File::Spec;

my %files = (
    'QuickMerge-4.0.3.opm'      => 'otrs',
    'QuickMergeOtobo-4.0.3.opm' => 'otobo',
);

for my $file ( sort keys %files ) {

    my $opm_file = File::Spec->catfile( dirname(__FILE__), 'data', $file );
    my $opm      = OTRS::OPM::Parser->new( opm_file => $opm_file );

    isa_ok $opm, 'OTRS::OPM::Parser';

    $opm->parse;

    ok !$opm->error_string || $opm->error_string =~ m{Invalid value for maxOccurs}, 'no error string';

    is $opm->name, 'QuickMerge', 'name';
    is $opm->product, $files{$file}, 'product';

    is_deeply $opm->framework, [qw/
        3.2.x
        3.3.x
        4.x.x
        5.x
    /], 'framework';
}

done_testing();

