package Stancer::Exceptions::MissingApiKey::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::MissingApiKey;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::MissingApiKey->new();

    isa_ok($object, 'Stancer::Exceptions::MissingApiKey', 'Stancer::Exceptions::MissingApiKey->new()');
    isa_ok($object, 'Stancer::Exceptions::BadMethodCall', 'Stancer::Exceptions::MissingApiKey->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::MissingApiKey->new()');

    is($object->message, 'You did not provide valid API key.', 'Has default message');
    is($object->log_level, 'critical', 'Has a log level');
}

1;
