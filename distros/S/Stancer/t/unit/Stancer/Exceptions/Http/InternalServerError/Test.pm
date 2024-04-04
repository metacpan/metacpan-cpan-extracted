package Stancer::Exceptions::Http::InternalServerError::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::Http::InternalServerError;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(7) {
    my $object = Stancer::Exceptions::Http::InternalServerError->new();

    isa_ok($object, 'Stancer::Exceptions::Http::InternalServerError', 'Stancer::Exceptions::Http::InternalServerError->new()');
    isa_ok($object, 'Stancer::Exceptions::Http::ServerSide', 'Stancer::Exceptions::Http::InternalServerError->new()');
    isa_ok($object, 'Stancer::Exceptions::Http', 'Stancer::Exceptions::Http::InternalServerError->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::Http::InternalServerError->new()');

    is($object->message, 'Internal Server Error', 'Has default message');
    is($object->log_level, 'critical', 'Has a log level');
    is($object->status, 500, 'Has an HTTP status');
}

1;
