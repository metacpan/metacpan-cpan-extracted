package Stancer::Exceptions::MissingReturnUrl::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::MissingReturnUrl;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::MissingReturnUrl->new();

    isa_ok($object, 'Stancer::Exceptions::MissingReturnUrl', 'Stancer::Exceptions::MissingReturnUrl->new()');
    isa_ok($object, 'Stancer::Exceptions::BadMethodCall', 'Stancer::Exceptions::MissingReturnUrl->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::MissingReturnUrl->new()');

    is($object->message, 'You must provide a return URL.', 'Has default message');
    is($object->log_level, 'critical', 'Has a log level');
}

1;
