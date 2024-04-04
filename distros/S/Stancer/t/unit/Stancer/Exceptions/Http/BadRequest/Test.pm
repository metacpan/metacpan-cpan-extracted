package Stancer::Exceptions::Http::BadRequest::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::Http::BadRequest;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(7) {
    my $object = Stancer::Exceptions::Http::BadRequest->new();

    isa_ok($object, 'Stancer::Exceptions::Http::BadRequest', 'Stancer::Exceptions::Http::BadRequest->new()');
    isa_ok($object, 'Stancer::Exceptions::Http::ClientSide', 'Stancer::Exceptions::Http::BadRequest->new()');
    isa_ok($object, 'Stancer::Exceptions::Http', 'Stancer::Exceptions::Http::BadRequest->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::Http::BadRequest->new()');

    is($object->message, 'Bad Request', 'Has default message');
    is($object->log_level, 'critical', 'Has a log level');
    is($object->status, 400, 'Has an HTTP status');
}

1;
