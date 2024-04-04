package Stancer::Exceptions::InvalidUrl::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;

use Stancer::Exceptions::InvalidUrl;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidUrl->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidUrl', 'Stancer::Exceptions::InvalidUrl->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidUrl->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidUrl->new()');

    is($object->message, 'Invalid URL.', 'Has default message');
    is($object->log_level, 'critical', 'Has a log level');
}

1;
