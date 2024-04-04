package Stancer::Exceptions::InvalidSearchUntilCreation::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidSearchUntilCreation;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(6) {
    my $object = Stancer::Exceptions::InvalidSearchUntilCreation->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidSearchUntilCreation', 'Stancer::Exceptions::InvalidSearchUntilCreation->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidSearchFilter', 'Stancer::Exceptions::InvalidSearchUntilCreation->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidSearchUntilCreation->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidSearchUntilCreation->new()');

    is($object->message, 'Created until must be a position integer or a DateTime object and must be in the past.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
