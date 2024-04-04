package Stancer::Core::Types::Network::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Core::Types::Network::Stub;
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub ip_address : Tests(22) {
    for my $address (ipv4_provider()) {
        ok(Stancer::Core::Types::Network::Stub->new(an_ip_address => $address), $address . ' is valid');
    }

    for my $address (ipv6_provider()) {
        ok(Stancer::Core::Types::Network::Stub->new(an_ip_address => $address), $address . ' is valid');
    }

    my $message = '%s is not a valid IP address.';
    my $integer = random_integer(100);
    my $fake = join q/./, (
        random_integer(250, 300),
        random_integer(250, 300),
        random_integer(250, 300),
        random_integer(250, 300),
    );

    throws_ok {
        Stancer::Core::Types::Network::Stub->new(an_ip_address => $fake);
    } 'Stancer::Exceptions::InvalidIpAddress', 'Must be a valid IP';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $fake . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Network::Stub->new(an_ip_address => $integer);
    } 'Stancer::Exceptions::InvalidIpAddress', 'Must be a string';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Network::Stub->new(an_ip_address => undef);
    } 'Stancer::Exceptions::InvalidIpAddress', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub port : Tests(9) {
    ok(Stancer::Core::Types::Network::Stub->new(a_port => random_integer(1, 65_535)), 'A port');

    my $message = 'Must be at less than 65535, %s given.';
    my $integer = random_integer(65_535, 99_999);
    my $string = random_string(10);

    throws_ok {
        Stancer::Core::Types::Network::Stub->new(a_port => $integer);
    } 'Stancer::Exceptions::InvalidPort', 'Must be less than 65 535';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Network::Stub->new(a_port => 0);
    } 'Stancer::Exceptions::InvalidPort', 'Must be at least 1';
    is($EVAL_ERROR->message, sprintf($message, q/"0"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Network::Stub->new(a_port => $string);
    } 'Stancer::Exceptions::InvalidPort', 'Must be an integer';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Network::Stub->new(a_port => undef);
    } 'Stancer::Exceptions::InvalidPort', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

sub url : Tests(9) {
    my $https = 'https://www.example.org/?' . random_string(10);
    my $http = 'http://www.example.org/?' . random_string(10);

    ok(Stancer::Core::Types::Network::Stub->new(an_url => $https), 'An url');

    my $message = '%s is not a valid HTTPS url.';
    my $integer = random_integer(10);
    my $string = random_string(10);

    throws_ok {
        Stancer::Core::Types::Network::Stub->new(an_url => $http);
    } 'Stancer::Exceptions::InvalidUrl', 'Must be an HTTPS url';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $http . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Network::Stub->new(an_url => $string);
    } 'Stancer::Exceptions::InvalidUrl', 'Must be an url';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Network::Stub->new(an_url => $integer);
    } 'Stancer::Exceptions::InvalidUrl', 'Must be a string';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Network::Stub->new(an_url => undef);
    } 'Stancer::Exceptions::InvalidUrl', 'Can not be undef';
    is($EVAL_ERROR->message, sprintf($message, 'undef'), 'Message check');
}

1;
