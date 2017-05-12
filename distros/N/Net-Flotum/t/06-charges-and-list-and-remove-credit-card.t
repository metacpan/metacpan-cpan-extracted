use common::sense;
use Test::More;
use JSON::MaybeXS;
use Furl;

use_ok('Net::Flotum');
ok( my $flotum = Net::Flotum->new( merchant_api_key => 'm-just-testing' ), 'new ok' );

diag "creating customer";
my $customer = $flotum->new_customer(
    name           => 'cron',
    legal_document => rand
);

isa_ok $customer, 'Net::Flotum::Object::Customer';

diag "adding a credit card";

my $cc = $customer->add_credit_card( callback => 'http://localhostx:2202/too' );
is( $cc->{fields}{number}, '*CreditCard', 'Credit card number is required' );

ok( $cc->{href}, 'request has an href' );
like( $cc->{href}, qr|/credit-cards|, 'request href like *credit-cards*' );
like( $cc->{href}, qr|localhostx|,    'request href has callback' );

ok( $cc->{valid_until}, 'request has a time to expire.' );

my $furl = Furl->new( timeout => 25 );

my $req = $furl->post(
    $cc->{href},
    [ 'content-type' => 'application/json' ],    # headers
    encode_json(
        {
            name_on_card => 'This is a fake credit card',
            csc          => '123',
            number       => '5268590528188853',
            validity     => '201801',
            brand        => 'mastercard'
        }
    ),
);

ok( $req->is_success, 'request ok' );

my $credit_card = decode_json $req->content;

ok( $credit_card->{id}, 'credit card id' );

diag "creating charge";

can_ok $customer, 'new_charge';

my $charge = $customer->new_charge(
    amount                      => 200,
    currency                    => 'bra',
    merchant_payment_account_id => 1,
    metadata                    => {
        'Please use' => 'The way you need',
        'but'        => 'Do not use more than 10000 bytes after encoded in JSON',
    }
);

isa_ok $charge, 'Net::Flotum::Object::Charge';

ok( $charge->id, 'charge id' );

diag "payment";

can_ok $charge, 'payment';

ok(
    my $payment = $charge->payment(
        customer_credit_card_id => $credit_card->{id},
        csc_check               => '123',
    ),
    'payment',
);

is( $payment->{transaction_status}, 'queue', 'transaction_status' );

diag "capturing";

can_ok $charge, 'capture';
my $capture;
for ( 1 .. 100 ) {
    diag "waiting 1 seconds";
    sleep 1;

    $capture = eval { $charge->capture( description => "is optional" ) };
    next if $@;

    ok( $capture, 'capture charge' );
    last;
}

is( $capture->{transaction_status}, 'authorized', 'transaction_status' );

diag "refunding";

can_ok $charge, "refund";

ok( my $refund = $charge->refund(), 'refund charge' );

is( $refund->{status},             'aborted',         'status aborted' );
is( $refund->{transaction_status}, 'in-cancellation', 'transaction_status in-cancellation' );

diag "list_credit_cards";
my @cards = $customer->list_credit_cards;
is( @cards, 1, 'one card' );
my $card = $cards[0];

is( $card->mask,             '5268*********853', 'mask ok' );
is( $card->conjecture_brand, 'mastercard',       'brand is ok' );
is( $card->validity,         '201801',           'validity is ok' );

diag "removing credit card";
is( $cards[0]->remove, '1', 'removed' );

done_testing();

