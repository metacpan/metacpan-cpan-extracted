package Stancer::Exceptions::InvalidExpirationMonth::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidExpirationMonth;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(6) {
    my $object = Stancer::Exceptions::InvalidExpirationMonth->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidExpirationMonth', 'Stancer::Exceptions::InvalidExpirationMonth->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidCardExpiration', 'Stancer::Exceptions::InvalidExpirationMonth->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidExpirationMonth->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidExpirationMonth->new()');

    is($object->message, 'Expiration month is invalid.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
