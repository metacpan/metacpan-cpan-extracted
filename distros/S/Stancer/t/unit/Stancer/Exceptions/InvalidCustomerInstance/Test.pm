package Stancer::Exceptions::InvalidCustomerInstance::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidCustomerInstance;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidCustomerInstance->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidCustomerInstance', 'Stancer::Exceptions::InvalidCustomerInstance->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidCustomerInstance->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidCustomerInstance->new()');

    is($object->message, 'Invalid Customer instance.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
