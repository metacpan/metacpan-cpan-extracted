#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use OTRS::OPM::Parser;

use File::Basename;
use File::Spec;

my $opm_file = File::Spec->catfile( dirname(__FILE__), 'data', 'QuickMerge-4.0.2.opm' );
my $opm      = OTRS::OPM::Parser->new( opm_file => $opm_file );

isa_ok $opm, 'OTRS::OPM::Parser';

$opm->parse;

ok $opm->tree, 'tree exists';
isa_ok $opm->tree, 'XML::LibXML::Document';

is $opm->name, 'QuickMerge', 'name';

is_deeply [ $opm->framework ], [qw/
    3.0.x
    3.1.x
    3.2.x
    3.3.x
    4.x.x
    5.x
/], 'framework';

done_testing();

