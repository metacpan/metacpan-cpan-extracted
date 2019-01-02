#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use OTRS::OPM::Analyzer;

use File::Basename;
use File::Spec;

my $opm_file = File::Spec->catfile( dirname(__FILE__), 'data', 'QuickMerge-3.3.2.opm' );
my $opm      = OTRS::OPM::Analyzer->new;

isa_ok $opm, 'OTRS::OPM::Analyzer';

my $result = eval { $opm->analyze( $opm_file ) };
diag $@ if $@;
my $check = {};

#is_deeply $result, $check;
is $result, undef;

done_testing();
