use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::RelayAccess;

my $PK = 'a' x 64;
my $MEMBER = 'c308e1f882c1f1dff2a43d4294239ddeec04e575f2d1aad1fa21ea7684e61fb5';

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
        members => [$MEMBER],
    );
    my $parsed = Net::Nostr::RelayAccess->from_event($event);
    is($parsed->members->[0], $MEMBER);
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
        qw(new membership_list add_member remove_member
           join_request invite leave_request
           from_event validate
           members member claim));
};

done_testing;
