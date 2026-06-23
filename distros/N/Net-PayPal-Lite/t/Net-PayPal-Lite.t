use strict;
use warnings;
use Test::More;

if ($ENV{NET_PAYPAL_CLIENT_ID} && $ENV{NET_PAYPAL_SECRET}) {
    plan(tests => 8);
}
else {
    plan(skip_all => "NET_PAYPAL_CLIENT_ID and NET_PAYPAL_SECRET env. variables must be set to run the tests");
}

use Net::PayPal::Lite;

Net::PayPal::Lite->live(0);

my $p = Net::PayPal::Lite->new(
    $ENV{NET_PAYPAL_CLIENT_ID},
    $ENV{NET_PAYPAL_SECRET},
);
ok( $p, "Access token is: " . $p->{access_token} );

my $year_in_future = (localtime)[5] + 1900 + 2;

my $resp = $p->cc_payment({
    cc_number       => '4111111111111111',
    cc_type         => 'visa',
    cc_expire_month => 3,
    cc_expire_year  => $year_in_future,
    first_name      => 'Jane',
    last_name       => 'Doe',
    amount          => 19.95,
});
my $payment_id = $resp->{id};
ok($resp->{state} eq "approved", $resp->{id});

$resp = $p->cc_payment({
    cc_number       => '4111111111111111',
    cc_type         => 'visa',
    cc_expire_month => 3,
    cc_expire_year  => $year_in_future,
    first_name      => 'CCREJECT-EC',
    last_name       => '',
    amount          => 19.95,
});
ok(!$resp, $p->error);

my $payment = $p->get_payment( $payment_id );

ok($payment, "Payment was made on " . $payment->{create_time});

my $cc = $p->store_cc({
    cc_number       => '4111111111111111',
    cc_type         => 'visa',
    cc_expire_month => 3,
    cc_expire_year  => $year_in_future,
    first_name      => 'Jane',
    last_name       => 'Doe'
});

ok($cc, "Stored CC valid until " . $cc->{valid_until});

my $cc_id = $cc->{id};

$cc = $p->get_cc( $cc_id );
ok($cc, $cc->{number});

$payment = $p->stored_cc_payment({id => $cc->{id}, amount => '19.95'});

ok($payment, "Payment was made on " . $payment->{create_time});

exit(0);
