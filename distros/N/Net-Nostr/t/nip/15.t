use strictures 2;
use Test2::V0 -no_srand => 1;
use JSON ();

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Marketplace;

my $json = JSON->new->utf8->canonical;

my $pubkey = 'aa' x 32;

# === kind 30017: Stall Event ===

subtest 'stall_event creates kind 30017' => sub {
    my $ev = Net::Nostr::Marketplace->stall_event(
        pubkey   => $pubkey,
        id       => 'stall-1',
        name     => 'My Stall',
        currency => 'USD',
        shipping => [
            { id => 'zone-1', name => 'US', cost => 5.0, regions => ['US', 'CA'] },
        ],
    );
    is $ev->kind, 30017, 'kind is 30017';
    is $ev->pubkey, $pubkey, 'pubkey set';

    # d tag MUST be the same as the stall id
    my ($d) = grep { $_->[0] eq 'd' } @{$ev->tags};
    is $d->[1], 'stall-1', 'd tag matches stall id';

    my $content = $json->decode($ev->content);
    is $content->{id}, 'stall-1', 'id in content';
    is $content->{name}, 'My Stall', 'name in content';
    is $content->{currency}, 'USD', 'currency in content';
    is scalar @{$content->{shipping}}, 1, 'one shipping zone';
    is $content->{shipping}[0]{id}, 'zone-1', 'shipping zone id';
    is $content->{shipping}[0]{name}, 'US', 'shipping zone name';
    is $content->{shipping}[0]{cost}, 5.0, 'shipping zone cost';
    is $content->{shipping}[0]{regions}, ['US', 'CA'], 'shipping zone regions';
};

subtest 'stall_event with optional description' => sub {
    my $ev = Net::Nostr::Marketplace->stall_event(
        pubkey      => $pubkey,
        id          => 'stall-2',
        name        => 'Digital Goods',
        description => 'Selling digital items',
        currency    => 'sat',
        shipping    => [
            { id => 'worldwide', cost => 0, regions => ['worldwide'] },
        ],
    );
    my $content = $json->decode($ev->content);
    is $content->{description}, 'Selling digital items', 'description in content';
    is $content->{shipping}[0]{cost}, 0, 'zero shipping cost for digital goods';
};

subtest 'stall_event without description omits field' => sub {
    my $ev = Net::Nostr::Marketplace->stall_event(
        pubkey   => $pubkey,
        id       => 'stall-3',
        name     => 'Minimal',
        currency => 'USD',
        shipping => [{ id => 'z1', cost => 1, regions => ['US'] }],
    );
    my $content = $json->decode($ev->content);
    ok !exists $content->{description}, 'description omitted when not provided';
};

subtest 'stall_event requires id, name, currency, shipping' => sub {
    eval { Net::Nostr::Marketplace->stall_event(pubkey => $pubkey, name => 'x', currency => 'USD', shipping => []) };
    like $@, qr/id/, 'croaks without id';

    eval { Net::Nostr::Marketplace->stall_event(pubkey => $pubkey, id => 'x', currency => 'USD', shipping => []) };
    like $@, qr/name/, 'croaks without name';

    eval { Net::Nostr::Marketplace->stall_event(pubkey => $pubkey, id => 'x', name => 'x', shipping => []) };
    like $@, qr/currency/, 'croaks without currency';

    eval { Net::Nostr::Marketplace->stall_event(pubkey => $pubkey, id => 'x', name => 'x', currency => 'USD') };
    like $@, qr/shipping/, 'croaks without shipping';
};

subtest 'stall_event multiple shipping zones' => sub {
    my $ev = Net::Nostr::Marketplace->stall_event(
        pubkey   => $pubkey,
        id       => 'stall-multi',
        name     => 'Global Store',
        currency => 'USD',
        shipping => [
            { id => 'domestic', name => 'Domestic', cost => 5.0, regions => ['US'] },
            { id => 'intl', name => 'International', cost => 15.0, regions => ['EU', 'Asia'] },
        ],
    );
    my $content = $json->decode($ev->content);
    is scalar @{$content->{shipping}}, 2, 'two shipping zones';
};

subtest 'stall_event shipping zone without optional name' => sub {
    my $ev = Net::Nostr::Marketplace->stall_event(
        pubkey   => $pubkey,
        id       => 'stall-noname',
        name     => 'Store',
        currency => 'USD',
        shipping => [{ id => 'z1', cost => 5, regions => ['US'] }],
    );
    my $content = $json->decode($ev->content);
    ok !exists $content->{shipping}[0]{name}, 'shipping zone name omitted when not provided';
};

# === kind 30018: Product Event ===

subtest 'product_event creates kind 30018' => sub {
    my $ev = Net::Nostr::Marketplace->product_event(
        pubkey   => $pubkey,
        id       => 'prod-1',
        stall_id => 'stall-1',
        name     => 'Widget',
        currency => 'USD',
        price    => 10.50,
        quantity => 100,
    );
    is $ev->kind, 30018, 'kind is 30018';

    my ($d) = grep { $_->[0] eq 'd' } @{$ev->tags};
    is $d->[1], 'prod-1', 'd tag matches product id';

    my $content = $json->decode($ev->content);
    is $content->{id}, 'prod-1', 'id in content';
    is $content->{stall_id}, 'stall-1', 'stall_id in content';
    is $content->{name}, 'Widget', 'name in content';
    is $content->{currency}, 'USD', 'currency in content';
    is $content->{price}, 10.50, 'price in content';
    is $content->{quantity}, 100, 'quantity in content';
};

subtest 'product_event with all optional fields' => sub {
    my $ev = Net::Nostr::Marketplace->product_event(
        pubkey      => $pubkey,
        id          => 'prod-2',
        stall_id    => 'stall-1',
        name        => 'Phone',
        description => 'A great phone',
        images      => ['https://img1.jpg', 'https://img2.jpg'],
        currency    => 'USD',
        price       => 999.99,
        quantity    => 50,
        specs       => [
            ['operating_system', 'Android 12.0'],
            ['screen_size', '6.4 inches'],
            ['connector_type', 'USB Type C'],
        ],
        shipping    => [
            { id => 'zone-1', cost => 10.0 },
        ],
        categories  => ['electronics', 'phones'],
    );

    my $content = $json->decode($ev->content);
    is $content->{description}, 'A great phone', 'description';
    is $content->{images}, ['https://img1.jpg', 'https://img2.jpg'], 'images';
    is $content->{specs}, [
        ['operating_system', 'Android 12.0'],
        ['screen_size', '6.4 inches'],
        ['connector_type', 'USB Type C'],
    ], 'specs from spec example';
    is $content->{shipping}[0]{id}, 'zone-1', 'product shipping zone id';
    is $content->{shipping}[0]{cost}, 10.0, 'product shipping extra cost';

    # t tags for categories
    my @t_tags = grep { $_->[0] eq 't' } @{$ev->tags};
    is scalar @t_tags, 2, 'two t tags for categories';
    is $t_tags[0][1], 'electronics', 'first category';
    is $t_tags[1][1], 'phones', 'second category';
};

subtest 'product_event quantity can be null (unlimited)' => sub {
    my $ev = Net::Nostr::Marketplace->product_event(
        pubkey   => $pubkey,
        id       => 'digital-1',
        stall_id => 'stall-1',
        name     => 'E-book',
        currency => 'USD',
        price    => 9.99,
        quantity => undef,
    );
    my $content = $json->decode($ev->content);
    ok exists $content->{quantity}, 'quantity key exists';
    is $content->{quantity}, undef, 'quantity is null for unlimited items';
};

subtest 'product_event requires id, stall_id, name, currency, price' => sub {
    my %base = (pubkey => $pubkey, id => 'x', stall_id => 's', name => 'n', currency => 'USD', price => 1);

    for my $field (qw(id stall_id name currency price)) {
        my %args = %base;
        delete $args{$field};
        eval { Net::Nostr::Marketplace->product_event(%args) };
        like $@, qr/$field/, "croaks without $field";
    }
};

subtest 'product_event optional fields omitted when not provided' => sub {
    my $ev = Net::Nostr::Marketplace->product_event(
        pubkey   => $pubkey,
        id       => 'minimal',
        stall_id => 's1',
        name     => 'Item',
        currency => 'USD',
        price    => 5,
    );
    my $content = $json->decode($ev->content);
    ok !exists $content->{description}, 'no description';
    ok !exists $content->{images}, 'no images';
    ok !exists $content->{specs}, 'no specs';
    ok !exists $content->{shipping}, 'no product shipping';
    ok !exists $content->{quantity}, 'no quantity when not passed';
};

# === kind 30019: Marketplace UI/UX Event ===

subtest 'marketplace_event creates kind 30019' => sub {
    my $ev = Net::Nostr::Marketplace->marketplace_event(
        pubkey => $pubkey,
        id     => 'market-1',
        name   => 'My Market',
        about  => 'A cool marketplace',
        ui     => {
            picture  => 'https://logo.png',
            banner   => 'https://banner.png',
            theme    => 'dark',
            darkMode => JSON::true,
        },
        merchants => ['bb' x 32, 'cc' x 32],
    );
    is $ev->kind, 30019, 'kind is 30019';

    my ($d) = grep { $_->[0] eq 'd' } @{$ev->tags};
    is $d->[1], 'market-1', 'd tag set';

    my $content = $json->decode($ev->content);
    is $content->{name}, 'My Market', 'name';
    is $content->{about}, 'A cool marketplace', 'about';
    is $content->{ui}{picture}, 'https://logo.png', 'ui picture';
    is $content->{ui}{banner}, 'https://banner.png', 'ui banner';
    is $content->{ui}{theme}, 'dark', 'ui theme';
    is $content->{ui}{darkMode}, JSON::true, 'ui darkMode';
    is scalar @{$content->{merchants}}, 2, 'two merchants';
};

subtest 'marketplace_event all fields optional except id' => sub {
    my $ev = Net::Nostr::Marketplace->marketplace_event(
        pubkey => $pubkey,
        id     => 'minimal-market',
    );
    is $ev->kind, 30019, 'kind is 30019';
    my $content = $json->decode($ev->content);
    ok !exists $content->{name}, 'name omitted';
    ok !exists $content->{about}, 'about omitted';
    ok !exists $content->{ui}, 'ui omitted';
    ok !exists $content->{merchants}, 'merchants omitted';
};

# === kind 30020: Auction Event ===

subtest 'auction_event creates kind 30020' => sub {
    my $ev = Net::Nostr::Marketplace->auction_event(
        pubkey       => $pubkey,
        id           => 'auction-1',
        stall_id     => 'stall-1',
        name         => 'Rare Item',
        starting_bid => 1000,
        duration     => 86400,
    );
    is $ev->kind, 30020, 'kind is 30020';

    my ($d) = grep { $_->[0] eq 'd' } @{$ev->tags};
    is $d->[1], 'auction-1', 'd tag matches auction id';

    my $content = $json->decode($ev->content);
    is $content->{id}, 'auction-1', 'id';
    is $content->{stall_id}, 'stall-1', 'stall_id';
    is $content->{name}, 'Rare Item', 'name';
    is $content->{starting_bid}, 1000, 'starting_bid';
    is $content->{duration}, 86400, 'duration';
};

subtest 'auction_event with all optional fields' => sub {
    my $ev = Net::Nostr::Marketplace->auction_event(
        pubkey       => $pubkey,
        id           => 'auction-2',
        stall_id     => 'stall-1',
        name         => 'Painting',
        description  => 'A beautiful painting',
        images       => ['https://painting.jpg'],
        starting_bid => 5000,
        start_date   => 1700000000,
        duration     => 172800,
        specs        => [['medium', 'oil on canvas'], ['size', '24x36']],
        shipping     => [{ id => 'zone-1', cost => 25.0 }],
    );
    my $content = $json->decode($ev->content);
    is $content->{description}, 'A beautiful painting', 'description';
    is $content->{images}, ['https://painting.jpg'], 'images';
    is $content->{start_date}, 1700000000, 'start_date';
    is $content->{specs}, [['medium', 'oil on canvas'], ['size', '24x36']], 'specs';
    is $content->{shipping}[0]{cost}, 25.0, 'shipping cost';
};

subtest 'auction_event start_date omitted when not provided' => sub {
    my $ev = Net::Nostr::Marketplace->auction_event(
        pubkey       => $pubkey,
        id           => 'auction-hidden',
        stall_id     => 'stall-1',
        name         => 'Mystery',
        starting_bid => 100,
        duration     => 3600,
    );
    my $content = $json->decode($ev->content);
    ok !exists $content->{start_date}, 'start_date omitted (unknown/hidden)';
};

subtest 'auction_event requires id, stall_id, name, starting_bid, duration' => sub {
    my %base = (pubkey => $pubkey, id => 'x', stall_id => 's', name => 'n', starting_bid => 1, duration => 60);

    for my $field (qw(id stall_id name starting_bid duration)) {
        my %args = %base;
        delete $args{$field};
        eval { Net::Nostr::Marketplace->auction_event(%args) };
        like $@, qr/$field/, "croaks without $field";
    }
};

# === kind 1021: Bid Event ===

subtest 'bid_event creates kind 1021' => sub {
    my $auction_event_id = 'dd' x 32;
    my $ev = Net::Nostr::Marketplace->bid_event(
        pubkey           => $pubkey,
        amount           => 1500,
        auction_event_id => $auction_event_id,
    );
    is $ev->kind, 1021, 'kind is 1021';
    is $ev->content, '1500', 'content is amount as string';

    my ($e) = grep { $_->[0] eq 'e' } @{$ev->tags};
    is $e->[1], $auction_event_id, 'e tag references auction event';
};

subtest 'bid_event requires amount and auction_event_id' => sub {
    eval { Net::Nostr::Marketplace->bid_event(pubkey => $pubkey, amount => 100) };
    like $@, qr/auction_event_id/, 'croaks without auction_event_id';

    eval { Net::Nostr::Marketplace->bid_event(pubkey => $pubkey, auction_event_id => 'x') };
    like $@, qr/amount/, 'croaks without amount';
};

# === kind 1022: Bid Confirmation Event ===

subtest 'bid_confirmation_event creates kind 1022' => sub {
    my $bid_event_id = 'ee' x 32;
    my $auction_event_id = 'dd' x 32;
    my $ev = Net::Nostr::Marketplace->bid_confirmation_event(
        pubkey           => $pubkey,
        bid_event_id     => $bid_event_id,
        auction_event_id => $auction_event_id,
        status           => 'accepted',
    );
    is $ev->kind, 1022, 'kind is 1022';

    my $content = $json->decode($ev->content);
    is $content->{status}, 'accepted', 'status in content';

    my @e_tags = grep { $_->[0] eq 'e' } @{$ev->tags};
    is scalar @e_tags, 2, 'two e tags';
    is $e_tags[0][1], $bid_event_id, 'first e tag references bid';
    is $e_tags[1][1], $auction_event_id, 'second e tag references auction';
};

subtest 'bid_confirmation_event status values' => sub {
    for my $status (qw(accepted rejected pending winner)) {
        my $ev = Net::Nostr::Marketplace->bid_confirmation_event(
            pubkey           => $pubkey,
            bid_event_id     => 'ee' x 32,
            auction_event_id => 'dd' x 32,
            status           => $status,
        );
        my $content = $json->decode($ev->content);
        is $content->{status}, $status, "status '$status' preserved";
    }
};

subtest 'bid_confirmation_event with optional message and duration_extended' => sub {
    my $ev = Net::Nostr::Marketplace->bid_confirmation_event(
        pubkey             => $pubkey,
        bid_event_id       => 'ee' x 32,
        auction_event_id   => 'dd' x 32,
        status             => 'accepted',
        message            => 'Bid accepted, good luck!',
        duration_extended  => 300,
    );
    my $content = $json->decode($ev->content);
    is $content->{message}, 'Bid accepted, good luck!', 'message in content';
    is $content->{duration_extended}, 300, 'duration_extended in content';
};

subtest 'bid_confirmation_event requires status, bid_event_id, auction_event_id' => sub {
    my %base = (pubkey => $pubkey, bid_event_id => 'ee' x 32, auction_event_id => 'dd' x 32, status => 'accepted');

    for my $field (qw(status bid_event_id auction_event_id)) {
        my %args = %base;
        delete $args{$field};
        eval { Net::Nostr::Marketplace->bid_confirmation_event(%args) };
        like $@, qr/$field/, "croaks without $field";
    }
};

# === Checkout Messages ===

subtest 'order_message builds type 0 JSON' => sub {
    my $msg = Net::Nostr::Marketplace->order_message(
        id          => 'order-1',
        items       => [
            { product_id => 'prod-1', quantity => 2 },
            { product_id => 'prod-2', quantity => 1 },
        ],
        shipping_id => 'zone-1',
        name        => 'Alice',
        address     => '123 Main St',
        message     => 'Please gift wrap',
        contact     => {
            nostr => $pubkey,
            phone => '+1234567890',
            email => 'alice@example.com',
        },
    );
    my $data = $json->decode($msg);
    is $data->{type}, 0, 'type is 0 (order)';
    is $data->{id}, 'order-1', 'order id';
    is scalar @{$data->{items}}, 2, 'two items';
    is $data->{items}[0]{product_id}, 'prod-1', 'first item product_id';
    is $data->{items}[0]{quantity}, 2, 'first item quantity';
    is $data->{shipping_id}, 'zone-1', 'shipping_id';
    is $data->{name}, 'Alice', 'name';
    is $data->{address}, '123 Main St', 'address';
    is $data->{message}, 'Please gift wrap', 'message';
    is $data->{contact}{nostr}, $pubkey, 'contact nostr';
    is $data->{contact}{phone}, '+1234567890', 'contact phone';
    is $data->{contact}{email}, 'alice@example.com', 'contact email';
};

subtest 'order_message requires id, items, shipping_id' => sub {
    my %base = (id => 'x', items => [{ product_id => 'p', quantity => 1 }], shipping_id => 'z');

    for my $field (qw(id items shipping_id)) {
        my %args = %base;
        delete $args{$field};
        eval { Net::Nostr::Marketplace->order_message(%args) };
        like $@, qr/$field/, "croaks without $field";
    }
};

subtest 'order_message optional fields omitted' => sub {
    my $msg = Net::Nostr::Marketplace->order_message(
        id          => 'order-min',
        items       => [{ product_id => 'p', quantity => 1 }],
        shipping_id => 'z1',
    );
    my $data = $json->decode($msg);
    is $data->{type}, 0, 'type is 0';
    ok !exists $data->{name}, 'name omitted';
    ok !exists $data->{address}, 'address omitted';
    ok !exists $data->{message}, 'message omitted';
    ok !exists $data->{contact}, 'contact omitted';
};

subtest 'payment_request_message builds type 1 JSON' => sub {
    my $msg = Net::Nostr::Marketplace->payment_request_message(
        id              => 'order-1',
        payment_options => [
            { type => 'url', link => 'https://pay.example.com/123' },
            { type => 'btc', link => 'bc1q...' },
            { type => 'ln', link => 'lnbc...' },
            { type => 'lnurl', link => 'lnurl1...' },
        ],
        message => 'Please pay within 24 hours',
    );
    my $data = $json->decode($msg);
    is $data->{type}, 1, 'type is 1 (payment request)';
    is $data->{id}, 'order-1', 'order id';
    is scalar @{$data->{payment_options}}, 4, 'four payment options';
    is $data->{payment_options}[0]{type}, 'url', 'first option type';
    is $data->{payment_options}[1]{type}, 'btc', 'second option type';
    is $data->{payment_options}[2]{type}, 'ln', 'third option type';
    is $data->{payment_options}[3]{type}, 'lnurl', 'fourth option type';
    is $data->{message}, 'Please pay within 24 hours', 'message';
};

subtest 'payment_request_message without optional message' => sub {
    my $msg = Net::Nostr::Marketplace->payment_request_message(
        id              => 'order-1',
        payment_options => [{ type => 'ln', link => 'lnbc...' }],
    );
    my $data = $json->decode($msg);
    is $data->{type}, 1, 'type is 1';
    ok !exists $data->{message}, 'message omitted when not provided';
};

subtest 'payment_request_message requires id and payment_options' => sub {
    eval { Net::Nostr::Marketplace->payment_request_message(payment_options => []) };
    like $@, qr/id/, 'croaks without id';

    eval { Net::Nostr::Marketplace->payment_request_message(id => 'x') };
    like $@, qr/payment_options/, 'croaks without payment_options';
};

subtest 'order_status_message builds type 2 JSON' => sub {
    my $msg = Net::Nostr::Marketplace->order_status_message(
        id      => 'order-1',
        message => 'Your order has shipped!',
        paid    => JSON::true,
        shipped => JSON::true,
    );
    my $data = $json->decode($msg);
    is $data->{type}, 2, 'type is 2 (order status)';
    is $data->{id}, 'order-1', 'order id';
    is $data->{message}, 'Your order has shipped!', 'message';
    is $data->{paid}, JSON::true, 'paid is true';
    is $data->{shipped}, JSON::true, 'shipped is true';
};

subtest 'order_status_message requires id, message, paid, shipped' => sub {
    my %base = (id => 'x', message => 'm', paid => JSON::true, shipped => JSON::false);

    for my $field (qw(id message paid shipped)) {
        my %args = %base;
        delete $args{$field};
        eval { Net::Nostr::Marketplace->order_status_message(%args) };
        like $@, qr/$field/, "croaks without $field";
    }
};

# === from_event ===

subtest 'from_event parses kind 30017 stall' => sub {
    my $ev = make_event(
        pubkey  => $pubkey,
        kind    => 30017,
        content => $json->encode({
            id => 'stall-1', name => 'My Stall', currency => 'USD',
            shipping => [{ id => 'z1', cost => 5, regions => ['US'] }],
        }),
        tags => [['d', 'stall-1']],
    );
    my $stall = Net::Nostr::Marketplace->from_event($ev);
    is $stall->stall_id, 'stall-1', 'stall id parsed';
    is $stall->name, 'My Stall', 'name parsed';
    is $stall->currency, 'USD', 'currency parsed';
    is scalar @{$stall->shipping}, 1, 'shipping parsed';
};

subtest 'from_event parses kind 30018 product' => sub {
    my $ev = make_event(
        pubkey  => $pubkey,
        kind    => 30018,
        content => $json->encode({
            id => 'prod-1', stall_id => 's1', name => 'Widget',
            currency => 'USD', price => 10, quantity => 5,
        }),
        tags => [['d', 'prod-1'], ['t', 'electronics'], ['t', 'gadgets']],
    );
    my $product = Net::Nostr::Marketplace->from_event($ev);
    is $product->product_id, 'prod-1', 'product id parsed';
    is $product->stall_id, 's1', 'stall_id parsed';
    is $product->name, 'Widget', 'name parsed';
    is $product->price, 10, 'price parsed';
    is $product->categories, ['electronics', 'gadgets'], 'categories from t tags';
};

subtest 'from_event parses kind 30020 auction' => sub {
    my $ev = make_event(
        pubkey  => $pubkey,
        kind    => 30020,
        content => $json->encode({
            id => 'auc-1', stall_id => 's1', name => 'Rare',
            starting_bid => 100, duration => 3600,
        }),
        tags => [['d', 'auc-1']],
    );
    my $auction = Net::Nostr::Marketplace->from_event($ev);
    is $auction->product_id, 'auc-1', 'auction id parsed';
    is $auction->starting_bid, 100, 'starting_bid parsed';
    is $auction->duration, 3600, 'duration parsed';
};

subtest 'from_event parses kind 1021 bid' => sub {
    my $auction_id = 'dd' x 32;
    my $ev = make_event(
        pubkey  => $pubkey,
        kind    => 1021,
        content => '1500',
        tags    => [['e', $auction_id]],
    );
    my $bid = Net::Nostr::Marketplace->from_event($ev);
    is $bid->amount, 1500, 'amount parsed from content';
    is $bid->auction_event_id, $auction_id, 'auction_event_id from e tag';
};

subtest 'from_event parses kind 1022 bid confirmation' => sub {
    my $bid_id = 'ee' x 32;
    my $auction_id = 'dd' x 32;
    my $ev = make_event(
        pubkey  => $pubkey,
        kind    => 1022,
        content => $json->encode({ status => 'winner', message => 'You won!' }),
        tags    => [['e', $bid_id], ['e', $auction_id]],
    );
    my $conf = Net::Nostr::Marketplace->from_event($ev);
    is $conf->status, 'winner', 'status parsed';
    is $conf->message, 'You won!', 'message parsed';
    is $conf->bid_event_id, $bid_id, 'bid_event_id from first e tag';
    is $conf->auction_event_id, $auction_id, 'auction_event_id from second e tag';
    is $conf->duration_extended, undef, 'duration_extended undef when absent';
};

subtest 'from_event parses kind 1022 duration_extended' => sub {
    my $bid_id = 'ee' x 32;
    my $auction_id = 'dd' x 32;
    my $ev = make_event(
        pubkey  => $pubkey,
        kind    => 1022,
        content => $json->encode({ status => 'accepted', duration_extended => 300 }),
        tags    => [['e', $bid_id], ['e', $auction_id]],
    );
    my $conf = Net::Nostr::Marketplace->from_event($ev);
    is $conf->duration_extended, 300, 'duration_extended parsed';
};

subtest 'from_event parses kind 30019 marketplace' => sub {
    my $ev = make_event(
        pubkey  => $pubkey,
        kind    => 30019,
        content => $json->encode({
            name => 'Market', about => 'A marketplace',
            ui => { theme => 'light', darkMode => JSON::false },
            merchants => ['bb' x 32],
        }),
        tags => [['d', 'market-1']],
    );
    my $market = Net::Nostr::Marketplace->from_event($ev);
    is $market->name, 'Market', 'name parsed';
    is $market->about, 'A marketplace', 'about parsed';
    is $market->ui->{theme}, 'light', 'ui parsed';
    is scalar @{$market->merchants}, 1, 'merchants parsed';
};

subtest 'from_event returns undef for unrecognized kind' => sub {
    my $ev = make_event(pubkey => $pubkey, kind => 1, content => '', tags => []);
    ok !defined Net::Nostr::Marketplace->from_event($ev), 'undef for kind 1';
};

# === parse_checkout_message ===

subtest 'parse_checkout_message parses type 0 order' => sub {
    my $msg = $json->encode({
        type => 0, id => 'order-1',
        items => [{ product_id => 'p1', quantity => 2 }],
        shipping_id => 'z1',
        contact => { nostr => $pubkey },
    });
    my $order = Net::Nostr::Marketplace->parse_checkout_message($msg);
    is $order->checkout_type, 0, 'type 0';
    is $order->order_id, 'order-1', 'order id';
    is scalar @{$order->items}, 1, 'items parsed';
    is $order->shipping_id, 'z1', 'shipping_id';
};

subtest 'parse_checkout_message parses type 1 payment request' => sub {
    my $msg = $json->encode({
        type => 1, id => 'order-1',
        payment_options => [
            { type => 'ln', link => 'lnbc...' },
        ],
    });
    my $req = Net::Nostr::Marketplace->parse_checkout_message($msg);
    is $req->checkout_type, 1, 'type 1';
    is scalar @{$req->payment_options}, 1, 'payment options parsed';
    is $req->payment_options->[0]{type}, 'ln', 'payment option type';
};

subtest 'parse_checkout_message parses type 2 order status' => sub {
    my $msg = $json->encode({
        type => 2, id => 'order-1',
        message => 'Shipped!', paid => JSON::true, shipped => JSON::true,
    });
    my $status = Net::Nostr::Marketplace->parse_checkout_message($msg);
    is $status->checkout_type, 2, 'type 2';
    is $status->order_id, 'order-1', 'order id';
    is $status->message, 'Shipped!', 'message';
    is $status->paid, JSON::true, 'paid';
    is $status->shipped, JSON::true, 'shipped';
};

# === validate ===

subtest 'validate kind 30017 requires d tag' => sub {
    my $ev = make_event(pubkey => $pubkey, kind => 30017, content => '{}', tags => []);
    eval { Net::Nostr::Marketplace->validate($ev) };
    like $@, qr/d tag/, 'croaks without d tag';

    my $ev2 = make_event(pubkey => $pubkey, kind => 30017, content => '{}', tags => [['d', 'stall-1']]);
    ok(Net::Nostr::Marketplace->validate($ev2)), 'valid with d tag';
};

subtest 'validate kind 30018 requires d tag' => sub {
    my $ev = make_event(pubkey => $pubkey, kind => 30018, content => '{}', tags => []);
    eval { Net::Nostr::Marketplace->validate($ev) };
    like $@, qr/d tag/, 'croaks without d tag';
};

subtest 'validate kind 1021 requires e tag' => sub {
    my $ev = make_event(pubkey => $pubkey, kind => 1021, content => '100', tags => []);
    eval { Net::Nostr::Marketplace->validate($ev) };
    like $@, qr/e tag/, 'croaks without e tag';
};

subtest 'validate kind 1022 requires two e tags' => sub {
    my $ev = make_event(pubkey => $pubkey, kind => 1022, content => '{}', tags => [['e', 'x']]);
    eval { Net::Nostr::Marketplace->validate($ev) };
    like $@, qr/two e tags/, 'croaks with only one e tag';

    my $ev2 = make_event(pubkey => $pubkey, kind => 1022, content => '{"status":"accepted"}',
        tags => [['e', 'bid-id'], ['e', 'auction-id']]);
    ok(Net::Nostr::Marketplace->validate($ev2)), 'valid with two e tags';
};

subtest 'validate rejects unrecognized kinds' => sub {
    my $ev = make_event(pubkey => $pubkey, kind => 1, content => '', tags => []);
    eval { Net::Nostr::Marketplace->validate($ev) };
    like $@, qr/30017|30018|30019|30020|1021|1022/, 'croaks for unrecognized kind';
};

# === Addressable event kinds (30000-39999) ===

subtest 'stall, product, marketplace, auction are addressable' => sub {
    for my $kind (30017, 30018, 30019, 30020) {
        ok $kind >= 30000 && $kind < 40000, "kind $kind is in addressable range";
    }
};

# === d tag MUST match id ===

subtest 'stall d tag matches content id' => sub {
    my $ev = Net::Nostr::Marketplace->stall_event(
        pubkey => $pubkey, id => 'my-stall',
        name => 'S', currency => 'USD',
        shipping => [{ id => 'z', cost => 0, regions => ['US'] }],
    );
    my ($d) = grep { $_->[0] eq 'd' } @{$ev->tags};
    my $content = $json->decode($ev->content);
    is $d->[1], $content->{id}, 'stall d tag == content id';
};

subtest 'product d tag matches content id' => sub {
    my $ev = Net::Nostr::Marketplace->product_event(
        pubkey => $pubkey, id => 'my-prod',
        stall_id => 's1', name => 'P', currency => 'USD', price => 1,
    );
    my ($d) = grep { $_->[0] eq 'd' } @{$ev->tags};
    my $content = $json->decode($ev->content);
    is $d->[1], $content->{id}, 'product d tag == content id';
};

subtest 'auction d tag matches content id' => sub {
    my $ev = Net::Nostr::Marketplace->auction_event(
        pubkey => $pubkey, id => 'my-auc',
        stall_id => 's1', name => 'A', starting_bid => 1, duration => 60,
    );
    my ($d) = grep { $_->[0] eq 'd' } @{$ev->tags};
    my $content = $json->decode($ev->content);
    is $d->[1], $content->{id}, 'auction d tag == content id';
};

# === Payment option types from spec ===

subtest 'payment option types: url, btc, ln, lnurl' => sub {
    for my $type (qw(url btc ln lnurl)) {
        my $msg = Net::Nostr::Marketplace->payment_request_message(
            id => 'order-1',
            payment_options => [{ type => $type, link => 'test-link' }],
        );
        my $data = $json->decode($msg);
        is $data->{payment_options}[0]{type}, $type, "payment type '$type' preserved";
    }
};

# === Spec audit additions ===

subtest 'bid_confirmation with rejected status and message' => sub {
    my $ev = Net::Nostr::Marketplace->bid_confirmation_event(
        pubkey           => $pubkey,
        bid_event_id     => 'ee' x 32,
        auction_event_id => 'dd' x 32,
        status           => 'rejected',
        message          => 'Amount too low',
    );
    my $content = $json->decode($ev->content);
    is $content->{status}, 'rejected', 'rejected status';
    is $content->{message}, 'Amount too low', 'message gives context for rejection';
};

subtest 'bid_confirmation with pending status and message' => sub {
    my $ev = Net::Nostr::Marketplace->bid_confirmation_event(
        pubkey           => $pubkey,
        bid_event_id     => 'ee' x 32,
        auction_event_id => 'dd' x 32,
        status           => 'pending',
        message          => 'Awaiting identity verification',
    );
    my $content = $json->decode($ev->content);
    is $content->{status}, 'pending', 'pending status';
    is $content->{message}, 'Awaiting identity verification', 'message gives context for pending';
};

subtest 'order_message with partial contact (nostr only)' => sub {
    my $msg = Net::Nostr::Marketplace->order_message(
        id          => 'order-partial',
        items       => [{ product_id => 'p1', quantity => 1 }],
        shipping_id => 'z1',
        contact     => { nostr => $pubkey },
    );
    my $data = $json->decode($msg);
    is $data->{contact}{nostr}, $pubkey, 'nostr contact present';
    ok !exists $data->{contact}{phone}, 'phone omitted';
    ok !exists $data->{contact}{email}, 'email omitted';
};

subtest 'auction_event with future start_date' => sub {
    my $future = time() + 86400 * 7;
    my $ev = Net::Nostr::Marketplace->auction_event(
        pubkey       => $pubkey,
        id           => 'future-auction',
        stall_id     => 'stall-1',
        name         => 'Scheduled Auction',
        starting_bid => 500,
        start_date   => $future,
        duration     => 3600,
    );
    my $content = $json->decode($ev->content);
    is $content->{start_date}, $future, 'future start_date accepted';
    ok $content->{start_date} > time(), 'start_date is in the future';
};

subtest 'validate kind 30019 requires d tag' => sub {
    my $ev = make_event(pubkey => $pubkey, kind => 30019, content => '{}', tags => []);
    eval { Net::Nostr::Marketplace->validate($ev) };
    like $@, qr/d tag/, 'croaks without d tag';

    my $ev2 = make_event(pubkey => $pubkey, kind => 30019, content => '{}', tags => [['d', 'market-1']]);
    ok(Net::Nostr::Marketplace->validate($ev2)), 'valid with d tag';
};

subtest 'validate kind 30020 requires d tag' => sub {
    my $ev = make_event(pubkey => $pubkey, kind => 30020, content => '{}', tags => []);
    eval { Net::Nostr::Marketplace->validate($ev) };
    like $@, qr/d tag/, 'croaks without d tag';
};

subtest 'hex64 validation rejects invalid event IDs in tags' => sub {
    my $valid_id = 'ab' x 32;

    # bid_event: auction_event_id too short
    eval { Net::Nostr::Marketplace->bid_event(
        pubkey => $pubkey, amount => 100, auction_event_id => 'abc123',
    ) };
    like $@, qr/auction_event_id must be 64-char lowercase hex/, 'bid_event rejects short id';

    # bid_event: uppercase hex
    eval { Net::Nostr::Marketplace->bid_event(
        pubkey => $pubkey, amount => 100, auction_event_id => 'AB' x 32,
    ) };
    like $@, qr/auction_event_id must be 64-char lowercase hex/, 'bid_event rejects uppercase';

    # bid_confirmation_event: invalid bid_event_id
    eval { Net::Nostr::Marketplace->bid_confirmation_event(
        pubkey => $pubkey, bid_event_id => 'not-hex',
        auction_event_id => $valid_id, status => 'accepted',
    ) };
    like $@, qr/bid_event_id must be 64-char lowercase hex/, 'bid_confirmation rejects bad bid_event_id';

    # bid_confirmation_event: invalid auction_event_id
    eval { Net::Nostr::Marketplace->bid_confirmation_event(
        pubkey => $pubkey, bid_event_id => $valid_id,
        auction_event_id => 'xyz', status => 'accepted',
    ) };
    like $@, qr/auction_event_id must be 64-char lowercase hex/, 'bid_confirmation rejects bad auction_event_id';

    # valid IDs pass through fine
    my $ev = Net::Nostr::Marketplace->bid_event(
        pubkey => $pubkey, amount => 100, auction_event_id => $valid_id,
    );
    ok $ev, 'bid_event accepts valid hex64 id';
};

done_testing;
