#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use OPM::Parser;

use File::Basename;
use File::Spec;

my $opm_file = File::Spec->catfile( dirname(__FILE__), 'data', 'QuickMerge-4.0.3.opm' );
my $opm      = OPM::Parser->new( opm_file => $opm_file );

isa_ok $opm, 'OPM::Parser';

$opm->parse;

ok !$opm->error_string || $opm->error_string =~ m{Invalid value for maxOccurs}, 'no error string';

ok $opm->tree, 'tree exists';
isa_ok $opm->tree, 'XML::LibXML::Document';

is $opm->name, 'QuickMerge', 'name';

is_deeply $opm->framework, [qw/
    3.2.x
    3.3.x
    4.x.x
    5.x
/], 'framework';

is_deeply $opm->framework_details, [ 
    { Content => "3.2.x", Maximum => "3.2.8", Minimum => "3.2.1" },
    { Content => "3.3.x", Maximum => "3.3.12"                    },
    { Content => "4.x.x",                     Minimum => "4.0.2" },
    { Content => "5.x"                                           },
], 'framework details';

done_testing();

