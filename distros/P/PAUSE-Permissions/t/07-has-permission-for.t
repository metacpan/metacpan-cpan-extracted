#!perl
#
# 07-has-permission-for.t - test the has_permission_for() method, against the following data:
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

    [   ['perl'],            'constant,Math::Complex'   ],
    [   ['perl', 'upload'],  'constant,Math::Complex'   ],
    [   ['perl', 'owner'],   ''                         ],
    [   ['SARGIE', 'owner'], 'Test::Cucumber'           ],

);

plan tests => 2 * int(@TESTS);

run_tests_with_preload_set_to(0);
run_tests_with_preload_set_to(1);

sub run_tests_with_preload_set_to
{
    my $preload = shift;
    my $pp      = PAUSE::Permissions->new(path => 't/06perms-mini.txt', preload => $preload);

    BAIL_OUT("failed to instantiate PAUSE::Permissions") unless defined($pp);

    foreach my $test (@TESTS) {
        my ($argref, $expected) = @$test;
        my $ref                 = $pp->has_permission_for(@$argref);
        my $as_string           = join(',', @$ref);
        is($as_string, $expected);
    }
}

