use strictures 2;
use Test2::V0 -no_srand => 1;
use JSON ();

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Marketplace;

my $json = JSON->new->utf8->canonical;

my $pubkey = 'aa' x 32;

# === SYNOPSIS examples ===

subtest 'SYNOPSIS: stall_event' => sub {
    my $hex_pubkey = $pubkey;
    my $stall = Net::Nostr::Marketplace->stall_event(
        pubkey   => $hex_pubkey,
        id       => 'stall-1',
        name     => 'My Stall',
        currency => 'USD',
        shipping => [
            { id => 'zone-1', name => 'US', cost => 5.0, regions => ['US', 'CA'] },
        ],
    );
    is $stall->kind, 30017, 'stall is kind 30017';
};

subtest 'SYNOPSIS: product_event' => sub {
    my $hex_pubkey = $pubkey;
    my $product = Net::Nostr::Marketplace->product_event(
        pubkey     => $hex_pubkey,
        id         => 'prod-1',
        stall_id   => 'stall-1',
        name       => 'Widget',
        currency   => 'USD',
        price      => 10.50,
        quantity   => 100,
        categories => ['electronics'],
    );
    is $product->kind, 30018, 'product is kind 30018';
};

subtest 'SYNOPSIS: marketplace_event' => sub {
    my $hex_pubkey = $pubkey;
    my $merchant_pubkey = 'bb' x 32;
    my $market = Net::Nostr::Marketplace->marketplace_event(
        pubkey    => $hex_pubkey,
        id        => 'market-1',
        name      => 'My Market',
        merchants => [$merchant_pubkey],
    );
    is $market->kind, 30019, 'marketplace is kind 30019';
};

subtest 'SYNOPSIS: auction_event' => sub {
    my $hex_pubkey = $pubkey;
    my $auction = Net::Nostr::Marketplace->auction_event(
        pubkey       => $hex_pubkey,
        id           => 'auction-1',
        stall_id     => 'stall-1',
        name         => 'Rare Item',
        starting_bid => 1000,
        duration     => 86400,
    );
    is $auction->kind, 30020, 'auction is kind 30020';
};

subtest 'SYNOPSIS: bid_event' => sub {
    my $hex_pubkey = $pubkey;
    my $auction_event_id = 'dd' x 32;
    my $bid = Net::Nostr::Marketplace->bid_event(
        pubkey           => $hex_pubkey,
        amount           => 1500,
        auction_event_id => $auction_event_id,
    );
    is $bid->kind, 1021, 'bid is kind 1021';
};

subtest 'SYNOPSIS: bid_confirmation_event' => sub {
    my $hex_pubkey = $pubkey;
    my $bid_event_id = 'ee' x 32;
    my $auction_event_id = 'dd' x 32;
    my $confirm = Net::Nostr::Marketplace->bid_confirmation_event(
        pubkey           => $hex_pubkey,
        bid_event_id     => $bid_event_id,
        auction_event_id => $auction_event_id,
        status           => 'accepted',
    );
    is $confirm->kind, 1022, 'confirmation is kind 1022';
};

subtest 'SYNOPSIS: order_message' => sub {
    my $order = Net::Nostr::Marketplace->order_message(
        id          => 'order-1',
        items       => [{ product_id => 'prod-1', quantity => 2 }],
        shipping_id => 'zone-1',
    );
    my $data = $json->decode($order);
    is $data->{type}, 0, 'order is type 0';
};

subtest 'SYNOPSIS: payment_request_message' => sub {
    my $payment = Net::Nostr::Marketplace->payment_request_message(
        id              => 'order-1',
        payment_options => [{ type => 'ln', link => 'lnbc...' }],
    );
    my $data = $json->decode($payment);
    is $data->{type}, 1, 'payment request is type 1';
};

subtest 'SYNOPSIS: order_status_message' => sub {
    my $status = Net::Nostr::Marketplace->order_status_message(
        id      => 'order-1',
        message => 'Shipped!',
        paid    => JSON::true,
        shipped => JSON::true,
    );
    my $data = $json->decode($status);
    is $data->{type}, 2, 'order status is type 2';
};

subtest 'SYNOPSIS: from_event' => sub {
    my $event = make_event(
        pubkey  => $pubkey,
        kind    => 30017,
        content => $json->encode({ id => 's1', name => 'S', currency => 'USD', shipping => [] }),
        tags    => [['d', 's1']],
    );
    my $parsed = Net::Nostr::Marketplace->from_event($event);
    ok defined $parsed, 'from_event returns object';
};

subtest 'SYNOPSIS: parse_checkout_message' => sub {
    my $json_string = $json->encode({ type => 0, id => 'o1', items => [], shipping_id => 'z' });
    my $checkout = Net::Nostr::Marketplace->parse_checkout_message($json_string);
    is $checkout->checkout_type, 0, 'checkout type parsed';
    is $checkout->order_id, 'o1', 'order_id parsed';
};

# === Method doc examples ===

subtest 'stall_event doc example' => sub {
    my $hex_pubkey = $pubkey;
    my $event = Net::Nostr::Marketplace->stall_event(
        pubkey      => $hex_pubkey,
        id          => 'stall-1',
        name        => 'My Stall',
        description => 'Optional description',
        currency    => 'USD',
        shipping    => [
            { id => 'zone-1', name => 'US', cost => 5.0, regions => ['US'] },
        ],
    );
    is $event->kind, 30017, 'kind 30017';
    my $content = $json->decode($event->content);
    is $content->{description}, 'Optional description', 'description set';
};

subtest 'product_event doc example' => sub {
    my $hex_pubkey = $pubkey;
    my $event = Net::Nostr::Marketplace->product_event(
        pubkey      => $hex_pubkey,
        id          => 'prod-1',
        stall_id    => 'stall-1',
        name        => 'Widget',
        currency    => 'USD',
        price       => 10.50,
        quantity    => 100,
        description => 'A fine widget',
        images      => ['https://img.jpg'],
        specs       => [['color', 'blue']],
        shipping    => [{ id => 'zone-1', cost => 2.0 }],
        categories  => ['widgets'],
    );
    is $event->kind, 30018, 'kind 30018';
    my @t = grep { $_->[0] eq 't' } @{$event->tags};
    is $t[0][1], 'widgets', 'category tag';
};

subtest 'marketplace_event doc example' => sub {
    my $hex_pubkey = $pubkey;
    my $pubkey1 = 'bb' x 32;
    my $pubkey2 = 'cc' x 32;
    my $event = Net::Nostr::Marketplace->marketplace_event(
        pubkey    => $hex_pubkey,
        id        => 'market-1',
        name      => 'My Market',
        about     => 'A cool marketplace',
        ui        => { theme => 'dark', darkMode => JSON::true },
        merchants => [$pubkey1, $pubkey2],
    );
    is $event->kind, 30019, 'kind 30019';
};

subtest 'auction_event doc example' => sub {
    my $hex_pubkey = $pubkey;
    my $event = Net::Nostr::Marketplace->auction_event(
        pubkey       => $hex_pubkey,
        id           => 'auction-1',
        stall_id     => 'stall-1',
        name         => 'Rare Item',
        starting_bid => 1000,
        start_date   => 1700000000,
        duration     => 86400,
    );
    is $event->kind, 30020, 'kind 30020';
    my $content = $json->decode($event->content);
    is $content->{start_date}, 1700000000, 'start_date set';
};

subtest 'bid_event doc example' => sub {
    my $hex_pubkey = $pubkey;
    my $event_id = 'dd' x 32;
    my $event = Net::Nostr::Marketplace->bid_event(
        pubkey           => $hex_pubkey,
        amount           => 1500,
        auction_event_id => $event_id,
    );
    is $event->kind, 1021, 'kind 1021';
    is $event->content, '1500', 'content is amount';
};

subtest 'bid_confirmation_event doc example' => sub {
    my $hex_pubkey = $pubkey;
    my $bid_id = 'ee' x 32;
    my $auction_id = 'dd' x 32;
    my $event = Net::Nostr::Marketplace->bid_confirmation_event(
        pubkey             => $hex_pubkey,
        bid_event_id       => $bid_id,
        auction_event_id   => $auction_id,
        status             => 'accepted',
        message            => 'Welcome!',
        duration_extended  => 300,
    );
    is $event->kind, 1022, 'kind 1022';
    my $content = $json->decode($event->content);
    is $content->{duration_extended}, 300, 'duration_extended set';
};

subtest 'order_message doc example' => sub {
    my $msg = Net::Nostr::Marketplace->order_message(
        id          => 'order-1',
        items       => [{ product_id => 'prod-1', quantity => 2 }],
        shipping_id => 'zone-1',
        name        => 'Alice',
        address     => '123 Main St',
        message     => 'Gift wrap please',
        contact     => { nostr => $pubkey, phone => '+1234567890', email => 'a@b.com' },
    );
    my $data = $json->decode($msg);
    is $data->{contact}{email}, 'a@b.com', 'contact email';
};

subtest 'payment_request_message doc example' => sub {
    my $msg = Net::Nostr::Marketplace->payment_request_message(
        id              => 'order-1',
        payment_options => [
            { type => 'ln', link => 'lnbc...' },
            { type => 'btc', link => 'bc1q...' },
        ],
        message => 'Pay within 24 hours',
    );
    my $data = $json->decode($msg);
    is scalar @{$data->{payment_options}}, 2, 'two payment options';
};

subtest 'order_status_message doc example' => sub {
    my $msg = Net::Nostr::Marketplace->order_status_message(
        id      => 'order-1',
        message => 'Shipped!',
        paid    => JSON::true,
        shipped => JSON::true,
    );
    my $data = $json->decode($msg);
    is $data->{paid}, JSON::true, 'paid is true';
};

subtest 'validate doc example' => sub {
    my $event = Net::Nostr::Marketplace->stall_event(
        pubkey   => $pubkey,
        id       => 's1',
        name     => 'S',
        currency => 'USD',
        shipping => [{ id => 'z', cost => 0, regions => ['US'] }],
    );
    ok(Net::Nostr::Marketplace->validate($event)), 'validate returns true';
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $info = Net::Nostr::Marketplace->new(
        name  => 'Widget',
        price => 10.50,
    );
    is $info->name, 'Widget';
    is $info->price, 10.50;
    is $info->categories, [];
    is $info->images, [];
    is $info->shipping, [];
    is $info->specs, [];
    is $info->merchants, [];
    is $info->items, [];
    is $info->payment_options, [];
};

subtest 'new() rejects unknown arguments' => sub {
    eval { Net::Nostr::Marketplace->new(
        name  => 'Widget',
        price => 10.50,
        bogus => 'value',
    ) };
    like($@, qr/unknown.+bogus/i, 'unknown argument rejected');
};

done_testing;
