package Stancer::Exceptions::InvalidOrderId::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidOrderId;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidOrderId->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidOrderId', 'Stancer::Exceptions::InvalidOrderId->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidOrderId->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidOrderId->new()');

    is($object->message, 'Invalid order ID.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
