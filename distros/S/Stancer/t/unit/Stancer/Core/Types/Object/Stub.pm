package Stancer::Core::Types::Object::Stub;

use 5.020;
use strict;
use warnings;

use Moo;
use namespace::clean;

use Stancer::Core::Types::Object qw(:all);

has an_auth_instance => (
    is => 'ro',
    isa => AuthInstance,
);

has a_card_instance => (
    is => 'ro',
    isa => CardInstance,
);

has a_customer_instance => (
    is => 'ro',
    isa => CustomerInstance,
);

has a_device_instance => (
    is => 'ro',
    isa => DeviceInstance,
);

has a_payment_instance => (
    is => 'ro',
    isa => PaymentInstance,
);

has a_refund_instance => (
    is => 'ro',
    isa => RefundInstance,
);

has a_sepa_instance => (
    is => 'ro',
    isa => SepaInstance,
);

has a_sepa_check_instance => (
    is => 'ro',
    isa => SepaCheckInstance,
);

1;
