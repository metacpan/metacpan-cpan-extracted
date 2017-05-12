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

my $trx_api             = Paymill::REST::Transactions->new(%base_args);
my $created_transaction = $trx_api->create(
    {
        amount      => 4200,
        token       => '098f6bcd4621d373cade4e832627b4f6',
        currency    => 'USD',
        description => 'Test refund through Paymill::REST on ' . time,
    }
);

my $refund_api     = Paymill::REST::Refunds->new(%base_args);
my $created_refund = $refund_api->create(
    {
        id     => $created_transaction->id,
        amount => 4200,
    }
);

my $found_refund = $refund_api->find($created_refund->id);

is(
    $found_refund->id,
    $created_refund->id,
    "Found refund via find(), IDs match"
);
is(
    $found_refund->amount,
    $created_refund->amount,
    "Found refund via find(), amount matches"
);

my @all_refunds = $refund_api->list({ order => 'created_at_desc' });
cmp_ok(scalar @all_refunds, ">=", 1, "Found at least 1 refund via list()");

my $found_previous_refund = 0;
foreach my $refund (@all_refunds) {
    $found_previous_refund++ if $refund->id eq $found_refund->id;
}
is($found_previous_refund, 1, "Previous created refund found via list()");

done_testing;
