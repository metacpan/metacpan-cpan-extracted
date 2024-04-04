package Stancer::Exceptions::InvalidName::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidName;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidName->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidName', 'Stancer::Exceptions::InvalidName->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidName->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidName->new()');

    is($object->message, 'Invalid name.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
