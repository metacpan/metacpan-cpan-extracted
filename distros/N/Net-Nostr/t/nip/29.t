#!/usr/bin/perl

# NIP-29: Relay-based Groups
# https://github.com/nostr-protocol/nips/blob/master/29.md

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Group;
use Net::Nostr::List;

my $alice_pk = 'a' x 64;
my $bob_pk   = 'b' x 64;
my $carol_pk = 'c' x 64;
my $relay_pk = 'd' x 64;
my $event_id = '1' x 64;

###############################################################################
# Group identifier
###############################################################################

subtest 'parse_id splits host and group_id' => sub {
    my $parsed = Net::Nostr::Group->parse_id("groups.nostr.com'abcdef");
    is($parsed->{host}, 'groups.nostr.com', 'host');
    is($parsed->{group_id}, 'abcdef', 'group_id');
};

subtest 'parse_id with underscore group_id' => sub {
    my $parsed = Net::Nostr::Group->parse_id("relay.com'my-group_1");
    is($parsed->{host}, 'relay.com', 'host');
    is($parsed->{group_id}, 'my-group_1', 'group_id');
};

subtest 'parse_id with host only infers _ as group_id (MAY)' => sub {
    my $parsed = Net::Nostr::Group->parse_id("groups.nostr.com");
    is($parsed->{host}, 'groups.nostr.com', 'host');
    is($parsed->{group_id}, '_', 'inferred top-level group _');
};

subtest 'format_id produces host-tick-group string' => sub {
    my $id = Net::Nostr::Group->format_id(
        host     => 'groups.nostr.com',
        group_id => 'abcdef',
    );
    is($id, "groups.nostr.com'abcdef", 'formatted id');
};

subtest 'validate_group_id accepts a-z0-9-_' => sub {
    ok(Net::Nostr::Group->validate_group_id('abc-def_123'), 'valid');
    ok(Net::Nostr::Group->validate_group_id('_'), 'underscore only');
    ok(Net::Nostr::Group->validate_group_id('a'), 'single char');
};

subtest 'validate_group_id rejects invalid characters' => sub {
    ok(!Net::Nostr::Group->validate_group_id('ABC'), 'uppercase rejected');
    ok(!Net::Nostr::Group->validate_group_id('ab cd'), 'space rejected');
    ok(!Net::Nostr::Group->validate_group_id('ab.cd'), 'dot rejected');
    ok(!Net::Nostr::Group->validate_group_id("ab'cd"), 'tick rejected');
    ok(!Net::Nostr::Group->validate_group_id(''), 'empty rejected');
};

subtest 'parse_id croaks on invalid group_id characters' => sub {
    ok(dies { Net::Nostr::Group->parse_id("relay.com'INVALID") },
        'croaks on uppercase in group_id');
};

###############################################################################
# h tag: MUST be on user events to groups
###############################################################################

subtest 'all user/mod events have h tag' => sub {
    my @events = (
        Net::Nostr::Group->put_user(
            pubkey => $alice_pk, group_id => 'test', target => $bob_pk,
        ),
        Net::Nostr::Group->remove_user(
            pubkey => $alice_pk, group_id => 'test', target => $bob_pk,
        ),
        Net::Nostr::Group->edit_metadata(
            pubkey => $alice_pk, group_id => 'test', name => 'Test',
        ),
        Net::Nostr::Group->delete_event(
            pubkey => $alice_pk, group_id => 'test', event_id => $event_id,
        ),
        Net::Nostr::Group->create_group(
            pubkey => $alice_pk, group_id => 'test',
        ),
        Net::Nostr::Group->delete_group(
            pubkey => $alice_pk, group_id => 'test',
        ),
        Net::Nostr::Group->create_invite(
            pubkey => $alice_pk, group_id => 'test', code => 'abc123',
        ),
        Net::Nostr::Group->join_request(
            pubkey => $bob_pk, group_id => 'test',
        ),
        Net::Nostr::Group->leave_request(
            pubkey => $bob_pk, group_id => 'test',
        ),
    );

    for my $event (@events) {
        my @h_tags = grep { $_->[0] eq 'h' } @{$event->tags};
        is(scalar @h_tags, 1, "kind ${\$event->kind} has one h tag");
        is($h_tags[0][1], 'test', "kind ${\$event->kind} h tag value is group_id");
    }
};

###############################################################################
# Timeline references (previous tag)
###############################################################################

subtest 'previous tags are included when provided' => sub {
    my $event = Net::Nostr::Group->join_request(
        pubkey   => $bob_pk,
        group_id => 'test',
        previous => ['abcd1234', 'deadbeef', '12345678'],
    );

    my @prev = grep { $_->[0] eq 'previous' } @{$event->tags};
    is(scalar @prev, 1, 'one previous tag');
    is($prev[0][1], 'abcd1234', 'first ref');
    is($prev[0][2], 'deadbeef', 'second ref');
    is($prev[0][3], '12345678', 'third ref');
};

subtest 'previous tag values are first 8 chars (4 bytes)' => sub {
    # clients should pass 8-char prefixes, but verify they are stored as-is
    my $event = Net::Nostr::Group->put_user(
        pubkey   => $alice_pk,
        group_id => 'test',
        target   => $bob_pk,
        previous => ['abcdef12'],
    );

    my @prev = grep { $_->[0] eq 'previous' } @{$event->tags};
    is(length($prev[0][1]), 8, 'reference is 8 chars');
};

subtest 'no previous tag when not provided' => sub {
    my $event = Net::Nostr::Group->join_request(
        pubkey   => $bob_pk,
        group_id => 'test',
    );

    my @prev = grep { $_->[0] eq 'previous' } @{$event->tags};
    is(scalar @prev, 0, 'no previous tag');
};

###############################################################################
# Kind 9000: put-user
###############################################################################

subtest 'put_user produces kind 9000' => sub {
    my $event = Net::Nostr::Group->put_user(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        target   => $bob_pk,
    );
    is($event->kind, 9000, 'kind is 9000');
    isa_ok($event, 'Net::Nostr::Event');
};

subtest 'put_user p tag with pubkey and optional roles' => sub {
    my $event = Net::Nostr::Group->put_user(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        target   => $bob_pk,
        roles    => ['admin', 'moderator'],
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p_tags, 1, 'one p tag');
    is($p_tags[0][1], $bob_pk, 'p tag has target pubkey');
    is($p_tags[0][2], 'admin', 'first role');
    is($p_tags[0][3], 'moderator', 'second role');
};

subtest 'put_user p tag without roles' => sub {
    my $event = Net::Nostr::Group->put_user(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        target   => $bob_pk,
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @$_, 2, 'p tag has only pubkey (no roles)') for @p_tags;
};

subtest 'put_user with optional content reason' => sub {
    my $event = Net::Nostr::Group->put_user(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        target   => $bob_pk,
        reason   => 'promoted to admin',
    );
    is($event->content, 'promoted to admin', 'content is reason');
};

subtest 'put_user content defaults to empty' => sub {
    my $event = Net::Nostr::Group->put_user(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        target   => $bob_pk,
    );
    is($event->content, '', 'content is empty');
};

subtest 'put_user croaks without required params' => sub {
    ok(dies { Net::Nostr::Group->put_user(
        group_id => 'test', target => $bob_pk,
    ) }, 'croaks without pubkey');
    ok(dies { Net::Nostr::Group->put_user(
        pubkey => $alice_pk, target => $bob_pk,
    ) }, 'croaks without group_id');
    ok(dies { Net::Nostr::Group->put_user(
        pubkey => $alice_pk, group_id => 'test',
    ) }, 'croaks without target');
};

subtest 'put_user passes extra args to Event' => sub {
    my $event = Net::Nostr::Group->put_user(
        pubkey     => $alice_pk,
        group_id   => 'test',
        target     => $bob_pk,
        created_at => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# Kind 9001: remove-user
###############################################################################

subtest 'remove_user produces kind 9001' => sub {
    my $event = Net::Nostr::Group->remove_user(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        target   => $bob_pk,
    );
    is($event->kind, 9001, 'kind is 9001');
};

subtest 'remove_user p tag with pubkey' => sub {
    my $event = Net::Nostr::Group->remove_user(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        target   => $bob_pk,
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p_tags, 1, 'one p tag');
    is($p_tags[0][1], $bob_pk, 'p tag has target pubkey');
};

subtest 'remove_user with reason' => sub {
    my $event = Net::Nostr::Group->remove_user(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        target   => $bob_pk,
        reason   => 'spamming',
    );
    is($event->content, 'spamming', 'content is reason');
};

subtest 'remove_user croaks without target' => sub {
    ok(dies { Net::Nostr::Group->remove_user(
        pubkey => $alice_pk, group_id => 'test',
    ) }, 'croaks without target');
};

###############################################################################
# Kind 9002: edit-metadata
###############################################################################

subtest 'edit_metadata produces kind 9002' => sub {
    my $event = Net::Nostr::Group->edit_metadata(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        name     => 'Pizza Lovers',
    );
    is($event->kind, 9002, 'kind is 9002');
};

subtest 'edit_metadata with name, picture, about tags' => sub {
    my $event = Net::Nostr::Group->edit_metadata(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        name     => 'Pizza Lovers',
        picture  => 'https://pizza.com/pic.png',
        about    => 'We love pizza',
    );

    my @name_tags = grep { $_->[0] eq 'name' } @{$event->tags};
    my @pic_tags  = grep { $_->[0] eq 'picture' } @{$event->tags};
    my @about_tags = grep { $_->[0] eq 'about' } @{$event->tags};

    is($name_tags[0][1], 'Pizza Lovers', 'name tag');
    is($pic_tags[0][1], 'https://pizza.com/pic.png', 'picture tag');
    is($about_tags[0][1], 'We love pizza', 'about tag');
};

subtest 'edit_metadata with group property flags' => sub {
    # These are single-element tags when set
    my $event = Net::Nostr::Group->edit_metadata(
        pubkey     => $alice_pk,
        group_id   => 'pizza',
        name       => 'Pizza',
        private    => 1,
        closed     => 1,
    );

    my @private = grep { $_->[0] eq 'private' } @{$event->tags};
    my @closed  = grep { $_->[0] eq 'closed' } @{$event->tags};
    is(scalar @private, 1, 'private flag tag present');
    is(scalar @closed, 1, 'closed flag tag present');
    is(scalar @{$private[0]}, 1, 'private tag has no value');
    is(scalar @{$closed[0]}, 1, 'closed tag has no value');
};

subtest 'edit_metadata open/visible/public/unrestricted flags' => sub {
    my $event = Net::Nostr::Group->edit_metadata(
        pubkey       => $alice_pk,
        group_id     => 'pizza',
        unrestricted => 1,
        open         => 1,
        visible      => 1,
        public       => 1,
    );

    for my $flag (qw(unrestricted open visible public)) {
        my @tags = grep { $_->[0] eq $flag } @{$event->tags};
        is(scalar @tags, 1, "$flag flag present");
    }
};

subtest 'edit_metadata flags not included when false' => sub {
    my $event = Net::Nostr::Group->edit_metadata(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        name     => 'Pizza',
    );

    for my $flag (qw(private closed unrestricted open visible public)) {
        my @tags = grep { $_->[0] eq $flag } @{$event->tags};
        is(scalar @tags, 0, "$flag not present when not set");
    }
};

subtest 'edit_metadata croaks without group_id' => sub {
    ok(dies { Net::Nostr::Group->edit_metadata(
        pubkey => $alice_pk, name => 'Test',
    ) }, 'croaks without group_id');
};

###############################################################################
# Kind 9005: delete-event
###############################################################################

subtest 'delete_event produces kind 9005' => sub {
    my $event = Net::Nostr::Group->delete_event(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        event_id => $event_id,
    );
    is($event->kind, 9005, 'kind is 9005');
};

subtest 'delete_event has e tag with event id' => sub {
    my $event = Net::Nostr::Group->delete_event(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        event_id => $event_id,
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is(scalar @e_tags, 1, 'one e tag');
    is($e_tags[0][1], $event_id, 'e tag has event id');
};

subtest 'delete_event with reason' => sub {
    my $event = Net::Nostr::Group->delete_event(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        event_id => $event_id,
        reason   => 'spam content',
    );
    is($event->content, 'spam content', 'content is reason');
};

subtest 'delete_event croaks without event_id' => sub {
    ok(dies { Net::Nostr::Group->delete_event(
        pubkey => $alice_pk, group_id => 'test',
    ) }, 'croaks without event_id');
};

###############################################################################
# Kind 9007: create-group
###############################################################################

subtest 'create_group produces kind 9007' => sub {
    my $event = Net::Nostr::Group->create_group(
        pubkey   => $alice_pk,
        group_id => 'new-group',
    );
    is($event->kind, 9007, 'kind is 9007');

    my @h_tags = grep { $_->[0] eq 'h' } @{$event->tags};
    is($h_tags[0][1], 'new-group', 'h tag has group_id');
};

subtest 'create_group croaks without group_id' => sub {
    ok(dies { Net::Nostr::Group->create_group(
        pubkey => $alice_pk,
    ) }, 'croaks without group_id');
};

###############################################################################
# Kind 9008: delete-group
###############################################################################

subtest 'delete_group produces kind 9008' => sub {
    my $event = Net::Nostr::Group->delete_group(
        pubkey   => $alice_pk,
        group_id => 'old-group',
    );
    is($event->kind, 9008, 'kind is 9008');

    my @h_tags = grep { $_->[0] eq 'h' } @{$event->tags};
    is($h_tags[0][1], 'old-group', 'h tag has group_id');
};

subtest 'delete_group with reason' => sub {
    my $event = Net::Nostr::Group->delete_group(
        pubkey   => $alice_pk,
        group_id => 'old-group',
        reason   => 'inactive',
    );
    is($event->content, 'inactive', 'content is reason');
};

###############################################################################
# Kind 9009: create-invite
###############################################################################

subtest 'create_invite produces kind 9009' => sub {
    my $event = Net::Nostr::Group->create_invite(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        code     => 'secret-code-123',
    );
    is($event->kind, 9009, 'kind is 9009');
};

subtest 'create_invite has code tag' => sub {
    my $event = Net::Nostr::Group->create_invite(
        pubkey   => $alice_pk,
        group_id => 'pizza',
        code     => 'secret-code-123',
    );

    my @code_tags = grep { $_->[0] eq 'code' } @{$event->tags};
    is(scalar @code_tags, 1, 'one code tag');
    is($code_tags[0][1], 'secret-code-123', 'code value');
};

subtest 'create_invite croaks without code' => sub {
    ok(dies { Net::Nostr::Group->create_invite(
        pubkey => $alice_pk, group_id => 'test',
    ) }, 'croaks without code');
};

###############################################################################
# Kind 9021: join-request
###############################################################################

subtest 'join_request produces kind 9021' => sub {
    my $event = Net::Nostr::Group->join_request(
        pubkey   => $bob_pk,
        group_id => 'pizza',
    );
    is($event->kind, 9021, 'kind is 9021');
};

subtest 'join_request with optional reason in content' => sub {
    my $event = Net::Nostr::Group->join_request(
        pubkey   => $bob_pk,
        group_id => 'pizza',
        reason   => 'I love pizza',
    );
    is($event->content, 'I love pizza', 'content has reason');
};

subtest 'join_request content defaults to empty' => sub {
    my $event = Net::Nostr::Group->join_request(
        pubkey   => $bob_pk,
        group_id => 'pizza',
    );
    is($event->content, '', 'content is empty');
};

subtest 'join_request with optional invite code' => sub {
    my $event = Net::Nostr::Group->join_request(
        pubkey   => $bob_pk,
        group_id => 'pizza',
        code     => 'invite-abc',
    );

    my @code_tags = grep { $_->[0] eq 'code' } @{$event->tags};
    is(scalar @code_tags, 1, 'one code tag');
    is($code_tags[0][1], 'invite-abc', 'code value');
};

subtest 'join_request without code has no code tag' => sub {
    my $event = Net::Nostr::Group->join_request(
        pubkey   => $bob_pk,
        group_id => 'pizza',
    );

    my @code_tags = grep { $_->[0] eq 'code' } @{$event->tags};
    is(scalar @code_tags, 0, 'no code tag');
};

subtest 'join_request croaks without group_id' => sub {
    ok(dies { Net::Nostr::Group->join_request(
        pubkey => $bob_pk,
    ) }, 'croaks without group_id');
};

subtest 'join_request passes extra args to Event' => sub {
    my $event = Net::Nostr::Group->join_request(
        pubkey     => $bob_pk,
        group_id   => 'pizza',
        created_at => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# Kind 9022: leave-request
###############################################################################

subtest 'leave_request produces kind 9022' => sub {
    my $event = Net::Nostr::Group->leave_request(
        pubkey   => $bob_pk,
        group_id => 'pizza',
    );
    is($event->kind, 9022, 'kind is 9022');
};

subtest 'leave_request with optional reason' => sub {
    my $event = Net::Nostr::Group->leave_request(
        pubkey   => $bob_pk,
        group_id => 'pizza',
        reason   => 'moving on',
    );
    is($event->content, 'moving on', 'content has reason');
};

subtest 'leave_request content defaults to empty' => sub {
    my $event = Net::Nostr::Group->leave_request(
        pubkey   => $bob_pk,
        group_id => 'pizza',
    );
    is($event->content, '', 'content is empty');
};

subtest 'leave_request croaks without group_id' => sub {
    ok(dies { Net::Nostr::Group->leave_request(
        pubkey => $bob_pk,
    ) }, 'croaks without group_id');
};

###############################################################################
# Kind 39000: group metadata (relay-generated, addressable)
###############################################################################

subtest 'metadata produces kind 39000 addressable event' => sub {
    my $event = Net::Nostr::Group->metadata(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        name     => 'Pizza Lovers',
    );
    is($event->kind, 39000, 'kind is 39000');
    ok($event->is_addressable, 'is addressable');
};

subtest 'metadata has d tag with group_id (not h tag)' => sub {
    my $event = Net::Nostr::Group->metadata(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        name     => 'Pizza Lovers',
    );

    my @d_tags = grep { $_->[0] eq 'd' } @{$event->tags};
    my @h_tags = grep { $_->[0] eq 'h' } @{$event->tags};
    is(scalar @d_tags, 1, 'one d tag');
    is($d_tags[0][1], 'pizza', 'd tag has group_id');
    is(scalar @h_tags, 0, 'no h tag on metadata events');
};

subtest 'metadata with name, picture, about' => sub {
    my $event = Net::Nostr::Group->metadata(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        name     => 'Pizza Lovers',
        picture  => 'https://pizza.com/pizza.png',
        about    => 'a group for people who love pizza',
    );

    my @name = grep { $_->[0] eq 'name' } @{$event->tags};
    my @pic  = grep { $_->[0] eq 'picture' } @{$event->tags};
    my @about = grep { $_->[0] eq 'about' } @{$event->tags};

    is($name[0][1], 'Pizza Lovers', 'name tag');
    is($pic[0][1], 'https://pizza.com/pizza.png', 'picture tag');
    is($about[0][1], 'a group for people who love pizza', 'about tag');
};

subtest 'metadata with property flags' => sub {
    my $event = Net::Nostr::Group->metadata(
        pubkey     => $relay_pk,
        group_id   => 'pizza',
        name       => 'Pizza',
        private    => 1,
        restricted => 1,
        hidden     => 1,
        closed     => 1,
    );

    for my $flag (qw(private restricted hidden closed)) {
        my @tags = grep { $_->[0] eq $flag } @{$event->tags};
        is(scalar @tags, 1, "$flag flag present");
        is(scalar @{$tags[0]}, 1, "$flag is single-element tag");
    }
};

subtest 'metadata flags omitted when false/not set' => sub {
    my $event = Net::Nostr::Group->metadata(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        name     => 'Pizza',
    );

    for my $flag (qw(private restricted hidden closed)) {
        my @tags = grep { $_->[0] eq $flag } @{$event->tags};
        is(scalar @tags, 0, "$flag not present when not set");
    }
};

subtest 'metadata content is empty string' => sub {
    my $event = Net::Nostr::Group->metadata(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        name     => 'Pizza',
    );
    is($event->content, '', 'content is empty');
};

subtest 'metadata croaks without group_id' => sub {
    ok(dies { Net::Nostr::Group->metadata(
        pubkey => $relay_pk, name => 'Test',
    ) }, 'croaks without group_id');
};

###############################################################################
# Kind 39001: group admins (relay-generated, addressable)
###############################################################################

subtest 'admins produces kind 39001 addressable event' => sub {
    my $event = Net::Nostr::Group->admins(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        members  => [{ pubkey => $alice_pk, roles => ['admin'] }],
    );
    is($event->kind, 39001, 'kind is 39001');
    ok($event->is_addressable, 'is addressable');
};

subtest 'admins has d tag with group_id' => sub {
    my $event = Net::Nostr::Group->admins(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        members  => [{ pubkey => $alice_pk, roles => ['admin'] }],
    );

    my @d_tags = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d_tags[0][1], 'pizza', 'd tag has group_id');
};

subtest 'admins p tags with pubkeys and roles' => sub {
    my $event = Net::Nostr::Group->admins(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        members  => [
            { pubkey => $alice_pk, roles => ['ceo'] },
            { pubkey => $bob_pk,   roles => ['secretary', 'gardener'] },
        ],
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p_tags, 2, 'two p tags');
    is($p_tags[0][1], $alice_pk, 'first admin pubkey');
    is($p_tags[0][2], 'ceo', 'first admin role');
    is($p_tags[1][1], $bob_pk, 'second admin pubkey');
    is($p_tags[1][2], 'secretary', 'second admin first role');
    is($p_tags[1][3], 'gardener', 'second admin second role');
};

subtest 'admins with optional content' => sub {
    my $event = Net::Nostr::Group->admins(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        content  => 'list of admins for the pizza lovers group',
        members  => [{ pubkey => $alice_pk, roles => ['admin'] }],
    );
    is($event->content, 'list of admins for the pizza lovers group', 'content');
};

subtest 'admins content defaults to empty' => sub {
    my $event = Net::Nostr::Group->admins(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        members  => [{ pubkey => $alice_pk, roles => ['admin'] }],
    );
    is($event->content, '', 'content is empty');
};

subtest 'admins croaks without members' => sub {
    ok(dies { Net::Nostr::Group->admins(
        pubkey => $relay_pk, group_id => 'test',
    ) }, 'croaks without members');
};

###############################################################################
# Kind 39002: group members (relay-generated, addressable)
###############################################################################

subtest 'members produces kind 39002 addressable event' => sub {
    my $event = Net::Nostr::Group->members(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        members  => [$alice_pk, $bob_pk, $carol_pk],
    );
    is($event->kind, 39002, 'kind is 39002');
    ok($event->is_addressable, 'is addressable');
};

subtest 'members has d tag and p tags' => sub {
    my $event = Net::Nostr::Group->members(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        members  => [$alice_pk, $bob_pk],
    );

    my @d_tags = grep { $_->[0] eq 'd' } @{$event->tags};
    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};

    is($d_tags[0][1], 'pizza', 'd tag has group_id');
    is(scalar @p_tags, 2, 'two p tags');
    is($p_tags[0][1], $alice_pk, 'first member');
    is($p_tags[1][1], $bob_pk, 'second member');
};

subtest 'members with optional content' => sub {
    my $event = Net::Nostr::Group->members(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        content  => 'list of members',
        members  => [$alice_pk],
    );
    is($event->content, 'list of members', 'content');
};

subtest 'members croaks without members' => sub {
    ok(dies { Net::Nostr::Group->members(
        pubkey => $relay_pk, group_id => 'test',
    ) }, 'croaks without members');
};

###############################################################################
# Kind 39003: group roles (relay-generated, addressable)
###############################################################################

subtest 'roles produces kind 39003 addressable event' => sub {
    my $event = Net::Nostr::Group->roles(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        roles    => [{ name => 'admin' }],
    );
    is($event->kind, 39003, 'kind is 39003');
    ok($event->is_addressable, 'is addressable');
};

subtest 'roles has d tag and role tags' => sub {
    my $event = Net::Nostr::Group->roles(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        roles    => [
            { name => 'admin', description => 'full control' },
            { name => 'moderator', description => 'can delete messages' },
        ],
    );

    my @d_tags = grep { $_->[0] eq 'd' } @{$event->tags};
    my @role_tags = grep { $_->[0] eq 'role' } @{$event->tags};

    is($d_tags[0][1], 'pizza', 'd tag has group_id');
    is(scalar @role_tags, 2, 'two role tags');
    is($role_tags[0][1], 'admin', 'first role name');
    is($role_tags[0][2], 'full control', 'first role description');
    is($role_tags[1][1], 'moderator', 'second role name');
    is($role_tags[1][2], 'can delete messages', 'second role description');
};

subtest 'roles without description' => sub {
    my $event = Net::Nostr::Group->roles(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        roles    => [{ name => 'admin' }],
    );

    my @role_tags = grep { $_->[0] eq 'role' } @{$event->tags};
    is(scalar @{$role_tags[0]}, 2, 'role tag has only name');
};

subtest 'roles with optional content' => sub {
    my $event = Net::Nostr::Group->roles(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        content  => 'list of roles',
        roles    => [{ name => 'admin' }],
    );
    is($event->content, 'list of roles', 'content');
};

subtest 'roles croaks without roles' => sub {
    ok(dies { Net::Nostr::Group->roles(
        pubkey => $relay_pk, group_id => 'test',
    ) }, 'croaks without roles');
};

###############################################################################
# Parsing: metadata_from_event
###############################################################################

subtest 'metadata_from_event parses kind 39000' => sub {
    my $event = make_event(
        pubkey  => $relay_pk,
        kind    => 39000,
        content => '',
        tags    => [
            ['d', 'pizza'],
            ['name', 'Pizza Lovers'],
            ['picture', 'https://pizza.com/pizza.png'],
            ['about', 'a group for people who love pizza'],
            ['private'],
            ['closed'],
        ],
    );

    my $meta = Net::Nostr::Group->metadata_from_event($event);
    is($meta->{group_id}, 'pizza', 'group_id');
    is($meta->{name}, 'Pizza Lovers', 'name');
    is($meta->{picture}, 'https://pizza.com/pizza.png', 'picture');
    is($meta->{about}, 'a group for people who love pizza', 'about');
    is($meta->{private}, 1, 'private flag');
    is($meta->{closed}, 1, 'closed flag');
    ok(!$meta->{restricted}, 'restricted not set');
    ok(!$meta->{hidden}, 'hidden not set');
};

subtest 'metadata_from_event with all flags' => sub {
    my $event = make_event(
        pubkey  => $relay_pk,
        kind    => 39000,
        content => '',
        tags    => [
            ['d', 'pizza'],
            ['name', 'Pizza'],
            ['private'],
            ['restricted'],
            ['hidden'],
            ['closed'],
        ],
    );

    my $meta = Net::Nostr::Group->metadata_from_event($event);
    is($meta->{private}, 1, 'private');
    is($meta->{restricted}, 1, 'restricted');
    is($meta->{hidden}, 1, 'hidden');
    is($meta->{closed}, 1, 'closed');
};

subtest 'metadata_from_event without optional fields' => sub {
    my $event = make_event(
        pubkey  => $relay_pk,
        kind    => 39000,
        content => '',
        tags    => [['d', 'test']],
    );

    my $meta = Net::Nostr::Group->metadata_from_event($event);
    is($meta->{group_id}, 'test', 'group_id');
    is($meta->{name}, undef, 'name is undef');
    is($meta->{picture}, undef, 'picture is undef');
    is($meta->{about}, undef, 'about is undef');
};

subtest 'metadata_from_event croaks on wrong kind' => sub {
    my $event = make_event(
        pubkey => $relay_pk, kind => 1, content => '',
    );
    ok(dies { Net::Nostr::Group->metadata_from_event($event) },
        'croaks on kind 1');
};

###############################################################################
# Parsing: admins_from_event
###############################################################################

subtest 'admins_from_event parses kind 39001' => sub {
    my $event = make_event(
        pubkey  => $relay_pk,
        kind    => 39001,
        content => 'admin list',
        tags    => [
            ['d', 'pizza'],
            ['p', $alice_pk, 'ceo'],
            ['p', $bob_pk, 'secretary', 'gardener'],
        ],
    );

    my $result = Net::Nostr::Group->admins_from_event($event);
    is($result->{group_id}, 'pizza', 'group_id');
    is(scalar @{$result->{admins}}, 2, 'two admins');
    is($result->{admins}[0]{pubkey}, $alice_pk, 'first admin pubkey');
    is($result->{admins}[0]{roles}, ['ceo'], 'first admin roles');
    is($result->{admins}[1]{pubkey}, $bob_pk, 'second admin pubkey');
    is($result->{admins}[1]{roles}, ['secretary', 'gardener'], 'second admin roles');
};

subtest 'admins_from_event croaks on wrong kind' => sub {
    my $event = make_event(
        pubkey => $relay_pk, kind => 1, content => '',
    );
    ok(dies { Net::Nostr::Group->admins_from_event($event) },
        'croaks on kind 1');
};

###############################################################################
# Parsing: members_from_event
###############################################################################

subtest 'members_from_event parses kind 39002' => sub {
    my $event = make_event(
        pubkey  => $relay_pk,
        kind    => 39002,
        content => '',
        tags    => [
            ['d', 'pizza'],
            ['p', $alice_pk],
            ['p', $bob_pk],
            ['p', $carol_pk],
        ],
    );

    my $result = Net::Nostr::Group->members_from_event($event);
    is($result->{group_id}, 'pizza', 'group_id');
    is($result->{members}, [$alice_pk, $bob_pk, $carol_pk], 'members list');
};

subtest 'members_from_event croaks on wrong kind' => sub {
    my $event = make_event(
        pubkey => $relay_pk, kind => 1, content => '',
    );
    ok(dies { Net::Nostr::Group->members_from_event($event) },
        'croaks on kind 1');
};

###############################################################################
# Parsing: roles_from_event
###############################################################################

subtest 'roles_from_event parses kind 39003' => sub {
    my $event = make_event(
        pubkey  => $relay_pk,
        kind    => 39003,
        content => '',
        tags    => [
            ['d', 'pizza'],
            ['role', 'admin', 'full control'],
            ['role', 'moderator', 'can delete messages'],
        ],
    );

    my $result = Net::Nostr::Group->roles_from_event($event);
    is($result->{group_id}, 'pizza', 'group_id');
    is(scalar @{$result->{roles}}, 2, 'two roles');
    is($result->{roles}[0]{name}, 'admin', 'first role name');
    is($result->{roles}[0]{description}, 'full control', 'first role description');
    is($result->{roles}[1]{name}, 'moderator', 'second role name');
};

subtest 'roles_from_event with roles that lack description' => sub {
    my $event = make_event(
        pubkey  => $relay_pk,
        kind    => 39003,
        content => '',
        tags    => [
            ['d', 'pizza'],
            ['role', 'admin'],
        ],
    );

    my $result = Net::Nostr::Group->roles_from_event($event);
    is($result->{roles}[0]{name}, 'admin', 'role name');
    is($result->{roles}[0]{description}, undef, 'description is undef');
};

subtest 'roles_from_event croaks on wrong kind' => sub {
    my $event = make_event(
        pubkey => $relay_pk, kind => 1, content => '',
    );
    ok(dies { Net::Nostr::Group->roles_from_event($event) },
        'croaks on kind 1');
};

###############################################################################
# Parsing: group_id_from_event (h or d tag)
###############################################################################

subtest 'group_id_from_event extracts h tag for user events' => sub {
    my $event = make_event(
        pubkey  => $bob_pk,
        kind    => 9021,
        content => '',
        tags    => [['h', 'pizza']],
    );
    is(Net::Nostr::Group->group_id_from_event($event), 'pizza',
        'group_id from h tag');
};

subtest 'group_id_from_event extracts d tag for metadata events' => sub {
    my $event = make_event(
        pubkey  => $relay_pk,
        kind    => 39000,
        content => '',
        tags    => [['d', 'pizza'], ['name', 'Pizza']],
    );
    is(Net::Nostr::Group->group_id_from_event($event), 'pizza',
        'group_id from d tag');
};

subtest 'group_id_from_event returns undef when no h or d tag' => sub {
    my $event = make_event(
        pubkey  => $bob_pk,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );
    is(Net::Nostr::Group->group_id_from_event($event), undef,
        'undef when no group tag');
};

###############################################################################
# Round-trips
###############################################################################

subtest 'round-trip: metadata -> metadata_from_event' => sub {
    my $event = Net::Nostr::Group->metadata(
        pubkey     => $relay_pk,
        group_id   => 'pizza',
        name       => 'Pizza Lovers',
        picture    => 'https://pizza.com/pizza.png',
        about      => 'we love pizza',
        private    => 1,
        closed     => 1,
    );

    my $meta = Net::Nostr::Group->metadata_from_event($event);
    is($meta->{group_id}, 'pizza', 'group_id round-trips');
    is($meta->{name}, 'Pizza Lovers', 'name round-trips');
    is($meta->{picture}, 'https://pizza.com/pizza.png', 'picture round-trips');
    is($meta->{about}, 'we love pizza', 'about round-trips');
    is($meta->{private}, 1, 'private round-trips');
    is($meta->{closed}, 1, 'closed round-trips');
};

subtest 'round-trip: admins -> admins_from_event' => sub {
    my $event = Net::Nostr::Group->admins(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        members  => [
            { pubkey => $alice_pk, roles => ['admin'] },
            { pubkey => $bob_pk,   roles => ['mod', 'janitor'] },
        ],
    );

    my $result = Net::Nostr::Group->admins_from_event($event);
    is($result->{group_id}, 'pizza', 'group_id round-trips');
    is($result->{admins}[0]{pubkey}, $alice_pk, 'first admin round-trips');
    is($result->{admins}[0]{roles}, ['admin'], 'first admin roles round-trip');
    is($result->{admins}[1]{roles}, ['mod', 'janitor'], 'second admin roles round-trip');
};

subtest 'round-trip: members -> members_from_event' => sub {
    my $event = Net::Nostr::Group->members(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        members  => [$alice_pk, $bob_pk, $carol_pk],
    );

    my $result = Net::Nostr::Group->members_from_event($event);
    is($result->{members}, [$alice_pk, $bob_pk, $carol_pk], 'members round-trip');
};

subtest 'round-trip: roles -> roles_from_event' => sub {
    my $event = Net::Nostr::Group->roles(
        pubkey   => $relay_pk,
        group_id => 'pizza',
        roles    => [
            { name => 'admin', description => 'full control' },
            { name => 'mod' },
        ],
    );

    my $result = Net::Nostr::Group->roles_from_event($event);
    is($result->{roles}[0]{name}, 'admin', 'first role round-trips');
    is($result->{roles}[0]{description}, 'full control', 'description round-trips');
    is($result->{roles}[1]{name}, 'mod', 'second role round-trips');
    is($result->{roles}[1]{description}, undef, 'missing description stays undef');
};

subtest 'round-trip: group_id through user events' => sub {
    for my $method (qw(join_request leave_request)) {
        my $event = Net::Nostr::Group->$method(
            pubkey   => $bob_pk,
            group_id => 'test-group',
        );
        is(Net::Nostr::Group->group_id_from_event($event), 'test-group',
            "group_id round-trips through $method");
    }
};

subtest 'round-trip: group_id through moderation events' => sub {
    my $event = Net::Nostr::Group->put_user(
        pubkey   => $alice_pk,
        group_id => 'mod-test',
        target   => $bob_pk,
    );
    is(Net::Nostr::Group->group_id_from_event($event), 'mod-test',
        'group_id round-trips through put_user');
};

###############################################################################
# Edge cases
###############################################################################

subtest 'group_id validation in event builders' => sub {
    ok(dies { Net::Nostr::Group->join_request(
        pubkey => $bob_pk, group_id => 'INVALID',
    ) }, 'croaks on invalid group_id in join_request');

    ok(dies { Net::Nostr::Group->put_user(
        pubkey => $alice_pk, group_id => 'has spaces', target => $bob_pk,
    ) }, 'croaks on invalid group_id in put_user');
};

subtest 'metadata events are addressable kind range' => sub {
    for my $kind (39000, 39001, 39002, 39003) {
        my $event = make_event(
            pubkey => $relay_pk, kind => $kind, content => '',
            tags => [['d', 'test']],
        );
        ok($event->is_addressable, "kind $kind is addressable");
    }
};

subtest 'moderation events are regular kind range' => sub {
    for my $kind (9000, 9001, 9002, 9005, 9007, 9008, 9009) {
        my $event = make_event(
            pubkey => $alice_pk, kind => $kind, content => '',
            tags => [['h', 'test']],
        );
        ok($event->is_regular, "kind $kind is regular");
    }
};

subtest 'user events are regular kind range' => sub {
    for my $kind (9021, 9022) {
        my $event = make_event(
            pubkey => $bob_pk, kind => $kind, content => '',
            tags => [['h', 'test']],
        );
        ok($event->is_regular, "kind $kind is regular");
    }
};

###############################################################################
# Normal user-created events with h tag
# "Groups may accept any event kind... with the addition of the h tag."
###############################################################################

subtest 'arbitrary event kind with h tag identified by group_id_from_event' => sub {
    # A kind 1 text note sent to a group
    my $note = make_event(
        pubkey  => $bob_pk,
        kind    => 1,
        content => 'hello group!',
        tags    => [['h', 'pizza']],
    );
    is(Net::Nostr::Group->group_id_from_event($note), 'pizza',
        'kind 1 note with h tag identified as group event');

    # A kind 30023 long-form article sent to a group
    my $article = make_event(
        pubkey  => $alice_pk,
        kind    => 30023,
        content => 'article body',
        tags    => [['d', 'my-article'], ['h', 'dev']],
    );
    # h tag should be found before d tag for user events
    is(Net::Nostr::Group->group_id_from_event($article), 'dev',
        'addressable event with both h and d tags picks h');
};

###############################################################################
# Spec example: wss://groups.nostr.com host maps to groups.nostr.com
###############################################################################

subtest 'parse_id matches spec example (line 23)' => sub {
    # "a group with id abcdef hosted at the relay wss://groups.nostr.com
    #  would be identified by the string groups.nostr.com'abcdef"
    my $parsed = Net::Nostr::Group->parse_id("groups.nostr.com'abcdef");
    is($parsed->{host}, 'groups.nostr.com', 'host from spec example');
    is($parsed->{group_id}, 'abcdef', 'group_id from spec example');
};

###############################################################################
# Group ids can be any length (line 10)
###############################################################################

subtest 'group_id of any length works in event builders' => sub {
    # Single character
    my $short = Net::Nostr::Group->join_request(
        pubkey => $bob_pk, group_id => 'a',
    );
    my @h = grep { $_->[0] eq 'h' } @{$short->tags};
    is($h[0][1], 'a', 'single-char group_id in event');

    # Very long id
    my $long_id = 'a' x 200;
    my $long = Net::Nostr::Group->join_request(
        pubkey => $bob_pk, group_id => $long_id,
    );
    @h = grep { $_->[0] eq 'h' } @{$long->tags};
    is($h[0][1], $long_id, '200-char group_id in event');
    is(length($h[0][1]), 200, 'long group_id preserved');
};

###############################################################################
# NIP-51 kind 10009: storing group list
# "A definition for kind:10009 was included in NIP-51 that allows clients
# to store the list of groups a user wants to remember being in."
###############################################################################

subtest 'kind 10009 simple groups list via NIP-51 List' => sub {
    my $list = Net::Nostr::List->new(kind => 10009);
    $list->add('group', "groups.nostr.com'pizza", 'wss://groups.nostr.com', 'Pizza Lovers');
    $list->add('group', "relay.example.com'dev", 'wss://relay.example.com');
    $list->add('r', 'wss://groups.nostr.com');
    $list->add('r', 'wss://relay.example.com');

    my $event = $list->to_event(pubkey => $alice_pk);
    is($event->kind, 10009, 'kind is 10009');
    ok($event->is_replaceable, 'is replaceable');

    my @group_tags = grep { $_->[0] eq 'group' } @{$event->tags};
    is(scalar @group_tags, 2, 'two group tags');
    is($group_tags[0][1], "groups.nostr.com'pizza", 'first group id');
    is($group_tags[0][2], 'wss://groups.nostr.com', 'first group relay');
    is($group_tags[0][3], 'Pizza Lovers', 'first group name');
    is($group_tags[1][1], "relay.example.com'dev", 'second group id');
    is($group_tags[1][2], 'wss://relay.example.com', 'second group relay');

    my @r_tags = grep { $_->[0] eq 'r' } @{$event->tags};
    is(scalar @r_tags, 2, 'two r tags');
};

subtest 'kind 10009 round-trip via List' => sub {
    my $list = Net::Nostr::List->new(kind => 10009);
    $list->add('group', "relay.com'test", 'wss://relay.com', 'Test Group');
    $list->add('r', 'wss://relay.com');

    my $event = $list->to_event(pubkey => $alice_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->kind, 10009, 'kind round-trips');
    my $items = $parsed->items;
    is(scalar @$items, 2, 'two items');
    is($items->[0][0], 'group', 'first item is group tag');
    is($items->[0][1], "relay.com'test", 'group id round-trips');
    is($items->[0][3], 'Test Group', 'group name round-trips');
    is($items->[1][0], 'r', 'second item is r tag');
};

###############################################################################
# Group metadata MUST be signed by relay's NIP-11 "self" pubkey
###############################################################################

subtest 'relay self pubkey available for signing group metadata' => sub {
    use Net::Nostr::RelayInfo;
    my $info = Net::Nostr::RelayInfo->new(self => $relay_pk);
    is($info->self, $relay_pk, 'self pubkey accessible from RelayInfo');

    # Group metadata event (kind 39000) must be signed by the self pubkey
    my $meta = Net::Nostr::Group->metadata(
        pubkey   => $info->self,
        group_id => 'pizza',
        name     => 'Pizza Lovers',
    );
    is($meta->pubkey, $relay_pk, 'group metadata uses relay self pubkey');
};

###############################################################################
# Hex validation for pubkey/event_id parameters used in tags
###############################################################################

subtest 'hex64 validation rejects invalid pubkeys and event ids' => sub {
    my %base = (pubkey => $alice_pk, group_id => 'pizza');

    # put_user target
    eval { Net::Nostr::Group->put_user(%base, target => 'INVALID') };
    like($@, qr/target must be 64-char lowercase hex/, 'put_user rejects bad target');

    eval { Net::Nostr::Group->put_user(%base, target => 'ab' x 31) };
    like($@, qr/target must be 64-char lowercase hex/, 'put_user rejects short target');

    eval { Net::Nostr::Group->put_user(%base, target => 'AB' x 32) };
    like($@, qr/target must be 64-char lowercase hex/, 'put_user rejects uppercase target');

    # remove_user target
    eval { Net::Nostr::Group->remove_user(%base, target => 'xyz') };
    like($@, qr/target must be 64-char lowercase hex/, 'remove_user rejects bad target');

    # delete_event event_id
    eval { Net::Nostr::Group->delete_event(%base, event_id => 'not-hex') };
    like($@, qr/event_id must be 64-char lowercase hex/, 'delete_event rejects bad event_id');

    # admins member pubkey
    eval {
        Net::Nostr::Group->admins(%base, members => [
            { pubkey => 'BADHEX', roles => ['admin'] },
        ]);
    };
    like($@, qr/member pubkey must be 64-char lowercase hex/, 'admins rejects bad member pubkey');

    # members list
    eval {
        Net::Nostr::Group->members(%base, members => [$alice_pk, 'short']);
    };
    like($@, qr/member pubkey must be 64-char lowercase hex/, 'members rejects bad member pubkey');
};

done_testing;
