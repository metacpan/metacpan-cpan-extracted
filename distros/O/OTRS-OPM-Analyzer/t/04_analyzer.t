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

ok !$opm->can( 'check_unittest' ), 'UnitTest role wasn\'t loaded yet';

my %roles_check = (
    file => [qw/
        SystemCall
        PerlCritic
        TemplateCheck
        BasicXMLCheck
        PerlTidy
    /],
    opm  => [qw/
        UnitTests
        Documentation
        Dependencies
        License
    /],
);

is_deeply +{ $opm->roles }, \%roles_check, "Configured roles";

$opm->_load_roles;

my @methods = map{ "check_" . lc $_ }map{ @{ $roles_check{$_} } }keys %roles_check;
can_ok( $opm, @methods, 'analyze' );

done_testing();
