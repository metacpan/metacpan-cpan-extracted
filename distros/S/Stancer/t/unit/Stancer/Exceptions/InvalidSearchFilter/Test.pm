package Stancer::Exceptions::InvalidSearchFilter::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidSearchFilter;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidSearchFilter->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidSearchFilter', 'Stancer::Exceptions::InvalidSearchFilter->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidSearchFilter->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidSearchFilter->new()');

    is($object->message, 'Invalid search filters.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
