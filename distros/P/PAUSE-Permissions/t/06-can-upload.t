#!perl
#
# 06-can-upload.t - test the can_upload(USER,MODULE) method, based on the following
#
#   constant,P5P,c
#   constant,SAPER,m
#   constant,perl,c
#
#   constant::Atom,JOHNWRDN,f
#   constant::Atom,NEILB,c
#
#   Math::Complex,JHI,c
#   Math::Complex,RAM,m
#   Math::Complex,ZEFRAM,f
#   Math::Complex,perl,c
#
#   CPAN::Test::Reporter,SKUD,c
#
#   Test::Cucumber,JOHND,f
#   Test::Cucumber,SARGIE,m
#

use strict;
use warnings;

use Test::More 0.88;
use PAUSE::Permissions;

my @TESTS = (
    ['constant',                     'SAPER', 1],
    ['constant',                     'NEILB', 0],
    ['No::Such::Module',             'FRED', 1],
    ['CPAN::Test::Reporter',         'skud', 1],
    ['CPAN::Test::Reporter',         'SKUD', 1],
    ['cpan::test::reporter',         'SKUD', 1],
    ['Test::Cucumber::DoesNotExist', 'NIGEL', 1],
    ['Test::Cucumber',               'NIGEL', 0],
);

plan tests => int(@TESTS);

my $pp = PAUSE::Permissions->new(path => 't/06perms-mini.txt', preload => 1);

BAIL_OUT("failed to instantiate PAUSE::Permissions") unless defined($pp);

foreach my $test (@TESTS) {
    my ($module_name, $pause_id, $expected_can_upload) = @$test;
    my $can_upload = $pp->can_upload($pause_id, $module_name);
    ok($can_upload == $expected_can_upload);
}

