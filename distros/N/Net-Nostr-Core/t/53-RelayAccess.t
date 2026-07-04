use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::RelayAccess;

my $PK = 'a' x 64;
my $MEMBER = 'c308e1f882c1f1dff2a43d4294239ddeec04e575f2d1aad1fa21ea7684e61fb5';

###############################################################################
# POD example: role_definition
###############################################################################

subtest 'POD: role_definition' => sub {
    my $event = Net::Nostr::RelayAccess->role_definition(
        pubkey      => $PK,
        role_id     => '28b7e50f',
        label       => 'king',
        description => 'ruler of the relay',
        color       => 37,
        order       => 1,
    );
    is($event->kind, 33534, 'kind');
    ok($event->is_protected, 'protected');
    is($event->d_tag, '28b7e50f', 'role id d tag');
};

###############################################################################
# POD example: membership_list
###############################################################################

subtest 'POD: membership_list' => sub {
    my $event = Net::Nostr::RelayAccess->membership_list(
        pubkey  => $PK,
        members => [$MEMBER],
    );
    is($event->kind, 13534, 'kind');
};

###############################################################################
# POD example: add_member
###############################################################################

subtest 'POD: add_member' => sub {
    my $event = Net::Nostr::RelayAccess->add_member(
        pubkey => $PK,
        member => $MEMBER,
    );
    is($event->kind, 8000, 'kind');
};

###############################################################################
# POD example: remove_member
###############################################################################

subtest 'POD: remove_member' => sub {
    my $event = Net::Nostr::RelayAccess->remove_member(
        pubkey => $PK,
        member => $MEMBER,
    );
    is($event->kind, 8001, 'kind');
};

###############################################################################
# POD example: join_request
###############################################################################

subtest 'POD: join_request' => sub {
    my $event = Net::Nostr::RelayAccess->join_request(
        pubkey => $PK,
        claim  => 'invite-code-abc',
    );
    is($event->kind, 28934, 'kind');
};

###############################################################################
# POD example: invite
###############################################################################

subtest 'POD: invite' => sub {
    my $event = Net::Nostr::RelayAccess->invite(
        pubkey => $PK,
        claim  => 'generated-code',
    );
    is($event->kind, 28935, 'kind');
};

###############################################################################
# POD example: leave_request
###############################################################################

subtest 'POD: leave_request' => sub {
    my $event = Net::Nostr::RelayAccess->leave_request(
        pubkey => $PK,
    );
    is($event->kind, 28936, 'kind');
};

###############################################################################
# POD example: from_event
###############################################################################

subtest 'POD: from_event' => sub {
    my $event = Net::Nostr::RelayAccess->membership_list(
        pubkey  => $PK,
        members => [{ pubkey => $MEMBER, roles => ['28b7e50f'] }],
    );
    my $parsed = Net::Nostr::RelayAccess->from_event($event);
    is($parsed->members->[0]{pubkey}, $MEMBER);
    is($parsed->members->[0]{roles}, ['28b7e50f']);
};

###############################################################################
# POD example: validate
###############################################################################

subtest 'POD: validate' => sub {
    my $event = Net::Nostr::RelayAccess->membership_list(
        pubkey  => $PK,
        members => [$MEMBER],
    );
    ok(Net::Nostr::RelayAccess->validate($event), 'validate returns true');
};

###############################################################################
# POD example: new
###############################################################################

subtest 'POD: new' => sub {
    my $ra = Net::Nostr::RelayAccess->new(
        members => [$MEMBER],
    );
    is($ra->members->[0], $MEMBER);
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

###############################################################################
# Public methods available
###############################################################################

subtest 'public methods available' => sub {
    can_ok('Net::Nostr::RelayAccess',
        qw(new role_definition membership_list add_member remove_member
           join_request invite leave_request
           from_event validate
           members member claim role_id label description color order));
};

done_testing;
