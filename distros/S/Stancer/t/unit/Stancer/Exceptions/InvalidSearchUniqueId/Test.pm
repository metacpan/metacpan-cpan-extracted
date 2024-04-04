package Stancer::Exceptions::InvalidSearchUniqueId::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidSearchUniqueId;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(6) {
    my $object = Stancer::Exceptions::InvalidSearchUniqueId->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidSearchUniqueId', 'Stancer::Exceptions::InvalidSearchUniqueId->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidSearchFilter', 'Stancer::Exceptions::InvalidSearchUniqueId->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidSearchUniqueId->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidSearchUniqueId->new()');

    is($object->message, 'Invalid unique ID.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
