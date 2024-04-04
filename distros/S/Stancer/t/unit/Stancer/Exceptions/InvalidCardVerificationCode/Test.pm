package Stancer::Exceptions::InvalidCardVerificationCode::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Exceptions::InvalidCardVerificationCode;
use TestCase;

## no critic (RequireFinalReturn)

sub instance : Tests(5) {
    my $object = Stancer::Exceptions::InvalidCardVerificationCode->new();

    isa_ok($object, 'Stancer::Exceptions::InvalidCardVerificationCode', 'Stancer::Exceptions::InvalidCardVerificationCode->new()');
    isa_ok($object, 'Stancer::Exceptions::InvalidArgument', 'Stancer::Exceptions::InvalidCardVerificationCode->new()');
    isa_ok($object, 'Stancer::Exceptions::Throwable', 'Stancer::Exceptions::InvalidCardVerificationCode->new()');

    is($object->message, 'Invalid CVC.', 'Has default message');
    is($object->log_level, 'debug', 'Has a log level');
}

1;
