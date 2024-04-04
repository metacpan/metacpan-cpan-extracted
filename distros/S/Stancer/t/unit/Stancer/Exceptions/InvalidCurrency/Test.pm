package Stancer::Exceptions::InvalidCurrency::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidCurrency;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidCurrency->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidCurrency', 'Stancer::Exceptions::InvalidCurrency->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidCurrency->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidCurrency->new()');

    is($object->message, 'You must provide a valid currency.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
