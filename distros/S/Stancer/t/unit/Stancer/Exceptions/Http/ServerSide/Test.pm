package Stancer::Exceptions::Http::ServerSide::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::Http::ServerSide;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::Http::ServerSide->new();

    isa_ok($object, 'Stancer::Exceptions::Http::ServerSide', 'Stancer::Exceptions::Http::ServerSide->new()');
    isa_ok($object, 'Stancer::Exceptions::Http', 'Stancer::Exceptions::Http::ServerSide->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::Http::ServerSide->new()');

    is($object->message, 'Server error', 'Has default message');
    is($object->log_level, 'critical', 'Has a log level');
}

1;
