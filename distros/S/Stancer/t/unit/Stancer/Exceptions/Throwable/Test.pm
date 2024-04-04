package Stancer::Exceptions::Throwable::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::Throwable;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(4) {
    my $object = Stancer::Exceptions::Throwable->new();

    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::Throwable->new()');
    ok($object->does('Throwable'), 'Should be throwable');

    is($object->message, 'Unexpected error.', 'Has default message');
    is($object->log_level, 'notice', 'Has a log level');
}

1;
