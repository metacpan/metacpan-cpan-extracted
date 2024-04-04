package Stancer::Core::Types::Object::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Auth;
use Stancer::Card;
use Stancer::Core::Types::Object::Stub;
use Stancer::Customer;
use Stancer::Device;
use Stancer::Payment;
use Stancer::Refund;
use Stancer::Sepa;
use Stancer::Sepa::Check;
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub auth : Tests(9) {
    my $auth = Stancer::Auth->new;

    ok(Stancer::Core::Types::Object::Stub->new(an_auth_instance => $auth), 'Allow Auth instance');

    my $bad = Stancer::Sepa->new;
    my $integer = random_integer(999);
    my $string = random_string(3);

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(an_auth_instance => $bad);
    } 'Stancer::Exceptions::InvalidAuthInstance', 'Other instances are not valid';
    is($EVAL_ERROR->message, sprintf('%s is not an instance of "Stancer::Auth".', $bad), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(an_auth_instance => $integer);
    } 'Stancer::Exceptions::InvalidAuthInstance', 'Integer is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(an_auth_instance => $string);
    } 'Stancer::Exceptions::InvalidAuthInstance', 'String is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(an_auth_instance => undef);
    } 'Stancer::Exceptions::InvalidAuthInstance', 'Can not be undef';
    is($EVAL_ERROR->message, 'No instance given.', 'Message check');
}

sub card : Tests(9) {
    my $card = Stancer::Card->new;

    ok(Stancer::Core::Types::Object::Stub->new(a_card_instance => $card), 'Allow Card instance');

    my $bad = Stancer::Sepa->new;
    my $integer = random_integer(999);
    my $string = random_string(3);

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_card_instance => $bad);
    } 'Stancer::Exceptions::InvalidCardInstance', 'Other instances are not valid';
    is($EVAL_ERROR->message, sprintf('%s is not an instance of "Stancer::Card".', $bad), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_card_instance => $integer);
    } 'Stancer::Exceptions::InvalidCardInstance', 'Integer is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_card_instance => $string);
    } 'Stancer::Exceptions::InvalidCardInstance', 'String is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_card_instance => undef);
    } 'Stancer::Exceptions::InvalidCardInstance', 'Can not be undef';
    is($EVAL_ERROR->message, 'No instance given.', 'Message check');
}

sub customer : Tests(9) {
    my $customer = Stancer::Customer->new;

    ok(Stancer::Core::Types::Object::Stub->new(a_customer_instance => $customer), 'Allow customer instance');

    my $bad = Stancer::Card->new;
    my $integer = random_integer(999);
    my $string = random_string(3);

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_customer_instance => $bad);
    } 'Stancer::Exceptions::InvalidCustomerInstance', 'Other instances are not valid';
    is($EVAL_ERROR->message, sprintf('%s is not an instance of "Stancer::Customer".', $bad), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_customer_instance => $integer);
    } 'Stancer::Exceptions::InvalidCustomerInstance', 'Integer is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_customer_instance => $string);
    } 'Stancer::Exceptions::InvalidCustomerInstance', 'String is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_customer_instance => undef);
    } 'Stancer::Exceptions::InvalidCustomerInstance', 'Can not be undef';
    is($EVAL_ERROR->message, 'No instance given.', 'Message check');
}

sub device : Tests(9) {
    my $ip = ipv4_provider();
    my $port = random_integer(1, 65_535);

    local $ENV{SERVER_ADDR} = $ip;
    local $ENV{SERVER_PORT} = $port;

    my $device = Stancer::Device->new;

    ok(Stancer::Core::Types::Object::Stub->new(a_device_instance => $device), 'Allow Device instance');

    my $bad = Stancer::Sepa->new;
    my $integer = random_integer(999);
    my $string = random_string(3);

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_device_instance => $bad);
    } 'Stancer::Exceptions::InvalidDeviceInstance', 'Other instances are not valid';
    is($EVAL_ERROR->message, sprintf('%s is not an instance of "Stancer::Device".', $bad), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_device_instance => $integer);
    } 'Stancer::Exceptions::InvalidDeviceInstance', 'Integer is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_device_instance => $string);
    } 'Stancer::Exceptions::InvalidDeviceInstance', 'String is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_device_instance => undef);
    } 'Stancer::Exceptions::InvalidDeviceInstance', 'Can not be undef';
    is($EVAL_ERROR->message, 'No instance given.', 'Message check');
}

sub payment : Tests(9) {
    my $payment = Stancer::Payment->new;

    ok(Stancer::Core::Types::Object::Stub->new(a_payment_instance => $payment), 'Allow payment instance');

    my $bad = Stancer::Card->new;
    my $integer = random_integer(999);
    my $string = random_string(3);

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_payment_instance => $bad);
    } 'Stancer::Exceptions::InvalidPaymentInstance', 'Other instances are not valid';
    is($EVAL_ERROR->message, sprintf('%s is not an instance of "Stancer::Payment".', $bad), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_payment_instance => $integer);
    } 'Stancer::Exceptions::InvalidPaymentInstance', 'Integer is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_payment_instance => $string);
    } 'Stancer::Exceptions::InvalidPaymentInstance', 'String is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_payment_instance => undef);
    } 'Stancer::Exceptions::InvalidPaymentInstance', 'Can not be undef';
    is($EVAL_ERROR->message, 'No instance given.', 'Message check');
}

sub refund : Tests(9) {
    my $refund = Stancer::Refund->new;

    ok(Stancer::Core::Types::Object::Stub->new(a_refund_instance => $refund), 'Allow refund instance');

    my $bad = Stancer::Card->new;
    my $integer = random_integer(999);
    my $string = random_string(3);

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_refund_instance => $bad);
    } 'Stancer::Exceptions::InvalidRefundInstance', 'Other instances are not valid';
    is($EVAL_ERROR->message, sprintf('%s is not an instance of "Stancer::Refund".', $bad), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_refund_instance => $integer);
    } 'Stancer::Exceptions::InvalidRefundInstance', 'Integer is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_refund_instance => $string);
    } 'Stancer::Exceptions::InvalidRefundInstance', 'String is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_refund_instance => undef);
    } 'Stancer::Exceptions::InvalidRefundInstance', 'Can not be undef';
    is($EVAL_ERROR->message, 'No instance given.', 'Message check');
}

sub sepa : Tests(9) {
    my $sepa = Stancer::Sepa->new;

    ok(Stancer::Core::Types::Object::Stub->new(a_sepa_instance => $sepa), 'Allow SEPA instance');

    my $bad = Stancer::Card->new;
    my $integer = random_integer(999);
    my $string = random_string(3);

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_sepa_instance => $bad);
    } 'Stancer::Exceptions::InvalidSepaInstance', 'Other instances are not valid';
    is($EVAL_ERROR->message, sprintf('%s is not an instance of "Stancer::Sepa".', $bad), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_sepa_instance => $integer);
    } 'Stancer::Exceptions::InvalidSepaInstance', 'Integer is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_sepa_instance => $string);
    } 'Stancer::Exceptions::InvalidSepaInstance', 'String is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_sepa_instance => undef);
    } 'Stancer::Exceptions::InvalidSepaInstance', 'Can not be undef';
    is($EVAL_ERROR->message, 'No instance given.', 'Message check');
}

sub sepa_check : Tests(9) {
    my $check = Stancer::Sepa::Check->new;

    ok(Stancer::Core::Types::Object::Stub->new(a_sepa_check_instance => $check), 'Allow Sepa check instance');

    my $bad = Stancer::Card->new;
    my $integer = random_integer(999);
    my $string = random_string(3);

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_sepa_check_instance => $bad);
    } 'Stancer::Exceptions::InvalidSepaCheckInstance', 'Other instances are not valid';
    is($EVAL_ERROR->message, sprintf('%s is not an instance of "Stancer::Sepa::Check".', $bad), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_sepa_check_instance => $integer);
    } 'Stancer::Exceptions::InvalidSepaCheckInstance', 'Integer is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $integer . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_sepa_check_instance => $string);
    } 'Stancer::Exceptions::InvalidSepaCheckInstance', 'String is not valid';
    is($EVAL_ERROR->message, sprintf('%s is not blessed.', q/"/ . $string . q/"/), 'Message check');

    throws_ok {
        Stancer::Core::Types::Object::Stub->new(a_sepa_check_instance => undef);
    } 'Stancer::Exceptions::InvalidSepaCheckInstance', 'Can not be undef';
    is($EVAL_ERROR->message, 'No instance given.', 'Message check');
}

1;
