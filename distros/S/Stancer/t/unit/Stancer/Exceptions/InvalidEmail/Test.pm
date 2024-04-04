package Stancer::Exceptions::InvalidEmail::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidEmail;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidEmail->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidEmail', 'Stancer::Exceptions::InvalidEmail->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidEmail->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidEmail->new()');

    is($object->message, 'Invalid email address.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
