#!/usr/bin/perl

# Unit tests for Net::Nostr::Group

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Group;

my $pk = 'a' x 64;
my $target_pk = 'b' x 64;
my $eid = '1' x 64;

###############################################################################
# parse_id
###############################################################################

subtest 'parse_id basic' => sub {
    my $r = Net::Nostr::Group->parse_id("host.com'grp");
    is($r->{host}, 'host.com', 'host');
    is($r->{group_id}, 'grp', 'group_id');
};

subtest 'parse_id host only' => sub {
    my $r = Net::Nostr::Group->parse_id("host.com");
    is($r->{group_id}, '_', 'defaults to _');
};

subtest 'parse_id croaks on invalid chars' => sub {
    ok(dies { Net::Nostr::Group->parse_id("h'BAD") }, 'croaks');
};

###############################################################################
# format_id
###############################################################################

subtest 'format_id' => sub {
    is(Net::Nostr::Group->format_id(host => 'h', group_id => 'g'), "h'g", 'formatted');
};

subtest 'format_id croaks without host' => sub {
    ok(dies { Net::Nostr::Group->format_id(group_id => 'g') }, 'croaks');
};

subtest 'format_id croaks without group_id' => sub {
    ok(dies { Net::Nostr::Group->format_id(host => 'h') }, 'croaks');
};

###############################################################################
# validate_group_id
###############################################################################

subtest 'validate_group_id' => sub {
    ok(Net::Nostr::Group->validate_group_id('ok-id_1'), 'valid');
    ok(!Net::Nostr::Group->validate_group_id('NO'), 'invalid');
    ok(!Net::Nostr::Group->validate_group_id(undef), 'undef');
};

###############################################################################
# Event builders: kind, h tag, content
###############################################################################

subtest 'put_user kind and tags' => sub {
    my $e = Net::Nostr::Group->put_user(
        pubkey => $pk, group_id => 'g', target => $target_pk,
        roles => ['admin'],
    );
    is($e->kind, 9000, 'kind');
    my @h = grep { $_->[0] eq 'h' } @{$e->tags};
    is($h[0][1], 'g', 'h tag');
    my @p = grep { $_->[0] eq 'p' } @{$e->tags};
    is($p[0][1], $target_pk, 'target');
    is($p[0][2], 'admin', 'role');
};

subtest 'remove_user kind' => sub {
    my $e = Net::Nostr::Group->remove_user(
        pubkey => $pk, group_id => 'g', target => $target_pk,
    );
    is($e->kind, 9001, 'kind');
};

subtest 'edit_metadata kind and metadata tags' => sub {
    my $e = Net::Nostr::Group->edit_metadata(
        pubkey => $pk, group_id => 'g', name => 'N', about => 'A',
    );
    is($e->kind, 9002, 'kind');
    my @name = grep { $_->[0] eq 'name' } @{$e->tags};
    is($name[0][1], 'N', 'name tag');
};

subtest 'delete_event kind and e tag' => sub {
    my $e = Net::Nostr::Group->delete_event(
        pubkey => $pk, group_id => 'g', event_id => $eid,
    );
    is($e->kind, 9005, 'kind');
    my @etag = grep { $_->[0] eq 'e' } @{$e->tags};
    is($etag[0][1], $eid, 'event_id');
};

subtest 'create_group kind' => sub {
    my $e = Net::Nostr::Group->create_group(pubkey => $pk, group_id => 'g');
    is($e->kind, 9007, 'kind');
};

subtest 'delete_group kind' => sub {
    my $e = Net::Nostr::Group->delete_group(pubkey => $pk, group_id => 'g');
    is($e->kind, 9008, 'kind');
};

subtest 'create_invite kind and code' => sub {
    my $e = Net::Nostr::Group->create_invite(
        pubkey => $pk, group_id => 'g', code => 'xyz',
    );
    is($e->kind, 9009, 'kind');
    my @c = grep { $_->[0] eq 'code' } @{$e->tags};
    is($c[0][1], 'xyz', 'code');
};

subtest 'join_request kind' => sub {
    my $e = Net::Nostr::Group->join_request(pubkey => $pk, group_id => 'g');
    is($e->kind, 9021, 'kind');
};

subtest 'leave_request kind' => sub {
    my $e = Net::Nostr::Group->leave_request(pubkey => $pk, group_id => 'g');
    is($e->kind, 9022, 'kind');
};

###############################################################################
# Metadata events (addressable, d tag)
###############################################################################

subtest 'metadata kind and d tag' => sub {
    my $e = Net::Nostr::Group->metadata(
        pubkey => $pk, group_id => 'g', name => 'N',
    );
    is($e->kind, 39000, 'kind');
    is($e->d_tag, 'g', 'd_tag');
};

subtest 'admins kind' => sub {
    my $e = Net::Nostr::Group->admins(
        pubkey => $pk, group_id => 'g',
        members => [{ pubkey => $target_pk, roles => ['admin'] }],
    );
    is($e->kind, 39001, 'kind');
};

subtest 'members kind' => sub {
    my $e = Net::Nostr::Group->members(
        pubkey => $pk, group_id => 'g', members => [$target_pk],
    );
    is($e->kind, 39002, 'kind');
};

subtest 'roles kind' => sub {
    my $e = Net::Nostr::Group->roles(
        pubkey => $pk, group_id => 'g',
        roles => [{ name => 'admin' }],
    );
    is($e->kind, 39003, 'kind');
};

###############################################################################
# Parsing
###############################################################################

subtest 'metadata_from_event' => sub {
    my $e = make_event(
        pubkey => $pk, kind => 39000, content => '',
        tags => [['d', 'g'], ['name', 'N'], ['private']],
    );
    my $m = Net::Nostr::Group->metadata_from_event($e);
    is($m->{group_id}, 'g', 'group_id');
    is($m->{name}, 'N', 'name');
    is($m->{private}, 1, 'private');
};

subtest 'admins_from_event' => sub {
    my $e = make_event(
        pubkey => $pk, kind => 39001, content => '',
        tags => [['d', 'g'], ['p', $target_pk, 'admin']],
    );
    my $r = Net::Nostr::Group->admins_from_event($e);
    is($r->{admins}[0]{pubkey}, $target_pk, 'pubkey');
    is($r->{admins}[0]{roles}, ['admin'], 'roles');
};

subtest 'members_from_event' => sub {
    my $e = make_event(
        pubkey => $pk, kind => 39002, content => '',
        tags => [['d', 'g'], ['p', $target_pk]],
    );
    my $r = Net::Nostr::Group->members_from_event($e);
    is($r->{members}, [$target_pk], 'members');
};

subtest 'roles_from_event' => sub {
    my $e = make_event(
        pubkey => $pk, kind => 39003, content => '',
        tags => [['d', 'g'], ['role', 'admin', 'desc']],
    );
    my $r = Net::Nostr::Group->roles_from_event($e);
    is($r->{roles}[0]{name}, 'admin', 'name');
    is($r->{roles}[0]{description}, 'desc', 'description');
};

subtest 'group_id_from_event h vs d' => sub {
    my $h = make_event(
        pubkey => $pk, kind => 9021, content => '',
        tags => [['h', 'from-h']],
    );
    my $d = make_event(
        pubkey => $pk, kind => 39000, content => '',
        tags => [['d', 'from-d']],
    );
    is(Net::Nostr::Group->group_id_from_event($h), 'from-h', 'h tag');
    is(Net::Nostr::Group->group_id_from_event($d), 'from-d', 'd tag');
};

subtest 'group_id_from_event returns undef' => sub {
    my $e = make_event(pubkey => $pk, kind => 1, content => '', tags => []);
    is(Net::Nostr::Group->group_id_from_event($e), undef, 'undef');
};

###############################################################################
# Validation errors
###############################################################################

subtest 'croaks on missing required params' => sub {
    ok(dies { Net::Nostr::Group->put_user(pubkey => $pk, group_id => 'g') },
        'put_user without target');
    ok(dies { Net::Nostr::Group->delete_event(pubkey => $pk, group_id => 'g') },
        'delete_event without event_id');
    ok(dies { Net::Nostr::Group->create_invite(pubkey => $pk, group_id => 'g') },
        'create_invite without code');
    ok(dies { Net::Nostr::Group->metadata_from_event(
        make_event(pubkey => $pk, kind => 1, content => '')) },
        'metadata_from_event wrong kind');
};

subtest 'croaks on invalid group_id' => sub {
    ok(dies { Net::Nostr::Group->join_request(pubkey => $pk, group_id => 'BAD') },
        'uppercase rejected');
    ok(dies { Net::Nostr::Group->create_group(pubkey => $pk, group_id => 'a b') },
        'space rejected');
};

###############################################################################
# previous tag
###############################################################################

subtest 'previous tag in builders' => sub {
    my $e = Net::Nostr::Group->put_user(
        pubkey => $pk, group_id => 'g', target => $target_pk,
        previous => ['aabbccdd'],
    );
    my @prev = grep { $_->[0] eq 'previous' } @{$e->tags};
    is(scalar @prev, 1, 'one previous tag');
    is($prev[0][1], 'aabbccdd', 'value');
};

###############################################################################
# Passthrough args
###############################################################################

subtest 'extra args pass through to Event' => sub {
    my $e = Net::Nostr::Group->join_request(
        pubkey => $pk, group_id => 'g', created_at => 42,
    );
    is($e->created_at, 42, 'created_at');
};

done_testing;
