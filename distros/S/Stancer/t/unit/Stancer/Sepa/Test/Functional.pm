package Stancer::Sepa::Test::Functional;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Sepa;
use List::Util qw(shuffle);
use TestCase;

## no critic (ProhibitPunctuationVars, RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub get_data : Tests(9) {
    # 404
    throws_ok(
        sub { Stancer::Sepa->new('sepa_' . random_string(24))->populate() },
        'Stancer::Exceptions::Http::NotFound',
        'Should throw a NotFound (404) error',
    );

    my $sepa = Stancer::Sepa->new('sepa_bIvCZePYqfMlU11TANT8IqL1');

    is($sepa->bic, 'TESTSEPP', 'Should have a bic');
    is($sepa->last4, '0003', 'Should have a last4');
    is($sepa->mandate, 'mandate-identifier', 'Should have a mandate');
    is($sepa->name, 'John Doe', 'Should have a name');

    isa_ok($sepa->created, 'DateTime', '$sepa->created');
    is($sepa->created->epoch, 1_601_045_777, 'Dates should correspond');

    isa_ok($sepa->date_mandate, 'DateTime', '$sepa->date_mandate');
    is($sepa->date_mandate->epoch, 1_601_045_728, 'Dates should correspond');
}

1;
