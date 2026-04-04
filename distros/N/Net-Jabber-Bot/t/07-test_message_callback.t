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

# Capture callback parameters
my @callback_calls;

sub message_handler {
    push @callback_calls, {@_};
}

sub background_noop { }

my %forums_and_responses = (
    room1 => [ "bot:", "hey bot " ],
    room2 => [ "admin:" ],
    room3 => [ "" ],    # empty string = respond to all messages
);

my $bot = Net::Jabber::Bot->new(
    server                 => $server,
    conference_server      => $conference_server,
    port                   => 5222,
    username               => $bot_username,
    password               => 'secret',
    alias                  => $bot_alias,
    message_function       => \&message_handler,
    background_function    => \&background_noop,
    loop_sleep_time        => 5,
    process_timeout        => 5,
    forums_and_responses   => \%forums_and_responses,
    ignore_server_messages => 1,
    ignore_self_messages   => 0,    # allow self messages so echoed messages get through
    safety_mode            => 0,    # disable safety to avoid overriding ignore_self_messages
    max_messages_per_hour  => 10000,
    forum_join_grace       => 0,
);

isa_ok( $bot, 'Net::Jabber::Bot' );

# Helper: inject a message directly into the mock client's queue
sub inject_message {
    my (%args) = @_;
    my $msg = Net::Jabber::Message->new();
    $msg->SetFrom( $args{from} );
    $msg->SetTo( $args{to} // "$bot_username\@$server/$bot_alias" );
    $msg->SetType( $args{type} // 'chat' );
    $msg->SetBody( $args{body} // '' );
    $msg->SetSubject( $args{subject} ) if defined $args{subject};
    push @{ $bot->jabber_client->{message_queue} }, $msg;
}

# Helper: process and return captured callback calls, then reset
sub process_and_collect {
    @callback_calls = ();
    $bot->Process(1);
    return @callback_calls;
}

# =========================================================================
# Test 1: Personal (chat) message delivers correct parameters
# =========================================================================
{
    inject_message(
        from => "alice\@$server/desktop",
        type => 'chat',
        body => 'Hello bot!',
    );

    my @calls = process_and_collect();
    is( scalar @calls, 1, 'chat message: callback called once' );

    my $c = $calls[0];
    isa_ok( $c->{bot_object}, 'Net::Jabber::Bot', 'chat message: bot_object' );
    is( $c->{from_full}, "alice\@$server/desktop", 'chat message: from_full' );
    is( $c->{body},      'Hello bot!',             'chat message: body' );
    is( $c->{type},      'chat',                   'chat message: type' );
    is( $c->{reply_to},  "alice\@$server/desktop",
        'chat message: reply_to equals from_full (no resource stripping for chat)' );
    ok( !defined $c->{bot_address_from},
        'chat message: bot_address_from is undef for non-groupchat' );
    isa_ok( $c->{message}, 'Net::Jabber::Message', 'chat message: raw message object' );
}

# =========================================================================
# Test 2: Groupchat message with alias prefix strips it from body
# =========================================================================
{
    inject_message(
        from => "room1\@$conference_server/alice",
        type => 'groupchat',
        body => 'bot: what time is it?',
    );

    my @calls = process_and_collect();
    is( scalar @calls, 1, 'groupchat alias: callback called once' );

    my $c = $calls[0];
    is( $c->{type}, 'groupchat', 'groupchat alias: type is groupchat' );
    is( $c->{body}, 'what time is it?',
        'groupchat alias: body has alias prefix stripped' );
    is( $c->{bot_address_from}, 'bot:',
        'groupchat alias: bot_address_from is the matched alias' );
    is( $c->{reply_to}, "room1\@$conference_server",
        'groupchat alias: reply_to has resource stripped' );
    is( $c->{from_full}, "room1\@$conference_server/alice",
        'groupchat alias: from_full preserved with resource' );
}

# =========================================================================
# Test 3: Second alias also works
# =========================================================================
{
    inject_message(
        from => "room1\@$conference_server/bob",
        type => 'groupchat',
        body => 'hey bot do something',
    );

    my @calls = process_and_collect();
    is( scalar @calls, 1, 'second alias: callback called once' );

    my $c = $calls[0];
    is( $c->{body}, 'do something',
        'second alias: body has "hey bot " prefix stripped' );
    is( $c->{bot_address_from}, 'hey bot ',
        'second alias: bot_address_from is the matched alias' );
}

# =========================================================================
# Test 4: Empty-string alias in room3 catches all messages
# =========================================================================
{
    inject_message(
        from => "room3\@$conference_server/charlie",
        type => 'groupchat',
        body => 'random chatter',
    );

    my @calls = process_and_collect();
    is( scalar @calls, 1, 'empty alias: callback called for any message' );

    my $c = $calls[0];
    is( $c->{body}, 'random chatter',
        'empty alias: body is the full message text' );
    is( $c->{bot_address_from}, '',
        'empty alias: bot_address_from is empty string' );
}

# =========================================================================
# Test 5: Groupchat message NOT matching any alias is ignored
# =========================================================================
{
    inject_message(
        from => "room2\@$conference_server/dave",
        type => 'groupchat',
        body => 'just talking to myself',
    );

    my @calls = process_and_collect();
    is( scalar @calls, 0,
        'no alias match: callback not called for irrelevant groupchat' );
}

# =========================================================================
# Test 6: Groupchat message matching alias in room2
# =========================================================================
{
    inject_message(
        from => "room2\@$conference_server/dave",
        type => 'groupchat',
        body => 'admin: restart service',
    );

    my @calls = process_and_collect();
    is( scalar @calls, 1, 'room2 alias match: callback called' );

    my $c = $calls[0];
    is( $c->{body},             'restart service', 'room2: body stripped' );
    is( $c->{bot_address_from}, 'admin:',          'room2: correct alias' );
}

# =========================================================================
# Test 7: Server messages are ignored when ignore_server_messages is on
# =========================================================================
{
    # Message from bare server (no user@server/resource format)
    inject_message(
        from => $server,
        type => 'chat',
        body => 'Server announcement',
    );

    my @calls = process_and_collect();
    is( scalar @calls, 0,
        'server message: ignored when ignore_server_messages=1' );
}

# =========================================================================
# Test 8: Message with user@server but no resource is also filtered
# =========================================================================
{
    inject_message(
        from => "system\@$server",
        type => 'chat',
        body => 'System notice',
    );

    my @calls = process_and_collect();
    is( scalar @calls, 0,
        'no-resource message: ignored when ignore_server_messages=1' );
}

# =========================================================================
# Test 9: Self-message detection when ignore_self_messages is on
# =========================================================================
{
    $bot->ignore_self_messages(1);

    inject_message(
        from => "room1\@$conference_server/" . $bot->resource,
        type => 'groupchat',
        body => 'bot: I said this myself',
    );

    my @calls = process_and_collect();
    is( scalar @calls, 0,
        'self message: ignored when ignore_self_messages=1' );

    $bot->ignore_self_messages(0);    # restore
}

# =========================================================================
# Test 10: Multiple messages in one Process() call
# =========================================================================
{
    inject_message(
        from => "alice\@$server/laptop",
        type => 'chat',
        body => 'First message',
    );
    inject_message(
        from => "bob\@$server/phone",
        type => 'chat',
        body => 'Second message',
    );

    my @calls = process_and_collect();
    is( scalar @calls, 2, 'multiple messages: both delivered' );
    is( $calls[0]->{body}, 'First message',  'multiple: first body correct' );
    is( $calls[1]->{body}, 'Second message', 'multiple: second body correct' );
}

# =========================================================================
# Test 11: Groupchat message from unknown forum (no aliases defined)
# =========================================================================
{
    # Send from a forum not in forums_and_responses — get_responses returns empty list
    inject_message(
        from => "unknownroom\@$conference_server/eve",
        type => 'groupchat',
        body => 'bot: hello?',
    );

    my @calls = process_and_collect();
    # No aliases to respond to for this forum → message passed through without alias stripping
    is( scalar @calls, 1,
        'unknown forum: message still delivered (no aliases to check)' );
    is( $calls[0]->{body}, 'bot: hello?',
        'unknown forum: body is unmodified (no alias stripping)' );
    ok( !defined $calls[0]->{bot_address_from},
        'unknown forum: bot_address_from is undef' );
}

# =========================================================================
# Test 12: Alias matching is order-sensitive (first match wins)
# =========================================================================
{
    # room1 has ["bot:", ""] — "bot:" should match before the catch-all ""
    inject_message(
        from => "room1\@$conference_server/frank",
        type => 'groupchat',
        body => 'bot: help me',
    );

    my @calls = process_and_collect();
    is( scalar @calls, 1, 'alias order: callback called' );
    is( $calls[0]->{bot_address_from}, 'bot:',
        'alias order: first alias matched, not catch-all' );
    is( $calls[0]->{body}, 'help me',
        'alias order: body stripped of first-matched alias' );
}

# =========================================================================
# Test 13: Whitespace before alias is tolerated
# =========================================================================
{
    inject_message(
        from => "room1\@$conference_server/grace",
        type => 'groupchat',
        body => '  bot: spaced out',
    );

    my @calls = process_and_collect();
    is( scalar @calls, 1, 'leading whitespace: callback called' );
    is( $calls[0]->{body}, 'spaced out',
        'leading whitespace: alias matched despite leading spaces' );
    is( $calls[0]->{bot_address_from}, 'bot:',
        'leading whitespace: correct alias matched' );
}

# =========================================================================
# Test 14: Message with no handler defined logs warning but doesn't crash
# =========================================================================
{
    my $saved_handler = $bot->message_function;
    $bot->message_function(undef);

    inject_message(
        from => "alice\@$server/desktop",
        type => 'chat',
        body => 'No handler here',
    );

    # Should not die
    my @calls = process_and_collect();
    is( scalar @calls, 0, 'no handler: callback not called (no handler)' );

    $bot->message_function($saved_handler);    # restore
}

done_testing();
