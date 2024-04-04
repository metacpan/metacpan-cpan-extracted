package Stancer::Exceptions::InvalidSepaCheckInstance::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidSepaCheckInstance;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidSepaCheckInstance->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidSepaCheckInstance', 'Stancer::Exceptions::InvalidSepaCheckInstance->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidSepaCheckInstance->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidSepaCheckInstance->new()');

    is($object->message, 'Invalid Sepa check instance.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
