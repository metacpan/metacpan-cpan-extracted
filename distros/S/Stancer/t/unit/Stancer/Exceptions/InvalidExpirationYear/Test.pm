package Stancer::Exceptions::InvalidExpirationYear::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidExpirationYear;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(6) {
    my $object = Stancer::Exceptions::InvalidExpirationYear->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidExpirationYear', 'Stancer::Exceptions::InvalidExpirationYear->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidCardExpiration', 'Stancer::Exceptions::InvalidExpirationYear->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidExpirationYear->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidExpirationYear->new()');

    is($object->message, 'Expiration year is invalid.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
