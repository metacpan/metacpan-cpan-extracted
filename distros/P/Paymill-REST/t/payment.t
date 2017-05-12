use strict;
use Test::More;

use Paymill::REST;

unless ($ENV{PAYMILL_PRIVATE_KEY}) {
    plan skip_all => 'PAYMILL_PRIVATE_KEY not set';
    done_testing;
    exit;
}

$Paymill::REST::PRIVATE_KEY = $ENV{PAYMILL_PRIVATE_KEY};

my %base_args;

if ($ENV{TEST_LOCAL}) {
    %base_args = (
        base_url        => 'https://api.chipmunk.dev/v2/',
        auth_netloc     => 'api.chipmunk.dev:443',
        verify_hostname => 0,
    );

    if ($ENV{DEBUG}) {
        $base_args{debug} = 1;
    }
}

my $payment_api     = Paymill::REST::Payments->new(%base_args);
my $created_payment = $payment_api->create(
    {
        token => '098f6bcd4621d373cade4e832627b4f6',
    }
);

my $found_payment = $payment_api->find($created_payment->id);

is(
    $found_payment->id,
    $created_payment->id,
    "Found payment via find(), IDs match"
);

my @all_payments = $payment_api->list({ order => 'created_at_desc' });
cmp_ok(scalar @all_payments, ">=", 1, "Found at least 1 payment via list()");

my $found_previous_payment = 0;
foreach my $payment (@all_payments) {
    $found_previous_payment++ if $payment->id eq $found_payment->id;
}
is($found_previous_payment, 1, "Previous created payment found via list()");

$created_payment->delete;
eval { $payment_api->find($created_payment->id) };
ok($@ =~ /^Request error: 404/, "Previous created payment successfully deleted");

done_testing;
