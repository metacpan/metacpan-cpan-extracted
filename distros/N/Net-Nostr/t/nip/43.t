use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Event;
use Net::Nostr::RelayAccess;

my $PK = 'a' x 64;
my $MEMBER1 = 'c308e1f882c1f1dff2a43d4294239ddeec04e575f2d1aad1fa21ea7684e61fb5';
my $MEMBER2 = 'ee1d336e13779e4d4c527b988429d96de16088f958cbf6c074676ac9cfd9c958';

###############################################################################
# Membership List (kind 13534)
###############################################################################

subtest 'membership_list: kind 13534' => sub {
    my $event = Net::Nostr::RelayAccess->membership_list(
        pubkey  => $PK,
        members => [$MEMBER1],
    );
    is($event->kind, 13534, 'kind is 13534');
    ok($event->is_replaceable, 'replaceable');
};

# Spec: MUST have NIP-70 "-" tag
subtest 'membership_list: protected tag' => sub {
    my $event = Net::Nostr::RelayAccess->membership_list(
        pubkey  => $PK,
        members => [$MEMBER1],
    );
    ok($event->is_protected, 'has protected tag');
};

# Spec: member tag for each member
subtest 'membership_list: member tags' => sub {
    my $event = Net::Nostr::RelayAccess->membership_list(
        pubkey  => $PK,
        members => [$MEMBER1, $MEMBER2],
    );
    my @m = grep { $_->[0] eq 'member' } @{$event->tags};
    is(scalar @m, 2, 'two member tags');
    is($m[0][1], $MEMBER1, 'first member');
    is($m[1][1], $MEMBER2, 'second member');
};

# Spec: empty members list
subtest 'membership_list: empty members' => sub {
    my $event = Net::Nostr::RelayAccess->membership_list(
        pubkey  => $PK,
        members => [],
    );
    my @m = grep { $_->[0] eq 'member' } @{$event->tags};
    is(scalar @m, 0, 'no member tags');
    ok($event->is_protected, 'still protected');
};

# Spec example
subtest 'membership_list: spec example' => sub {
    my $event = Net::Nostr::RelayAccess->membership_list(
        pubkey  => $PK,
        members => [$MEMBER1, $MEMBER2],
    );
    is($event->kind, 13534, 'kind');
    ok($event->is_protected, 'protected');
    my @m = grep { $_->[0] eq 'member' } @{$event->tags};
    is(scalar @m, 2, 'member count');
    is($m[0][1], $MEMBER1, 'member 1 from spec');
    is($m[1][1], $MEMBER2, 'member 2 from spec');
};

# Spec: members defaults to []
subtest 'membership_list: members defaults to empty' => sub {
    my $event = Net::Nostr::RelayAccess->membership_list(
        pubkey => $PK,
    );
    my @m = grep { $_->[0] eq 'member' } @{$event->tags};
    is(scalar @m, 0, 'no member tags');
};

###############################################################################
# Add User (kind 8000)
###############################################################################

subtest 'add_member: kind 8000' => sub {
    my $event = Net::Nostr::RelayAccess->add_member(
        pubkey => $PK,
        member => $MEMBER1,
    );
    is($event->kind, 8000, 'kind is 8000');
    ok($event->is_regular, 'regular');
};

# Spec: MUST have "-" tag
subtest 'add_member: protected tag' => sub {
    my $event = Net::Nostr::RelayAccess->add_member(
        pubkey => $PK,
        member => $MEMBER1,
    );
    ok($event->is_protected, 'has protected tag');
};

# Spec: p tag with member's hex pubkey
subtest 'add_member: p tag' => sub {
    my $event = Net::Nostr::RelayAccess->add_member(
        pubkey => $PK,
        member => $MEMBER1,
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 1, 'one p tag');
    is($p[0][1], $MEMBER1, 'p tag value');
};

# Spec example
subtest 'add_member: spec example' => sub {
    my $event = Net::Nostr::RelayAccess->add_member(
        pubkey => $PK,
        member => $MEMBER1,
    );
    is($event->kind, 8000, 'kind');
    ok($event->is_protected, 'protected');
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0][1], $MEMBER1, 'member from spec example');
};

# Spec: requires member
subtest 'add_member: requires member' => sub {
    like(
        dies {
            Net::Nostr::RelayAccess->add_member(pubkey => $PK)
        },
        qr/member/i,
        'requires member'
    );
};

###############################################################################
# Remove User (kind 8001)
###############################################################################

subtest 'remove_member: kind 8001' => sub {
    my $event = Net::Nostr::RelayAccess->remove_member(
        pubkey => $PK,
        member => $MEMBER1,
    );
    is($event->kind, 8001, 'kind is 8001');
    ok($event->is_regular, 'regular');
};

# Spec: MUST have "-" tag
subtest 'remove_member: protected tag' => sub {
    my $event = Net::Nostr::RelayAccess->remove_member(
        pubkey => $PK,
        member => $MEMBER1,
    );
    ok($event->is_protected, 'has protected tag');
};

# Spec: p tag with member's hex pubkey
subtest 'remove_member: p tag' => sub {
    my $event = Net::Nostr::RelayAccess->remove_member(
        pubkey => $PK,
        member => $MEMBER1,
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 1, 'one p tag');
    is($p[0][1], $MEMBER1, 'p tag value');
};

# Spec example
subtest 'remove_member: spec example' => sub {
    my $event = Net::Nostr::RelayAccess->remove_member(
        pubkey => $PK,
        member => $MEMBER1,
    );
    is($event->kind, 8001, 'kind');
    ok($event->is_protected, 'protected');
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0][1], $MEMBER1, 'member from spec example');
};

# Spec: requires member
subtest 'remove_member: requires member' => sub {
    like(
        dies {
            Net::Nostr::RelayAccess->remove_member(pubkey => $PK)
        },
        qr/member/i,
        'requires member'
    );
};

###############################################################################
# Join Request (kind 28934)
###############################################################################

subtest 'join_request: kind 28934' => sub {
    my $event = Net::Nostr::RelayAccess->join_request(
        pubkey => $PK,
        claim  => 'invite-code-123',
    );
    is($event->kind, 28934, 'kind is 28934');
    ok($event->is_ephemeral, 'ephemeral');
};

# Spec: MUST have "-" tag
subtest 'join_request: protected tag' => sub {
    my $event = Net::Nostr::RelayAccess->join_request(
        pubkey => $PK,
        claim  => 'invite-code-123',
    );
    ok($event->is_protected, 'has protected tag');
};

# Spec: MUST have claim tag with invite code
subtest 'join_request: claim tag' => sub {
    my $event = Net::Nostr::RelayAccess->join_request(
        pubkey => $PK,
        claim  => 'invite-code-123',
    );
    my @c = grep { $_->[0] eq 'claim' } @{$event->tags};
    is(scalar @c, 1, 'one claim tag');
    is($c[0][1], 'invite-code-123', 'claim value');
};

# Spec example
subtest 'join_request: spec example' => sub {
    my $event = Net::Nostr::RelayAccess->join_request(
        pubkey => $PK,
        claim  => '<invite code>',
    );
    is($event->kind, 28934, 'kind');
    ok($event->is_protected, 'protected');
    my @c = grep { $_->[0] eq 'claim' } @{$event->tags};
    is($c[0][1], '<invite code>', 'claim from spec example');
};

# Spec: requires claim
subtest 'join_request: requires claim' => sub {
    like(
        dies {
            Net::Nostr::RelayAccess->join_request(pubkey => $PK)
        },
        qr/claim/i,
        'requires claim'
    );
};

###############################################################################
# Invite (kind 28935)
###############################################################################

subtest 'invite: kind 28935' => sub {
    my $event = Net::Nostr::RelayAccess->invite(
        pubkey => $PK,
        claim  => 'generated-invite-code',
    );
    is($event->kind, 28935, 'kind is 28935');
    ok($event->is_ephemeral, 'ephemeral');
};

# Spec: MUST have "-" tag
subtest 'invite: protected tag' => sub {
    my $event = Net::Nostr::RelayAccess->invite(
        pubkey => $PK,
        claim  => 'generated-invite-code',
    );
    ok($event->is_protected, 'has protected tag');
};

# Spec: claim tag with invite code
subtest 'invite: claim tag' => sub {
    my $event = Net::Nostr::RelayAccess->invite(
        pubkey => $PK,
        claim  => 'generated-invite-code',
    );
    my @c = grep { $_->[0] eq 'claim' } @{$event->tags};
    is(scalar @c, 1, 'one claim tag');
    is($c[0][1], 'generated-invite-code', 'claim value');
};

# Spec example
subtest 'invite: spec example' => sub {
    my $event = Net::Nostr::RelayAccess->invite(
        pubkey => $PK,
        claim  => '<invite code>',
    );
    is($event->kind, 28935, 'kind');
    ok($event->is_protected, 'protected');
    my @c = grep { $_->[0] eq 'claim' } @{$event->tags};
    is($c[0][1], '<invite code>', 'claim from spec example');
};

# Spec: requires claim
subtest 'invite: requires claim' => sub {
    like(
        dies {
            Net::Nostr::RelayAccess->invite(pubkey => $PK)
        },
        qr/claim/i,
        'requires claim'
    );
};

###############################################################################
# Leave Request (kind 28936)
###############################################################################

subtest 'leave_request: kind 28936' => sub {
    my $event = Net::Nostr::RelayAccess->leave_request(
        pubkey => $PK,
    );
    is($event->kind, 28936, 'kind is 28936');
    ok($event->is_ephemeral, 'ephemeral');
};

# Spec: MUST have "-" tag
subtest 'leave_request: protected tag' => sub {
    my $event = Net::Nostr::RelayAccess->leave_request(
        pubkey => $PK,
    );
    ok($event->is_protected, 'has protected tag');
};

# Spec example: minimal event with just "-" tag
subtest 'leave_request: spec example' => sub {
    my $event = Net::Nostr::RelayAccess->leave_request(
        pubkey => $PK,
    );
    is($event->kind, 28936, 'kind');
    ok($event->is_protected, 'protected');
    # Spec shows only ["-"] in tags, no other required tags
    my @non_protected = grep { $_->[0] ne '-' } @{$event->tags};
    is(scalar @non_protected, 0, 'no extra tags');
};

###############################################################################
# from_event: round-trip parsing
###############################################################################

subtest 'from_event: membership_list round-trip' => sub {
    my $event = Net::Nostr::RelayAccess->membership_list(
        pubkey  => $PK,
        members => [$MEMBER1, $MEMBER2],
    );
    my $parsed = Net::Nostr::RelayAccess->from_event($event);
    is(scalar @{$parsed->members}, 2, 'members count');
    is($parsed->members->[0], $MEMBER1, 'first member');
    is($parsed->members->[1], $MEMBER2, 'second member');
};

subtest 'from_event: add_member round-trip' => sub {
    my $event = Net::Nostr::RelayAccess->add_member(
        pubkey => $PK,
        member => $MEMBER1,
    );
    my $parsed = Net::Nostr::RelayAccess->from_event($event);
    is($parsed->member, $MEMBER1, 'member');
};

subtest 'from_event: remove_member round-trip' => sub {
    my $event = Net::Nostr::RelayAccess->remove_member(
        pubkey => $PK,
        member => $MEMBER1,
    );
    my $parsed = Net::Nostr::RelayAccess->from_event($event);
    is($parsed->member, $MEMBER1, 'member');
};

subtest 'from_event: join_request round-trip' => sub {
    my $event = Net::Nostr::RelayAccess->join_request(
        pubkey => $PK,
        claim  => 'my-invite',
    );
    my $parsed = Net::Nostr::RelayAccess->from_event($event);
    is($parsed->claim, 'my-invite', 'claim');
};

subtest 'from_event: invite round-trip' => sub {
    my $event = Net::Nostr::RelayAccess->invite(
        pubkey => $PK,
        claim  => 'generated-code',
    );
    my $parsed = Net::Nostr::RelayAccess->from_event($event);
    is($parsed->claim, 'generated-code', 'claim');
};

subtest 'from_event: leave_request round-trip' => sub {
    my $event = Net::Nostr::RelayAccess->leave_request(
        pubkey => $PK,
    );
    my $parsed = Net::Nostr::RelayAccess->from_event($event);
    isa_ok($parsed, 'Net::Nostr::RelayAccess');
};

subtest 'from_event: returns undef for wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    is(Net::Nostr::RelayAccess->from_event($event), undef, 'undef for kind 1');
};

###############################################################################
# validate
###############################################################################

subtest 'validate: valid membership_list' => sub {
    my $event = Net::Nostr::RelayAccess->membership_list(
        pubkey  => $PK,
        members => [$MEMBER1],
    );
    ok(Net::Nostr::RelayAccess->validate($event), 'valid');
};

subtest 'validate: valid add_member' => sub {
    my $event = Net::Nostr::RelayAccess->add_member(
        pubkey => $PK,
        member => $MEMBER1,
    );
    ok(Net::Nostr::RelayAccess->validate($event), 'valid');
};

subtest 'validate: valid remove_member' => sub {
    my $event = Net::Nostr::RelayAccess->remove_member(
        pubkey => $PK,
        member => $MEMBER1,
    );
    ok(Net::Nostr::RelayAccess->validate($event), 'valid');
};

subtest 'validate: valid join_request' => sub {
    my $event = Net::Nostr::RelayAccess->join_request(
        pubkey => $PK,
        claim  => 'code',
    );
    ok(Net::Nostr::RelayAccess->validate($event), 'valid');
};

subtest 'validate: valid invite' => sub {
    my $event = Net::Nostr::RelayAccess->invite(
        pubkey => $PK,
        claim  => 'code',
    );
    ok(Net::Nostr::RelayAccess->validate($event), 'valid');
};

subtest 'validate: valid leave_request' => sub {
    my $event = Net::Nostr::RelayAccess->leave_request(
        pubkey => $PK,
    );
    ok(Net::Nostr::RelayAccess->validate($event), 'valid');
};

subtest 'validate: rejects wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    like(
        dies { Net::Nostr::RelayAccess->validate($event) },
        qr/kind/i,
        'rejects wrong kind'
    );
};

# Spec: all events MUST have "-" tag
subtest 'validate: membership_list requires protected tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 13534, content => '',
        tags => [['member', $MEMBER1]],
    );
    like(
        dies { Net::Nostr::RelayAccess->validate($event) },
        qr/protected|"-"/i,
        'rejects missing protected tag'
    );
};

subtest 'validate: add_member requires protected tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 8000, content => '',
        tags => [['p', $MEMBER1]],
    );
    like(
        dies { Net::Nostr::RelayAccess->validate($event) },
        qr/protected|"-"/i,
        'rejects missing protected tag'
    );
};

subtest 'validate: remove_member requires protected tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 8001, content => '',
        tags => [['p', $MEMBER1]],
    );
    like(
        dies { Net::Nostr::RelayAccess->validate($event) },
        qr/protected|"-"/i,
        'rejects missing protected tag'
    );
};

subtest 'validate: join_request requires protected tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 28934, content => '',
        tags => [['claim', 'code']],
    );
    like(
        dies { Net::Nostr::RelayAccess->validate($event) },
        qr/protected|"-"/i,
        'rejects missing protected tag'
    );
};

subtest 'validate: invite requires protected tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 28935, content => '',
        tags => [['claim', 'code']],
    );
    like(
        dies { Net::Nostr::RelayAccess->validate($event) },
        qr/protected|"-"/i,
        'rejects missing protected tag'
    );
};

subtest 'validate: leave_request requires protected tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 28936, content => '',
        tags => [],
    );
    like(
        dies { Net::Nostr::RelayAccess->validate($event) },
        qr/protected|"-"/i,
        'rejects missing protected tag'
    );
};

# Spec: kind 8000/8001 MUST have p tag
subtest 'validate: add_member requires p tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 8000, content => '',
        tags => [['-']],
    );
    like(
        dies { Net::Nostr::RelayAccess->validate($event) },
        qr/p.*tag/i,
        'rejects missing p tag'
    );
};

subtest 'validate: remove_member requires p tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 8001, content => '',
        tags => [['-']],
    );
    like(
        dies { Net::Nostr::RelayAccess->validate($event) },
        qr/p.*tag/i,
        'rejects missing p tag'
    );
};

# Spec: kind 28934 MUST have claim tag
subtest 'validate: join_request requires claim tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 28934, content => '',
        tags => [['-']],
    );
    like(
        dies { Net::Nostr::RelayAccess->validate($event) },
        qr/claim.*tag/i,
        'rejects missing claim tag'
    );
};

# Spec: kind 28935 has claim tag
subtest 'validate: invite requires claim tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 28935, content => '',
        tags => [['-']],
    );
    like(
        dies { Net::Nostr::RelayAccess->validate($event) },
        qr/claim.*tag/i,
        'rejects missing claim tag'
    );
};

###############################################################################
# Constructor: unknown args rejected
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::RelayAccess->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

done_testing;
