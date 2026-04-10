package Net::Nostr::Marketplace;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Net::Nostr::Event;

use Class::Tiny qw(
    stall_id
    product_id
    name
    description
    currency
    price
    quantity
    images
    specs
    shipping
    categories
    about
    ui
    merchants
    starting_bid
    start_date
    duration
    amount
    auction_event_id
    bid_event_id
    status
    message
    duration_extended
    checkout_type
    order_id
    items
    shipping_id
    contact
    payment_options
    paid
    shipped
    address
);

my $json = JSON->new->utf8->canonical;
my $HEX64 = qr/\A[0-9a-f]{64}\z/;

sub new {
    my $class = shift;
    my %args = @_;
    $args{categories} //= [];
    $args{images}     //= [];
    $args{shipping}   //= [];
    $args{specs}      //= [];
    $args{merchants}  //= [];
    $args{items}      //= [];
    $args{payment_options} //= [];
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

# === Event creation ===

sub stall_event {
    my ($class, %args) = @_;

    my $pubkey   = $args{pubkey}   // croak "stall_event requires 'pubkey'";
    my $id       = $args{id}       // croak "stall_event requires 'id'";
    my $name     = $args{name}     // croak "stall_event requires 'name'";
    my $currency = $args{currency} // croak "stall_event requires 'currency'";
    my $shipping = $args{shipping} // croak "stall_event requires 'shipping'";

    my %content = (
        id       => $id,
        name     => $name,
        currency => $currency,
        shipping => _build_stall_shipping($shipping),
    );
    $content{description} = $args{description} if defined $args{description};

    return Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 30017,
        content => $json->encode(\%content),
        tags    => [['d', $id]],
    );
}

sub _build_stall_shipping {
    my ($zones) = @_;
    my @out;
    for my $z (@$zones) {
        my %zone = (
            id      => $z->{id},
            cost    => $z->{cost},
            regions => $z->{regions},
        );
        $zone{name} = $z->{name} if defined $z->{name};
        push @out, \%zone;
    }
    return \@out;
}

sub product_event {
    my ($class, %args) = @_;

    my $pubkey   = $args{pubkey}   // croak "product_event requires 'pubkey'";
    my $id       = $args{id}       // croak "product_event requires 'id'";
    my $stall_id = $args{stall_id} // croak "product_event requires 'stall_id'";
    my $name     = $args{name}     // croak "product_event requires 'name'";
    my $currency = $args{currency} // croak "product_event requires 'currency'";
    croak "product_event requires 'price'" unless exists $args{price};

    my %content = (
        id       => $id,
        stall_id => $stall_id,
        name     => $name,
        currency => $currency,
        price    => $args{price},
    );

    if (exists $args{quantity}) {
        $content{quantity} = $args{quantity};
    }
    $content{description} = $args{description} if defined $args{description};
    $content{images}      = $args{images}      if defined $args{images};
    $content{specs}       = $args{specs}        if defined $args{specs};
    $content{shipping}    = $args{shipping}     if defined $args{shipping};

    my @tags = (['d', $id]);
    if (defined $args{categories}) {
        for my $cat (@{$args{categories}}) {
            push @tags, ['t', $cat];
        }
    }

    return Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 30018,
        content => $json->encode(\%content),
        tags    => \@tags,
    );
}

sub marketplace_event {
    my ($class, %args) = @_;

    my $pubkey = $args{pubkey} // croak "marketplace_event requires 'pubkey'";
    my $id     = $args{id}     // croak "marketplace_event requires 'id'";

    my %content;
    $content{name}      = $args{name}      if defined $args{name};
    $content{about}     = $args{about}     if defined $args{about};
    $content{ui}        = $args{ui}        if defined $args{ui};
    $content{merchants} = $args{merchants} if defined $args{merchants};

    return Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 30019,
        content => $json->encode(\%content),
        tags    => [['d', $id]],
    );
}

sub auction_event {
    my ($class, %args) = @_;

    my $pubkey       = $args{pubkey}       // croak "auction_event requires 'pubkey'";
    my $id           = $args{id}           // croak "auction_event requires 'id'";
    my $stall_id     = $args{stall_id}     // croak "auction_event requires 'stall_id'";
    my $name         = $args{name}         // croak "auction_event requires 'name'";
    croak "auction_event requires 'starting_bid'" unless exists $args{starting_bid};
    croak "auction_event requires 'duration'"     unless exists $args{duration};

    my %content = (
        id           => $id,
        stall_id     => $stall_id,
        name         => $name,
        starting_bid => $args{starting_bid},
        duration     => $args{duration},
    );

    $content{description} = $args{description} if defined $args{description};
    $content{images}      = $args{images}      if defined $args{images};
    $content{start_date}  = $args{start_date}  if defined $args{start_date};
    $content{specs}       = $args{specs}        if defined $args{specs};
    $content{shipping}    = $args{shipping}     if defined $args{shipping};

    return Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 30020,
        content => $json->encode(\%content),
        tags    => [['d', $id]],
    );
}

sub bid_event {
    my ($class, %args) = @_;

    my $pubkey           = $args{pubkey}           // croak "bid_event requires 'pubkey'";
    croak "bid_event requires 'amount'"            unless exists $args{amount};
    my $auction_event_id = $args{auction_event_id} // croak "bid_event requires 'auction_event_id'";
    croak "auction_event_id must be 64-char lowercase hex" unless $auction_event_id =~ $HEX64;

    return Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 1021,
        content => '' . $args{amount},
        tags    => [['e', $auction_event_id]],
    );
}

sub bid_confirmation_event {
    my ($class, %args) = @_;

    my $pubkey           = $args{pubkey}           // croak "bid_confirmation_event requires 'pubkey'";
    my $bid_event_id     = $args{bid_event_id}     // croak "bid_confirmation_event requires 'bid_event_id'";
    my $auction_event_id = $args{auction_event_id} // croak "bid_confirmation_event requires 'auction_event_id'";
    croak "bid_event_id must be 64-char lowercase hex" unless $bid_event_id =~ $HEX64;
    croak "auction_event_id must be 64-char lowercase hex" unless $auction_event_id =~ $HEX64;
    my $status           = $args{status}           // croak "bid_confirmation_event requires 'status'";

    my %content = (status => $status);
    $content{message}           = $args{message}           if defined $args{message};
    $content{duration_extended} = $args{duration_extended}  if defined $args{duration_extended};

    return Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 1022,
        content => $json->encode(\%content),
        tags    => [['e', $bid_event_id], ['e', $auction_event_id]],
    );
}

# === Checkout message builders ===

sub order_message {
    my ($class, %args) = @_;

    my $id          = $args{id}          // croak "order_message requires 'id'";
    my $items       = $args{items}       // croak "order_message requires 'items'";
    my $shipping_id = $args{shipping_id} // croak "order_message requires 'shipping_id'";

    my %data = (
        type        => 0,
        id          => $id,
        items       => $items,
        shipping_id => $shipping_id,
    );
    $data{name}    = $args{name}    if defined $args{name};
    $data{address} = $args{address} if defined $args{address};
    $data{message} = $args{message} if defined $args{message};
    $data{contact} = $args{contact} if defined $args{contact};

    return $json->encode(\%data);
}

sub payment_request_message {
    my ($class, %args) = @_;

    my $id              = $args{id}              // croak "payment_request_message requires 'id'";
    my $payment_options = $args{payment_options} // croak "payment_request_message requires 'payment_options'";

    my %data = (
        type            => 1,
        id              => $id,
        payment_options => $payment_options,
    );
    $data{message} = $args{message} if defined $args{message};

    return $json->encode(\%data);
}

sub order_status_message {
    my ($class, %args) = @_;

    my $id      = $args{id}      // croak "order_status_message requires 'id'";
    my $message = $args{message} // croak "order_status_message requires 'message'";
    croak "order_status_message requires 'paid'"    unless exists $args{paid};
    croak "order_status_message requires 'shipped'" unless exists $args{shipped};

    return $json->encode({
        type    => 2,
        id      => $id,
        message => $message,
        paid    => $args{paid},
        shipped => $args{shipped},
    });
}

# === Event parsing ===

sub from_event {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    if ($kind == 30017) {
        return $class->_parse_stall_event($event);
    } elsif ($kind == 30018) {
        return $class->_parse_product_event($event);
    } elsif ($kind == 30019) {
        return $class->_parse_marketplace_event($event);
    } elsif ($kind == 30020) {
        return $class->_parse_auction_event($event);
    } elsif ($kind == 1021) {
        return $class->_parse_bid_event($event);
    } elsif ($kind == 1022) {
        return $class->_parse_bid_confirmation_event($event);
    }
    return undef;
}

sub _parse_stall_event {
    my ($class, $event) = @_;
    my $data = $json->decode($event->content);

    return $class->new(
        stall_id    => $data->{id},
        name        => $data->{name},
        description => $data->{description},
        currency    => $data->{currency},
        shipping    => $data->{shipping} // [],
    );
}

sub _parse_product_event {
    my ($class, $event) = @_;
    my $data = $json->decode($event->content);

    my @categories;
    for my $tag (@{$event->tags}) {
        push @categories, $tag->[1] if $tag->[0] eq 't';
    }

    return $class->new(
        product_id  => $data->{id},
        stall_id    => $data->{stall_id},
        name        => $data->{name},
        description => $data->{description},
        currency    => $data->{currency},
        price       => $data->{price},
        quantity    => $data->{quantity},
        images      => $data->{images} // [],
        specs       => $data->{specs} // [],
        shipping    => $data->{shipping} // [],
        categories  => \@categories,
    );
}

sub _parse_marketplace_event {
    my ($class, $event) = @_;
    my $data = $json->decode($event->content);

    return $class->new(
        name      => $data->{name},
        about     => $data->{about},
        ui        => $data->{ui},
        merchants => $data->{merchants} // [],
    );
}

sub _parse_auction_event {
    my ($class, $event) = @_;
    my $data = $json->decode($event->content);

    return $class->new(
        product_id   => $data->{id},
        stall_id     => $data->{stall_id},
        name         => $data->{name},
        description  => $data->{description},
        starting_bid => $data->{starting_bid},
        start_date   => $data->{start_date},
        duration     => $data->{duration},
        images       => $data->{images} // [],
        specs        => $data->{specs} // [],
        shipping     => $data->{shipping} // [],
    );
}

sub _parse_bid_event {
    my ($class, $event) = @_;

    my $auction_event_id;
    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'e') {
            $auction_event_id = $tag->[1];
            last;
        }
    }

    return $class->new(
        amount           => 0 + $event->content,
        auction_event_id => $auction_event_id,
    );
}

sub _parse_bid_confirmation_event {
    my ($class, $event) = @_;
    my $data = $json->decode($event->content);

    my ($bid_event_id, $auction_event_id);
    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'e') {
            if (!defined $bid_event_id) {
                $bid_event_id = $tag->[1];
            } else {
                $auction_event_id = $tag->[1];
            }
        }
    }

    return $class->new(
        status           => $data->{status},
        message          => $data->{message},
        duration_extended => $data->{duration_extended},
        bid_event_id     => $bid_event_id,
        auction_event_id => $auction_event_id,
    );
}

# === Checkout message parsing ===

sub parse_checkout_message {
    my ($class, $msg) = @_;
    my $data = $json->decode($msg);
    my $type = $data->{type};

    if ($type == 0) {
        return $class->new(
            checkout_type => 0,
            order_id      => $data->{id},
            items         => $data->{items} // [],
            shipping_id   => $data->{shipping_id},
            name          => $data->{name},
            address       => $data->{address},
            message       => $data->{message},
            contact       => $data->{contact},
        );
    } elsif ($type == 1) {
        return $class->new(
            checkout_type   => 1,
            order_id        => $data->{id},
            payment_options => $data->{payment_options} // [],
            message         => $data->{message},
        );
    } elsif ($type == 2) {
        return $class->new(
            checkout_type => 2,
            order_id      => $data->{id},
            message       => $data->{message},
            paid          => $data->{paid},
            shipped       => $data->{shipped},
        );
    }

    croak "unrecognized checkout message type: $type";
}

# === Validation ===

sub validate {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    if ($kind == 30017 || $kind == 30018 || $kind == 30019 || $kind == 30020) {
        my $has_d;
        for my $tag (@{$event->tags}) {
            $has_d = 1 if $tag->[0] eq 'd';
        }
        croak "kind $kind requires a d tag" unless $has_d;
        return 1;
    } elsif ($kind == 1021) {
        my $has_e;
        for my $tag (@{$event->tags}) {
            $has_e = 1 if $tag->[0] eq 'e';
        }
        croak "kind 1021 requires an e tag" unless $has_e;
        return 1;
    } elsif ($kind == 1022) {
        my $e_count = 0;
        for my $tag (@{$event->tags}) {
            $e_count++ if $tag->[0] eq 'e';
        }
        croak "kind 1022 requires two e tags" unless $e_count >= 2;
        return 1;
    }

    croak "marketplace event must be kind 30017, 30018, 30019, 30020, 1021, or 1022";
}

1;

__END__

=head1 NAME

Net::Nostr::Marketplace - NIP-15 Nostr Marketplace

=head1 SYNOPSIS

    use Net::Nostr::Marketplace;

    # Create a stall (kind 30017)
    my $stall = Net::Nostr::Marketplace->stall_event(
        pubkey   => $hex_pubkey,
        id       => 'stall-1',
        name     => 'My Stall',
        currency => 'USD',
        shipping => [
            { id => 'zone-1', name => 'US', cost => 5.0, regions => ['US', 'CA'] },
        ],
    );

    # Create a product (kind 30018)
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

    # Create a marketplace (kind 30019)
    my $market = Net::Nostr::Marketplace->marketplace_event(
        pubkey    => $hex_pubkey,
        id        => 'market-1',
        name      => 'My Market',
        merchants => [$merchant_pubkey],
    );

    # Create an auction (kind 30020)
    my $auction = Net::Nostr::Marketplace->auction_event(
        pubkey       => $hex_pubkey,
        id           => 'auction-1',
        stall_id     => 'stall-1',
        name         => 'Rare Item',
        starting_bid => 1000,
        duration     => 86400,
    );

    # Place a bid (kind 1021)
    my $bid = Net::Nostr::Marketplace->bid_event(
        pubkey           => $hex_pubkey,
        amount           => 1500,
        auction_event_id => $auction_event_id,
    );

    # Confirm a bid (kind 1022)
    my $confirm = Net::Nostr::Marketplace->bid_confirmation_event(
        pubkey           => $hex_pubkey,
        bid_event_id     => $bid_event_id,
        auction_event_id => $auction_event_id,
        status           => 'accepted',
    );

    # Checkout messages (JSON for NIP-04 direct messages)
    my $order = Net::Nostr::Marketplace->order_message(
        id          => 'order-1',
        items       => [{ product_id => 'prod-1', quantity => 2 }],
        shipping_id => 'zone-1',
    );

    my $payment = Net::Nostr::Marketplace->payment_request_message(
        id              => 'order-1',
        payment_options => [{ type => 'ln', link => 'lnbc...' }],
    );

    my $status = Net::Nostr::Marketplace->order_status_message(
        id      => 'order-1',
        message => 'Shipped!',
        paid    => JSON::true,
        shipped => JSON::true,
    );

    # Parse events
    my $parsed = Net::Nostr::Marketplace->from_event($event);

    # Parse checkout messages
    my $checkout = Net::Nostr::Marketplace->parse_checkout_message($json_string);

=head1 DESCRIPTION

Implements NIP-15 Nostr Marketplace. Merchants publish stalls, products,
and auctions as Nostr events. Customers interact through bids and checkout
messages sent via NIP-04 direct messages.

Six event kinds are involved:

=over

=item B<kind 30017> - Stall (addressable). Contains stall name, currency,
and shipping zones. The C<d> tag MUST match the stall C<id>.

=item B<kind 30018> - Product (addressable). Contains product details
including price, quantity, and optional specs. The C<d> tag MUST match the
product C<id>. Categories are stored as C<t> tags.

=item B<kind 30019> - Marketplace UI/UX (addressable). Customizes the
marketplace experience with name, description, theme, and merchant list.

=item B<kind 30020> - Auction (addressable). Similar to products but with
C<starting_bid> and C<duration> instead of fixed price. The C<d> tag MUST
match the auction C<id>.

=item B<kind 1021> - Bid. Content is the bid amount. References the auction
event via an C<e> tag. Bids reference the event ID (not UUID) so editing
an auction after a bid invalidates the bid.

=item B<kind 1022> - Bid confirmation. Merchant confirms/rejects bids.
Status can be C<accepted>, C<rejected>, C<pending>, or C<winner>.
References both the bid and auction events via C<e> tags. May extend
the auction duration.

=back

Checkout is handled via three message types exchanged as NIP-04 encrypted
direct messages:

=over

=item B<type 0> - Customer order with items, shipping zone, and optional
contact info.

=item B<type 1> - Merchant payment request with payment options (url, btc,
ln, lnurl).

=item B<type 2> - Merchant order status update with paid/shipped booleans.

=back

=head1 CONSTRUCTOR

=head2 new

    my $info = Net::Nostr::Marketplace->new(%fields);

Creates a new C<Net::Nostr::Marketplace> object.  Typically returned by
L</from_event>; calling C<new> directly is useful for testing or
manual construction.

    my $info = Net::Nostr::Marketplace->new(
        name  => 'Widget',
        price => 10.50,
    );

Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 stall_event

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

Creates a kind 30017 stall L<Net::Nostr::Event>. C<pubkey>, C<id>, C<name>,
C<currency>, and C<shipping> are required. C<description> is optional.
Each shipping zone requires C<id>, C<cost>, and C<regions>; C<name> is
optional.

=head2 product_event

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

Creates a kind 30018 product L<Net::Nostr::Event>. C<pubkey>, C<id>,
C<stall_id>, C<name>, C<currency>, and C<price> are required. C<quantity>
can be C<undef> for unlimited items. C<categories> become C<t> tags.

=head2 marketplace_event

    my $event = Net::Nostr::Marketplace->marketplace_event(
        pubkey    => $hex_pubkey,
        id        => 'market-1',
        name      => 'My Market',
        about     => 'A cool marketplace',
        ui        => { theme => 'dark', darkMode => JSON::true },
        merchants => [$pubkey1, $pubkey2],
    );

Creates a kind 30019 marketplace UI/UX L<Net::Nostr::Event>. C<pubkey> and
C<id> are required. All other fields are optional.

=head2 auction_event

    my $event = Net::Nostr::Marketplace->auction_event(
        pubkey       => $hex_pubkey,
        id           => 'auction-1',
        stall_id     => 'stall-1',
        name         => 'Rare Item',
        starting_bid => 1000,
        start_date   => 1700000000,
        duration     => 86400,
    );

Creates a kind 30020 auction L<Net::Nostr::Event>. C<pubkey>, C<id>,
C<stall_id>, C<name>, C<starting_bid>, and C<duration> are required.
C<start_date> is optional; omit if the start date is unknown or hidden.

=head2 bid_event

    my $event = Net::Nostr::Marketplace->bid_event(
        pubkey           => $hex_pubkey,
        amount           => 1500,
        auction_event_id => $event_id,
    );

Creates a kind 1021 bid L<Net::Nostr::Event>. Content is the amount as a
string. An C<e> tag references the auction event.

=head2 bid_confirmation_event

    my $event = Net::Nostr::Marketplace->bid_confirmation_event(
        pubkey             => $hex_pubkey,
        bid_event_id       => $bid_id,
        auction_event_id   => $auction_id,
        status             => 'accepted',
        message            => 'Welcome!',
        duration_extended  => 300,
    );

Creates a kind 1022 bid confirmation L<Net::Nostr::Event>. C<pubkey>,
C<bid_event_id>, C<auction_event_id>, and C<status> are required.
C<message> and C<duration_extended> are optional. Two C<e> tags reference
the bid and auction events.

=head2 order_message

    my $json = Net::Nostr::Marketplace->order_message(
        id          => 'order-1',
        items       => [{ product_id => 'prod-1', quantity => 2 }],
        shipping_id => 'zone-1',
        name        => 'Alice',
        address     => '123 Main St',
        message     => 'Gift wrap please',
        contact     => { nostr => $pubkey, phone => '+1234567890', email => 'a@b.com' },
    );

Builds a type 0 order JSON string for NIP-04 checkout. C<id>, C<items>,
and C<shipping_id> are required. All other fields are optional.

=head2 payment_request_message

    my $json = Net::Nostr::Marketplace->payment_request_message(
        id              => 'order-1',
        payment_options => [
            { type => 'ln', link => 'lnbc...' },
            { type => 'btc', link => 'bc1q...' },
        ],
        message => 'Pay within 24 hours',
    );

Builds a type 1 payment request JSON string. C<id> and C<payment_options>
are required. Payment option types include C<url>, C<btc>, C<ln>, and
C<lnurl>. C<message> is optional.

=head2 order_status_message

    my $json = Net::Nostr::Marketplace->order_status_message(
        id      => 'order-1',
        message => 'Shipped!',
        paid    => JSON::true,
        shipped => JSON::true,
    );

Builds a type 2 order status JSON string. All fields are required.

=head2 from_event

    my $parsed = Net::Nostr::Marketplace->from_event($event);

Parses a marketplace event (kinds 30017, 30018, 30019, 30020, 1021, 1022)
into a C<Net::Nostr::Marketplace> object. Returns C<undef> for unrecognized
kinds.

=head2 parse_checkout_message

    my $msg = Net::Nostr::Marketplace->parse_checkout_message($json_string);
    say $msg->checkout_type;  # 0, 1, or 2
    say $msg->order_id;

Parses a checkout JSON string (type 0 order, type 1 payment request, or
type 2 order status) into a C<Net::Nostr::Marketplace> object.

=head2 validate

    Net::Nostr::Marketplace->validate($event);

Validates a marketplace event. Croaks on invalid structure. Addressable
events (30017, 30018, 30019, 30020) must have a C<d> tag. Kind 1021 must
have an C<e> tag. Kind 1022 must have two C<e> tags.

=head1 ACCESSORS

Available on objects returned by L</from_event> and L</parse_checkout_message>.
Which accessors contain data depends on which event kind or message type
was parsed.

=head2 stall_id

Stall identifier (from kind 30017 or 30018).

=head2 product_id

Product or auction identifier (from kind 30018 or 30020).

=head2 name

Name of the stall, product, auction, or marketplace.

=head2 description

Optional description.

=head2 currency

Currency code (e.g. C<USD>, C<sat>).

=head2 price

Product price (from kind 30018).

=head2 quantity

Available quantity; C<undef> for unlimited (from kind 30018).

=head2 images

Arrayref of image URLs.

=head2 specs

Arrayref of C<[$key, $value]> specification pairs.

=head2 shipping

Arrayref of shipping zone hashrefs.

=head2 categories

Arrayref of category strings from C<t> tags (kind 30018).

=head2 about

Marketplace description (kind 30019).

=head2 ui

UI configuration hashref (kind 30019).

=head2 merchants

Arrayref of merchant pubkeys (kind 30019).

=head2 starting_bid

Starting bid amount (kind 30020).

=head2 start_date

Auction start UNIX timestamp (kind 30020).

=head2 duration

Auction duration in seconds (kind 30020).

=head2 amount

Bid amount (kind 1021).

=head2 auction_event_id

Referenced auction event ID (kinds 1021, 1022).

=head2 bid_event_id

Referenced bid event ID (kind 1022).

=head2 status

Bid confirmation status: C<accepted>, C<rejected>, C<pending>, or C<winner>
(kind 1022).

=head2 message

Optional message (kinds 1022, checkout messages).

=head2 duration_extended

Number of seconds by which the auction is extended (kind 1022).

=head2 checkout_type

Checkout message type: 0 (order), 1 (payment request), or 2 (order status).

=head2 order_id

Order identifier (checkout messages).

=head2 items

Arrayref of item hashrefs with C<product_id> and C<quantity> (type 0).

=head2 shipping_id

Selected shipping zone ID (type 0).

=head2 address

Shipping address string (type 0).

=head2 contact

Contact hashref with optional C<nostr>, C<phone>, C<email> (type 0).

=head2 payment_options

Arrayref of payment option hashrefs with C<type> and C<link> (type 1).

=head2 paid

Boolean indicating payment received (type 2).

=head2 shipped

Boolean indicating item shipped (type 2).

=head1 SEE ALSO

L<NIP-15|https://github.com/nostr-protocol/nips/blob/master/15.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
