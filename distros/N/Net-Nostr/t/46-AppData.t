use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Event;
use Net::Nostr::AppData;

my $PK = 'a' x 64;

###############################################################################
# POD example: store app-specific data
###############################################################################

subtest 'POD: store app-specific data' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey  => $PK,
        d_tag   => 'com.example.myapp/settings',
        content => '{"theme":"dark","fontSize":14}',
    );
    is($event->kind, 30078, 'kind is 30078');
    is($event->d_tag, 'com.example.myapp/settings', 'd tag');
    is($event->content, '{"theme":"dark","fontSize":14}', 'content');
};

###############################################################################
# POD example: parse app data from event
###############################################################################

subtest 'POD: parse app data' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey  => $PK,
        d_tag   => 'com.example.myapp/settings',
        content => '{"theme":"dark","fontSize":14}',
    );
    my $ad = Net::Nostr::AppData->from_event($event);
    is($ad->d_tag, 'com.example.myapp/settings');
    is($ad->content, '{"theme":"dark","fontSize":14}');
};

###############################################################################
# POD example: validate
###############################################################################

subtest 'POD: validate' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey => $PK,
        d_tag  => 'myapp',
    );
    ok(Net::Nostr::AppData->validate($event), 'validate returns true');

    my $bad = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30078, content => '', tags => [],
    );
    eval { Net::Nostr::AppData->validate($bad) };
    ok($@, 'validate croaks on invalid event');
};

###############################################################################
# POD example: to_event with extra_tags
###############################################################################

subtest 'POD: to_event with extra_tags' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey     => $PK,
        d_tag      => 'com.example.myapp/settings',
        content    => '{"theme":"dark","fontSize":14}',
        extra_tags => [['version', '2']],
    );
    my @tags = @{$event->tags};
    is($tags[0][0], 'd');
    is($tags[1], ['version', '2']);
};

###############################################################################
# Constructor
###############################################################################

subtest 'constructor: no args' => sub {
    my $ad = Net::Nostr::AppData->new;
    isa_ok($ad, 'Net::Nostr::AppData');
};

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::AppData->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

###############################################################################
# exports
###############################################################################

subtest 'public methods available' => sub {
    can_ok('Net::Nostr::AppData',
        qw(new to_event from_event validate d_tag content extra_tags));
};

done_testing;
