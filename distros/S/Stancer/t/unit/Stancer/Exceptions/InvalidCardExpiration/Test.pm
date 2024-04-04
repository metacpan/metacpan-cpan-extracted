package Stancer::Exceptions::InvalidCardExpiration::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidCardExpiration;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidCardExpiration->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidCardExpiration', 'Stancer::Exceptions::InvalidCardExpiration->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidCardExpiration->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidCardExpiration->new()');

    is($object->message, 'Expiration is invalid.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
