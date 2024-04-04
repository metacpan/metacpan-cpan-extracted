package Stancer::Exceptions::InvalidCardNumber::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidCardNumber;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidCardNumber->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidCardNumber', 'Stancer::Exceptions::InvalidCardNumber->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidCardNumber->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidCardNumber->new()');

    is($object->message, 'Invalid card number.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
