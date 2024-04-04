package Stancer::Exceptions::BadMethodCall::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::BadMethodCall;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(4) {
    my $object = Stancer::Exceptions::BadMethodCall->new();

    isa_ok($object, 'Stancer::Exceptions::BadMethodCall', 'Stancer::Exceptions::BadMethodCall->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::BadMethodCall->new()');

    is($object->message, 'Bad method call.', 'Has default message');
    is($object->log_level, 'critical', 'Has a log level');
}

1;
