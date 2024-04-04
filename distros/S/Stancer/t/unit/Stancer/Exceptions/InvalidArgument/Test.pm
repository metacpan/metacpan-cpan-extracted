package Stancer::Exceptions::InvalidArgument::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidArgument;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(4) {
    my $object = Stancer::Exceptions::InvalidArgument->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidArgument->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidArgument->new()');

    is($object->message, 'Invalid argument.', 'Has default message');
    is($object->log_level, 'notice', 'Has a log level');
}

1;
