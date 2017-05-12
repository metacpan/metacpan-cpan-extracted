# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-PayPal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Data::Dumper;
use Test::More;

if ($ENV{NET_PAYPAL_CLIENT_ID} && $ENV{NET_PAYPAL_SECRET}) {
    plan(tests => 8);
}
else {
    plan(skip_all => "NET_PAYPAL_CLIENT_ID and NET_PAYPAL_SECRET env. variables must be set to run the tests");
}


BEGIN { use_ok('Net::PayPal') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

Net::PayPal->live(0);

my $p = Net::PayPal->new(
    $ENV{NET_PAYPAL_CLIENT_ID},
    $ENV{NET_PAYPAL_SECRET},
);
ok( $p, "Access token is: " . $p->{access_token} );


my $resp = $p->cc_payment({
    cc_number       => '4353185781082049',
    cc_type         => 'visa',
    cc_expire_month => 3,
    cc_expire_year  => 2018,
    first_name      => 'Sherzod',
    last_name       => 'Ruzmetov',
    amount          => 19.95,
});
my $payment_id = $resp->{id};
ok($resp->{state} eq "approved", $resp->{id});

$resp = $p->cc_payment({
    cc_number       => '4353185781082040',
    cc_type         => 'visa',
    cc_expire_month => 3,
    cc_expire_year  => 2018,
    first_name      => 'Sherzod',
    last_name       => 'Ruzmetov',
    amount          => 19.95,
});
ok(!$resp, $p->error);

my $payment = $p->get_payment( $payment_id );

ok($payment, "Payment was made on " . $payment->{create_time});

my $cc = $p->store_cc({
    cc_number       => '4353185781082049',
    cc_type         => 'visa',
    cc_expire_month => 3,
    cc_expire_year  => 2018,
    first_name      => 'Sherzod',
    last_name       => 'Ruzmetov'
});

ok($cc, "Stored CC valid until " . $cc->{valid_until});

my $cc_id = $cc->{id};

$cc = $p->get_cc( $cc_id );
ok($cc, $cc->{number});

$payment = $p->stored_cc_payment({id => $cc->{id}, amount => '19.95'});

ok($payment, "Payment was made on " . $payment->{create_time});



exit(0);
