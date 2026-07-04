use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::MintDiscovery;

my $PK = 'a' x 64;

###############################################################################
# POD example: recommendation
###############################################################################

subtest 'POD: recommendation' => sub {
    my $mint_pk = 'b' x 64;
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'my-rec',
        mint_kind  => '38173',
        urls       => [['fed11abc..', 'fedimint']],
        mint_refs  => [["38173:${mint_pk}:fed-id", 'wss://relay1']],
        content    => 'I trust this mint with my life',
    );
    is($event->kind, 38000, 'kind');
};

###############################################################################
# POD example: cashu_mint
###############################################################################

subtest 'POD: cashu_mint' => sub {
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $PK,
        identifier => 'mint-pubkey',
        urls       => ['https://cashu.example.com'],
        nuts       => '1,2,3,4,5,6,7',
        network    => 'mainnet',
    );
    is($event->kind, 38172, 'kind');
};

###############################################################################
# POD example: fedimint
###############################################################################

subtest 'POD: fedimint' => sub {
    my $event = Net::Nostr::MintDiscovery->fedimint(
        pubkey     => $PK,
        identifier => 'federation-id',
        urls       => ['fed11abc..', 'fed11xyz..'],
        modules    => 'lightning,wallet,mint',
        network    => 'signet',
    );
    is($event->kind, 38173, 'kind');
};

###############################################################################
# POD example: from_event
###############################################################################

subtest 'POD: from_event' => sub {
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $PK,
        identifier => 'test',
    );
    my $parsed = Net::Nostr::MintDiscovery->from_event($event);
    is($parsed->identifier, 'test');
};

###############################################################################
# POD example: validate
###############################################################################

subtest 'POD: validate' => sub {
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $PK,
        identifier => 'test',
    );
    ok(Net::Nostr::MintDiscovery->validate($event), 'validate returns true');
};

###############################################################################
# POD example: new
###############################################################################

subtest 'POD: new' => sub {
    my $mint = Net::Nostr::MintDiscovery->new(
        identifier => 'mint-id',
    );
    is($mint->identifier, 'mint-id');
};

###############################################################################
# Constructor: unknown args rejected
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::MintDiscovery->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

###############################################################################
# Public methods available
###############################################################################

subtest 'public methods available' => sub {
    can_ok('Net::Nostr::MintDiscovery',
        qw(new recommendation cashu_mint fedimint from_event validate
           identifier mint_kind urls mint_refs nuts modules network
           description));
};

done_testing;
