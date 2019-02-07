#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use OTRS::OPM::Parser;

use File::Basename;
use File::Spec;

my $opm_file = File::Spec->catfile( dirname(__FILE__), 'data', 'QuickMergeTwoDocs-3.3.2.opm' );
my $opm      = OTRS::OPM::Parser->new( opm_file => $opm_file );

isa_ok $opm, 'OTRS::OPM::Parser';

$opm->parse;

{
    my $doc = $opm->documentation;
    is $doc->{filename}, 'doc/en/QuickMerge.pod';
}

{
    my $doc = $opm->documentation( lang => 'de' );
    is $doc->{filename}, 'doc/de/QuickMerge.pod';
}

{
    my $doc = $opm->documentation( lang => 'fr' );
    is $doc->{filename}, 'doc/en/QuickMerge.pod';
}

{
    my $doc = $opm->documentation( lang => 'de', type => 'pod' );
    is $doc->{filename}, 'doc/de/QuickMerge.pod';
}

{
    my $doc = $opm->documentation( lang => 'de', type => 'pdf' );
    is $doc->{filename}, 'doc/de/QuickMerge.pod';
}

{
    my $doc = $opm->documentation( lang => 'en', type => 'pod' );
    is $doc->{filename}, 'doc/en/QuickMerge.pod';
}

{
    my $doc = $opm->documentation( lang => 'en', type => 'pdf' );
    is $doc->{filename}, 'doc/en/QuickMerge.pdf';
}

{
    $opm->files([]);
    my $doc = $opm->documentation;
    is $doc, undef;
}

done_testing();

