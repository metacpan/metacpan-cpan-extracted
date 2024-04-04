package Stancer::Exceptions::InvalidIban::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidIban;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidIban->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidIban', 'Stancer::Exceptions::InvalidIban->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidIban->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidIban->new()');

    is($object->message, 'Invalid IBAN.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
