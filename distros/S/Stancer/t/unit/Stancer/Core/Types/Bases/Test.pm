package Stancer::Core::Types::Bases::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Core::Types::Bases::Stub;
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub bool_test : Tests(10) {
    ok(Stancer::Core::Types::Bases::Stub->new(a_boolean => 1), '"1" is valid');
    ok(Stancer::Core::Types::Bases::Stub->new(a_boolean => 0), '"0" is valid');
    ok(Stancer::Core::Types::Bases::Stub->new(a_boolean => JSON::true), '"JSON::true" is valid');
    ok(Stancer::Core::Types::Bases::Stub->new(a_boolean => JSON::false), '"JSON::false" is valid');

    my $message = '%s is not a bool.';
    my $integer = random_integer(2, 10);
    my $string = random_string(10);

    throws_ok {
        Stancer::Core::Types::Bases::Stub->new(a_boolean => $integer);
    } 'Stancer::Exceptions::InvalidArgument', 'Can not be an integer';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Bases::Stub->new(a_boolean => $string);
    } 'Stancer::Exceptions::InvalidArgument', 'Can not be a string';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Bases::Stub->new(a_boolean => undef);
    } 'Stancer::Exceptions::InvalidArgument', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub enum : Tests(6) {
    my @expected = qw(foo bar);

    for my $val (@expected) {
        ok(Stancer::Core::Types::Bases::Stub->new(an_enumeration => $val), q/"/ . $val . '" is valid');
    }

    my $message = 'Must be one of : ' . join(', ', map { q/"/ . $_ . q/"/} @expected) . '. %s given';
    my $string = random_string(10);

    throws_ok {
        Stancer::Core::Types::Bases::Stub->new(an_enumeration => $string);
    } 'Stancer::Exceptions::InvalidArgument', 'Can not be anything else';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Bases::Stub->new(an_enumeration => undef);
    } 'Stancer::Exceptions::InvalidArgument', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub str_test : Tests(3) {
    my $string = random_string(10);

    ok(Stancer::Core::Types::Bases::Stub->new(a_string => $string), q/"/ . $string . '" is valid');

    my $message = '%s is not a string.';

    throws_ok {
        Stancer::Core::Types::Bases::Stub->new(a_string => undef);
    } 'Stancer::Exceptions::InvalidArgument', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

1;
