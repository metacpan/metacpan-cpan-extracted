package Stancer::Exceptions::InvalidDeviceInstance::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidDeviceInstance;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidDeviceInstance->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidDeviceInstance', 'Stancer::Exceptions::InvalidDeviceInstance->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidDeviceInstance->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidDeviceInstance->new()');

    is($object->message, 'Invalid Device instance.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
