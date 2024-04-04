package Stancer::Exceptions::InvalidUniqueId::Test;

use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidUniqueId;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidUniqueId->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidUniqueId', 'Stancer::Exceptions::InvalidUniqueId->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidUniqueId->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidUniqueId->new()');

    is($object->message, 'Invalid unique ID.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
