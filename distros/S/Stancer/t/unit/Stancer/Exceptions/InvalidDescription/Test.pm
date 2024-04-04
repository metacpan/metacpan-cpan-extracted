package Stancer::Exceptions::InvalidDescription::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidDescription;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidDescription->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidDescription', 'Stancer::Exceptions::InvalidDescription->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidDescription->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidDescription->new()');

    is($object->message, 'Invalid description.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
