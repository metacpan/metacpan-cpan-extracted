package Stancer::Exceptions::Http::NotFound::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::Http::NotFound;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(7) {
    my $object = Stancer::Exceptions::Http::NotFound->new();

    isa_ok($object, 'Stancer::Exceptions::Http::NotFound', 'Stancer::Exceptions::Http::NotFound->new()');
    isa_ok($object, 'Stancer::Exceptions::Http::ClientSide', 'Stancer::Exceptions::Http::NotFound->new()');
    isa_ok($object, 'Stancer::Exceptions::Http', 'Stancer::Exceptions::Http::NotFound->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::Http::NotFound->new()');

    is($object->message, 'Not Found', 'Has default message');
    is($object->log_level, 'error', 'Has a log level');
    is($object->status, 404, 'Has an HTTP status');
}

1;
