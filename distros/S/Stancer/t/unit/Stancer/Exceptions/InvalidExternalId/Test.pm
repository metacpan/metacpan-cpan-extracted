package Stancer::Exceptions::InvalidExternalId::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidExternalId;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidExternalId->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidExternalId', 'Stancer::Exceptions::InvalidExternalId->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidExternalId->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidExternalId->new()');

    is($object->message, 'Invalid external ID.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
