#!perl

use strict;
use warnings;

use Test::More;
use Net::Jabber::Bot;

use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;

# No-op sleep to avoid real delays
BEGIN { *CORE::GLOBAL::sleep = sub { }; }

my $server            = 'jabber.example.com';
my $conference_server = "conference.$server";
my $bot_alias         = 'testbot';
my $bot_username      = 'botuser';

sub background_noop { }

my %forums_and_responses = (
    room1 => ["bot:"],
);

my $bot = Net::Jabber::Bot->new(
    server               => $server,
    conference_server     => $conference_server,
    port                 => 5222,
    username             => $bot_username,
    password             => 'secret',
    alias                => $bot_alias,
    background_function  => \&background_noop,
    loop_sleep_time      => 5,
    process_timeout      => 5,
    forums_and_responses => \%forums_and_responses,
    safety_mode          => 0,
    max_messages_per_hour => 10000,
    forum_join_grace     => 0,
    auto_subscribe       => 1,
);

isa_ok( $bot, 'Net::Jabber::Bot' );

# Grab the mock client and callbacks
my $client = $bot->jabber_client;
my $session_id = $client->{SESSION}->{id};
my $presence_cb = $client->{presence_callback};
my $iq_cb       = $client->{iq_callback};

ok( defined $presence_cb, "presence callback is registered" );
ok( defined $iq_cb,       "iq callback is registered" );

# ─── Presence: subscribe with auto_subscribe enabled ──────────

subtest 'auto_subscribe accepts subscription requests' => sub {
    @{$client->{subscription_log}} = ();    # reset

    my $presence = Net::Jabber::Presence->new();
    $presence->SetFrom('friend@example.com');
    $presence->SetType('subscribe');

    $presence_cb->($session_id, $presence);

    my @subs = @{$client->{subscription_log}};
    is( scalar @subs, 2, "two subscription calls made" );
    is( $subs[0]->{type}, 'subscribe',  "first call: subscribe (request mutual)" );
    is( $subs[0]->{to},   'friend@example.com', "subscribe to correct JID" );
    is( $subs[1]->{type}, 'subscribed', "second call: subscribed (approve)" );
    is( $subs[1]->{to},   'friend@example.com', "subscribed to correct JID" );
};

# ─── Presence: subscribe with auto_subscribe disabled ─────────

subtest 'auto_subscribe disabled ignores subscription requests' => sub {
    @{$client->{subscription_log}} = ();    # reset
    $bot->auto_subscribe(0);

    my $presence = Net::Jabber::Presence->new();
    $presence->SetFrom('stranger@example.com');
    $presence->SetType('subscribe');

    $presence_cb->($session_id, $presence);

    my @subs = @{$client->{subscription_log}};
    is( scalar @subs, 0, "no subscription calls when auto_subscribe is off" );

    $bot->auto_subscribe(1);    # restore
};

# ─── Presence: unsubscribe ────────────────────────────────────

subtest 'unsubscribe sends unsubscribed response' => sub {
    @{$client->{subscription_log}} = ();    # reset

    my $presence = Net::Jabber::Presence->new();
    $presence->SetFrom('leaving@example.com');
    $presence->SetType('unsubscribe');

    $presence_cb->($session_id, $presence);

    my @subs = @{$client->{subscription_log}};
    is( scalar @subs, 1, "one subscription call for unsubscribe" );
    is( $subs[0]->{type}, 'unsubscribed', "sends unsubscribed response" );
    is( $subs[0]->{to},   'leaving@example.com', "unsubscribed correct JID" );
};

# ─── Presence: normal available (no type) ─────────────────────

subtest 'normal presence is stored in PresenceDB' => sub {
    my $presence = Net::Jabber::Presence->new();
    $presence->SetFrom('buddy@example.com/home');
    # No SetType — this is a normal "available" presence

    $presence_cb->($session_id, $presence);

    # Verify it was stored via PresenceDBParse
    my $stored = $client->{presence_db}{'buddy@example.com/home'};
    ok( defined $stored, "presence stored in DB" );
    is( $stored->GetFrom(), 'buddy@example.com/home', "stored presence has correct from" );
};

# ─── Presence: priority is set to 0 when missing ──────────────

subtest 'missing priority defaults to 0' => sub {
    my $presence = Net::Jabber::Presence->new();
    $presence->SetFrom('noprio@example.com/laptop');
    # No SetPriority — should be set to 0 by the handler

    $presence_cb->($session_id, $presence);

    my $stored = $client->{presence_db}{'noprio@example.com/laptop'};
    ok( defined $stored, "presence stored" );
    is( $stored->GetPriority(), 0, "priority set to 0 when missing" );
};

# ─── Presence: explicit priority is preserved ─────────────────

subtest 'explicit priority is preserved' => sub {
    my $presence = Net::Jabber::Presence->new();
    $presence->SetFrom('prio@example.com/work');
    $presence->SetPriority(10);

    $presence_cb->($session_id, $presence);

    my $stored = $client->{presence_db}{'prio@example.com/work'};
    ok( defined $stored, "presence stored" );
    is( $stored->GetPriority(), 10, "explicit priority 10 preserved" );
};

# ─── Presence: with show and status ───────────────────────────

subtest 'presence with show/status values' => sub {
    my $presence = Net::Jabber::Presence->new();
    $presence->SetFrom('away@example.com/mobile');
    $presence->SetShow('away');
    $presence->SetStatus('On vacation');
    $presence->SetPriority(5);

    $presence_cb->($session_id, $presence);

    my $stored = $client->{presence_db}{'away@example.com/mobile'};
    ok( defined $stored, "presence stored" );
    is( $stored->GetShow(),   'away',        "show value preserved" );
    is( $stored->GetStatus(), 'On vacation', "status string preserved" );
};

# ─── Presence: subscribe does NOT store in PresenceDB ─────────

subtest 'subscribe does not store in PresenceDB' => sub {
    delete $client->{presence_db}{'sub_only@example.com'};

    my $presence = Net::Jabber::Presence->new();
    $presence->SetFrom('sub_only@example.com');
    $presence->SetType('subscribe');

    $presence_cb->($session_id, $presence);

    ok( !exists $client->{presence_db}{'sub_only@example.com'},
        "subscribe presence is not stored in DB" );
};

# ─── Presence: unsubscribe does NOT store in PresenceDB ───────

subtest 'unsubscribe does not store in PresenceDB' => sub {
    delete $client->{presence_db}{'unsub_only@example.com'};

    my $presence = Net::Jabber::Presence->new();
    $presence->SetFrom('unsub_only@example.com');
    $presence->SetType('unsubscribe');

    $presence_cb->($session_id, $presence);

    ok( !exists $client->{presence_db}{'unsub_only@example.com'},
        "unsubscribe presence is not stored in DB" );
};

# ─── Presence: undefined from handled gracefully ──────────────

subtest 'presence with undefined from does not crash' => sub {
    my $presence = Net::Jabber::Presence->new();
    # No SetFrom — from will be undef/empty
    $presence->SetPriority(1);

    # Should not die
    eval { $presence_cb->($session_id, $presence) };
    ok( !$@, "presence with no from does not crash" );
};

# ═══════════════════════════════════════════════════════════════
# IQ Handler Tests
# ═══════════════════════════════════════════════════════════════

# ─── IQ: version request ──────────────────────────────────────

subtest 'IQ version request sends version response' => sub {
    delete $client->{last_version_send};

    my $iq = Net::Jabber::IQ->new();
    $iq->SetFrom('requester@example.com/client');
    $iq->SetType('get');

    # Add a query with jabber:iq:version namespace
    my $query = $iq->NewQuery('jabber:iq:version');

    $iq_cb->($session_id, $iq);

    ok( defined $client->{last_version_send}, "VersionSend was called" );
    is( $client->{last_version_send}->{to},   'requester@example.com/client', "version sent to correct JID" );
    is( $client->{last_version_send}->{name}, 'Net::Jabber::Bot', "version name is package name" );
    is( $client->{last_version_send}->{ver},  $Net::Jabber::Bot::VERSION, "version matches module VERSION" );
    like( $client->{last_version_send}->{os}, qr/^Perl v/, "OS string starts with 'Perl v'" );
};

# ─── IQ: non-version query is ignored ─────────────────────────

subtest 'IQ with non-version xmlns does not send version' => sub {
    delete $client->{last_version_send};

    my $iq = Net::Jabber::IQ->new();
    $iq->SetFrom('other@example.com');
    $iq->SetType('get');

    # Use a different namespace
    my $query = $iq->NewQuery('jabber:iq:roster');

    $iq_cb->($session_id, $iq);

    ok( !defined $client->{last_version_send}, "VersionSend NOT called for non-version query" );
};

# ─── IQ: no query element ─────────────────────────────────────

subtest 'IQ without query element does not crash' => sub {
    delete $client->{last_version_send};

    my $iq = Net::Jabber::IQ->new();
    $iq->SetFrom('bare@example.com');
    $iq->SetType('result');
    # No query added

    eval { $iq_cb->($session_id, $iq) };
    ok( !$@, "IQ with no query does not crash" );
    ok( !defined $client->{last_version_send}, "VersionSend NOT called when no query" );
};

# ─── IQ: version response contains valid Perl version ─────────

subtest 'IQ version response has well-formatted Perl version' => sub {
    delete $client->{last_version_send};

    my $iq = Net::Jabber::IQ->new();
    $iq->SetFrom('checker@example.com');
    $iq->SetType('get');
    $iq->NewQuery('jabber:iq:version');

    $iq_cb->($session_id, $iq);

    my $os = $client->{last_version_send}->{os};
    # Perl version should be formatted like "Perl v5.X.Y" (not raw like "Perl v5.042000")
    like( $os, qr/^Perl v\d+\.\d+/, "OS contains formatted Perl version" );
    unlike( $os, qr/\d{6}/, "Perl version does not contain raw 6-digit minor version" );
};

# ═══════════════════════════════════════════════════════════════
# Integration: Presence feeds into GetStatus
# ═══════════════════════════════════════════════════════════════

subtest 'presence updates are visible via GetStatus' => sub {
    # Send an "available" presence
    my $presence = Net::Jabber::Presence->new();
    $presence->SetFrom('statustest@example.com/desktop');
    $presence->SetPriority(1);

    $presence_cb->($session_id, $presence);

    my $status = $bot->GetStatus('statustest@example.com/desktop');
    is( $status, 'available', "GetStatus returns available for presence with no show" );

    # Now send an "away" presence
    my $away = Net::Jabber::Presence->new();
    $away->SetFrom('statustest@example.com/desktop');
    $away->SetShow('away');
    $away->SetPriority(1);

    $presence_cb->($session_id, $away);

    $status = $bot->GetStatus('statustest@example.com/desktop');
    is( $status, 'away', "GetStatus reflects updated show value" );
};

# ═══════════════════════════════════════════════════════════════
# Integration: auto_subscribe toggle at runtime
# ═══════════════════════════════════════════════════════════════

subtest 'auto_subscribe can be toggled at runtime' => sub {
    # Start with auto_subscribe on
    $bot->auto_subscribe(1);
    @{$client->{subscription_log}} = ();

    my $p1 = Net::Jabber::Presence->new();
    $p1->SetFrom('toggle1@example.com');
    $p1->SetType('subscribe');
    $presence_cb->($session_id, $p1);

    is( scalar @{$client->{subscription_log}}, 2, "auto_subscribe on: 2 calls" );

    # Turn it off
    $bot->auto_subscribe(0);
    @{$client->{subscription_log}} = ();

    my $p2 = Net::Jabber::Presence->new();
    $p2->SetFrom('toggle2@example.com');
    $p2->SetType('subscribe');
    $presence_cb->($session_id, $p2);

    is( scalar @{$client->{subscription_log}}, 0, "auto_subscribe off: 0 calls" );

    # Turn it back on
    $bot->auto_subscribe(1);
    @{$client->{subscription_log}} = ();

    my $p3 = Net::Jabber::Presence->new();
    $p3->SetFrom('toggle3@example.com');
    $p3->SetType('subscribe');
    $presence_cb->($session_id, $p3);

    is( scalar @{$client->{subscription_log}}, 2, "auto_subscribe back on: 2 calls" );
};

done_testing();
