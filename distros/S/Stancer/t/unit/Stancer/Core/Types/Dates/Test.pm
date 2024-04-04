package Stancer::Core::Types::Dates::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Core::Types::Dates::Stub;
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

my @parts = localtime;
my $current = $parts[5] + 1900;

sub month : Tests(20) {
    my @months = qw(
        none
        January
        February
        March
        April
        May
        June
        July
        August
        September
        October
        November
        December
    );

    for my $month (1..12) {
        ok(Stancer::Core::Types::Dates::Stub->new(a_month => $month), 'Allow ' . $months[$month]);
    }

    my $message = 'Must be an integer between 1 and 12 (included), %s given.';
    my $string = random_string(10);

    throws_ok {
        Stancer::Core::Types::Dates::Stub->new(a_month => 0);
    } 'Stancer::Exceptions::InvalidExpirationMonth', 'Must be more than 0';
    is($EVAL_ERROR->message, sprintf($message, q/"0"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Dates::Stub->new(a_month => 13);
    } 'Stancer::Exceptions::InvalidExpirationMonth', 'Must be maximum 12';
    is($EVAL_ERROR->message, sprintf($message, q/"13"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Dates::Stub->new(a_month => $string);
    } 'Stancer::Exceptions::InvalidExpirationMonth', 'Must be an integer';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Dates::Stub->new(a_month => undef);
    } 'Stancer::Exceptions::InvalidExpirationMonth', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub year : Tests(35) {
    for my $y (0..30) {
        my $year = $y + $current - 15;

        ok(Stancer::Core::Types::Dates::Stub->new(a_year => $year), 'Allow ' . $year);
    }

    my $message = 'Must be an integer, %s given.';
    my $string = random_string(10);

    throws_ok {
        Stancer::Core::Types::Dates::Stub->new(a_year => $string);
    } 'Stancer::Exceptions::InvalidExpirationYear', 'Must be an integer';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Dates::Stub->new(a_year => undef);
    } 'Stancer::Exceptions::InvalidExpirationYear', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

1;
