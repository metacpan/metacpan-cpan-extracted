package Stancer::Refund::Status::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Refund::Status;
use TestCase;

## no critic (RequireFinalReturn)

sub constants : Tests(5) {
    is(
        Stancer::Refund::Status::NOT_HONORED,
        'not_honored',
        'Constant "Stancer::Refund::Status::NOT_HONORED" exists',
    );
    is(
        Stancer::Refund::Status::PAYMENT_CANCELED,
        'payment_canceled',
        'Constant "Stancer::Refund::Status::PAYMENT_CANCELED" exists',
    );
    is(
        Stancer::Refund::Status::REFUND_SENT,
        'refund_sent',
        'Constant "Stancer::Refund::Status::REFUND_SENT" exists',
    );
    is(
        Stancer::Refund::Status::REFUNDED,
        'refunded',
        'Constant "Stancer::Refund::Status::REFUNDED" exists',
    );
    is(
        Stancer::Refund::Status::TO_REFUND,
        'to_refund',
        'Constant "Stancer::Refund::Status::TO_REFUND" exists',
    );
}

1;
