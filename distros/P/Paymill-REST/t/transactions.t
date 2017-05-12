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
        description => 'Test transaction through Paymill::REST on ' . time,
    }
);

my $found_transaction = $trx_api->find($created_transaction->id);

is(
    $found_transaction->id,
    $created_transaction->id,
    "Found transaction via find(), IDs match"
);
is(
    $found_transaction->amount,
    $created_transaction->amount,
    "Found transaction via find(), amount matches"
);
is(
    $found_transaction->origin_amount,
    $created_transaction->origin_amount,
    "Found transaction via find(), origin_amount matches"
);
is(
    $found_transaction->description,
    $created_transaction->description,
    "Found transaction via find(), description matches"
);
is(
    $found_transaction->currency,
    $created_transaction->currency,
    "Found transaction via find(), currency matches"
);
is(
    $found_transaction->response_code,
    $created_transaction->response_code,
    "Found transaction via find(), response_code matches"
);
is(
    $found_transaction->created_at->epoch,
    $created_transaction->created_at->epoch,
    "Found transaction via find(), created_at matches"
);

my @all_transactions = $trx_api->list({ order => 'created_at_desc' });
cmp_ok(scalar @all_transactions, ">=", 1, "Found at least 1 transaction via list()");

my $found_previous_trx = 0;
foreach my $transaction (@all_transactions) {
    $found_previous_trx++ if $transaction->id eq $found_transaction->id;
}
is($found_previous_trx, 1, "Previous created transaction found via list()");

done_testing;
