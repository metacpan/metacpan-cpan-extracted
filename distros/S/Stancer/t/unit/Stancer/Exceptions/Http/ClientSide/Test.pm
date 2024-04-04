package Stancer::Exceptions::Http::ClientSide::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::Http::ClientSide;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::Http::ClientSide->new();

    isa_ok($object, 'Stancer::Exceptions::Http::ClientSide', 'Stancer::Exceptions::Http::ClientSide->new()');
    isa_ok($object, 'Stancer::Exceptions::Http', 'Stancer::Exceptions::Http::ClientSide->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::Http::ClientSide->new()');

    is($object->message, 'Client error', 'Has default message');
    is($object->log_level, 'error', 'Has a log level');
}

1;
