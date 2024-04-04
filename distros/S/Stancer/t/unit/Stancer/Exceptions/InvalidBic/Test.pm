package Stancer::Exceptions::InvalidBic::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidBic;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidBic->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidBic', 'Stancer::Exceptions::InvalidBic->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidBic->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidBic->new()');

    is($object->message, 'Invalid BIC.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
