package Stancer::Exceptions::InvalidCardInstance::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidCardInstance;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidCardInstance->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidCardInstance', 'Stancer::Exceptions::InvalidCardInstance->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidCardInstance->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidCardInstance->new()');

    is($object->message, 'Invalid Card instance.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
