package Stancer::Exceptions::InvalidPort::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidPort;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidPort->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidPort', 'Stancer::Exceptions::InvalidPort->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidPort->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidPort->new()');

    is($object->message, 'Invalid port.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
