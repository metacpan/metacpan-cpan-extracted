#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Bech32 qw(encode_naddr encode_npub);
use Net::Nostr::Event;
use Net::Nostr::Git;

my $my_pubkey = 'a' x 64;
my $owner_pk  = 'b' x 64;
my $author_pk = 'c' x 64;

my $commit_id     = 'abc123' . ('0' x 58);
my $tag_commit_id = 'def456' . ('0' x 58);
my $tip_commit_id = 'ghi789' . ('0' x 58);

my $new_tip_commit_id = 'jkl012' . ('0' x 58);

my $npub = encode_npub($my_pubkey);

my $event_id       = '1' x 64;
my $patch_event_id = '2' x 64;
my $pr_event_id    = '3' x 64;
my $pr_author_pk   = 'd' x 64;

###############################################################################
# POD SYNOPSIS examples
###############################################################################

subtest 'POD: announce a repository' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey      => $my_pubkey,
        id          => 'my-project',
        name        => 'My Project',
        description => 'A Nostr library',
        clone       => ['https://github.com/user/repo.git'],
        relays      => ['wss://relay.example.com'],
    );
    is $repo->kind, 30617, 'kind 30617';
    is $repo->d_tag, 'my-project', 'd tag';
    ok scalar(grep { $_->[0] eq 'name' } @{$repo->tags}), 'has name tag';
};

subtest 'POD: announce repository state' => sub {
    my $state = Net::Nostr::Git->repository_state(
        pubkey => $my_pubkey,
        id     => 'my-project',
        refs   => [
            ['refs/heads/main', $commit_id],
            ['refs/tags/v1.0',  $tag_commit_id],
        ],
        head => 'main',
    );
    is $state->kind, 30618, 'kind 30618';
    my @head = grep { $_->[0] eq 'HEAD' } @{$state->tags};
    is $head[0][1], 'ref: refs/heads/main', 'HEAD tag';
};

subtest 'POD: submit a patch' => sub {
    my $patch = Net::Nostr::Git->patch(
        pubkey     => $my_pubkey,
        content    => "From abc123 Mon Sep 17 00:00:00 2001\n...",
        repository => "30617:$owner_pk:my-project",
        repo_owner => $owner_pk,
        root       => 1,
    );
    is $patch->kind, 1617, 'kind 1617';
    my @t = grep { $_->[0] eq 't' && $_->[1] eq 'root' } @{$patch->tags};
    is scalar @t, 1, 'has root tag';
};

subtest 'POD: open a pull request' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey     => $my_pubkey,
        content    => 'Please review these changes.',
        repository => "30617:$owner_pk:my-project",
        subject    => 'Add feature X',
        commit     => $tip_commit_id,
        clone      => ['https://github.com/user/fork.git'],
    );
    is $pr->kind, 1618, 'kind 1618';
    my @s = grep { $_->[0] eq 'subject' } @{$pr->tags};
    is $s[0][1], 'Add feature X', 'subject tag';
};

subtest 'POD: file an issue' => sub {
    my $issue = Net::Nostr::Git->issue(
        pubkey     => $my_pubkey,
        content    => 'Found a bug in parsing.',
        repository => "30617:$owner_pk:my-project",
        repo_owner => $owner_pk,
        subject    => 'Crash on startup',
        labels     => ['bug'],
    );
    is $issue->kind, 1621, 'kind 1621';
    my @s = grep { $_->[0] eq 'subject' } @{$issue->tags};
    is $s[0][1], 'Crash on startup', 'subject tag';
};

subtest 'POD: update a pull request' => sub {
    my $update = Net::Nostr::Git->pull_request_update(
        pubkey     => $my_pubkey,
        repository => "30617:$owner_pk:my-project",
        pr_event   => $pr_event_id,
        pr_author  => $pr_author_pk,
        commit     => $new_tip_commit_id,
        clone      => ['https://github.com/user/fork.git'],
    );
    is $update->kind, 1619, 'kind 1619';
    my @E = grep { $_->[0] eq 'E' } @{$update->tags};
    is $E[0][1], $pr_event_id, 'E tag';
};

subtest 'POD: set status' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey        => $my_pubkey,
        status        => 'applied',
        target        => $patch_event_id,
        repo_owner    => $my_pubkey,
        target_author => $author_pk,
    );
    is $status->kind, 1631, 'kind 1631';
};

subtest 'POD: user grasp list' => sub {
    my $list = Net::Nostr::Git->grasp_list(
        pubkey  => $my_pubkey,
        servers => ['wss://grasp.example.com'],
    );
    is $list->kind, 10317, 'kind 10317';
    my @g = grep { $_->[0] eq 'g' } @{$list->tags};
    is $g[0][1], 'wss://grasp.example.com', 'g tag';
};

subtest 'POD: from_event' => sub {
    my $event = make_event(
        pubkey => $my_pubkey, kind => 30617, content => '',
        tags => [['d', 'my-project']],
    );
    my $info = Net::Nostr::Git->from_event($event);
    is $info->event_type, 'repository', 'event_type';
    is $info->repo_id, 'my-project', 'repo_id';
};

subtest 'POD: validate' => sub {
    my $event = make_event(
        pubkey => $my_pubkey, kind => 30617, content => '',
        tags => [['d', 'my-project']],
    );
    ok lives { Net::Nostr::Git->validate($event) }, 'validate succeeds';

    my $bad = make_event(pubkey => $my_pubkey, kind => 1, content => 'hello');
    ok dies { Net::Nostr::Git->validate($bad) }, 'validate rejects non-NIP-34';
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $info = Net::Nostr::Git->new(
        event_type => 'repository',
        repo_id    => 'my-project',
    );
    is $info->event_type, 'repository';
    is $info->repo_id, 'my-project';
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Git->new(event_type => 'repository', bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

###############################################################################
# nostr_clone_url / parse_nostr_clone_url - NIP-34 Nostr Clone URL format
###############################################################################

subtest 'POD: nostr_clone_url with naddr' => sub {
    my $naddr = encode_naddr(
        identifier => 'my-project',
        pubkey     => $my_pubkey,
        kind       => 30617,
        relays     => ['wss://relay.example.com'],
    );
    my $url = Net::Nostr::Git->nostr_clone_url(naddr => $naddr);
    is $url, "nostr://$naddr", 'naddr form';
};

subtest 'POD: nostr_clone_url with owner and identifier' => sub {
    my $url = Net::Nostr::Git->nostr_clone_url(
        owner      => $npub,
        identifier => 'my-project',
    );
    is $url, "nostr://$npub/my-project", 'owner/identifier form';
};

subtest 'POD: nostr_clone_url with relay hint' => sub {
    my $url = Net::Nostr::Git->nostr_clone_url(
        owner      => $npub,
        relay_hint => 'wss://relay.example.com',
        identifier => 'my-project',
    );
    is $url, "nostr://$npub/relay.example.com/my-project", 'wss:// stripped';
};

subtest 'nostr_clone_url percent-encodes identifier' => sub {
    my $url = Net::Nostr::Git->nostr_clone_url(
        owner      => $npub,
        identifier => 'my repo',
    );
    like $url, qr{/my%20repo\z}, 'space percent-encoded';
};

subtest 'nostr_clone_url keeps non-wss scheme in relay hint' => sub {
    my $url = Net::Nostr::Git->nostr_clone_url(
        owner      => 'example.com',
        relay_hint => 'ws://localhost:7334',
        identifier => 'my-repo',
    );
    like $url, qr{/ws%3A%2F%2Flocalhost%3A7334/}, 'ws:// percent-encoded';
};

subtest 'nostr_clone_url rejects missing arguments' => sub {
    like dies { Net::Nostr::Git->nostr_clone_url() },
        qr/requires/, 'no args';
    like dies { Net::Nostr::Git->nostr_clone_url(owner => $npub) },
        qr/requires.*identifier/i, 'missing identifier';
};

subtest 'nostr_clone_url rejects invalid naddr' => sub {
    ok dies { Net::Nostr::Git->nostr_clone_url(naddr => 'bogus') },
        'invalid naddr rejected';
};

subtest 'POD: parse_nostr_clone_url naddr form' => sub {
    my $naddr = encode_naddr(
        identifier => 'my-project',
        pubkey     => $my_pubkey,
        kind       => 30617,
    );
    my $result = Net::Nostr::Git->parse_nostr_clone_url("nostr://$naddr");
    is $result->{identifier}, 'my-project', 'identifier from naddr';
    is $result->{pubkey}, $my_pubkey, 'pubkey from naddr';
    is $result->{kind}, 30617, 'kind from naddr';
};

subtest 'POD: parse_nostr_clone_url owner/identifier form' => sub {
    my $result = Net::Nostr::Git->parse_nostr_clone_url("nostr://$npub/my-project");
    is $result->{owner}, $npub, 'owner';
    is $result->{identifier}, 'my-project', 'identifier';
    ok !exists $result->{relay_hint}, 'no relay_hint';
};

subtest 'parse_nostr_clone_url: owner/relay/identifier form' => sub {
    my $result = Net::Nostr::Git->parse_nostr_clone_url(
        "nostr://$npub/relay.example.com/my-project"
    );
    is $result->{owner}, $npub, 'owner';
    is $result->{relay_hint}, 'wss://relay.example.com', 'relay_hint with wss:// prepended';
    is $result->{identifier}, 'my-project', 'identifier';
};

subtest 'parse_nostr_clone_url: percent-decodes identifier' => sub {
    my $result = Net::Nostr::Git->parse_nostr_clone_url(
        "nostr://$npub/my%20%F0%9F%9A%80%20repo"
    );
    is $result->{identifier}, "my \x{1F680} repo", 'emoji in identifier decoded';
};

subtest 'parse_nostr_clone_url: non-wss relay hint' => sub {
    my $result = Net::Nostr::Git->parse_nostr_clone_url(
        "nostr://example.com/ws%3A%2F%2Flocalhost%3A7334/my-repo"
    );
    is $result->{relay_hint}, 'ws://localhost:7334', 'ws:// preserved';
    is $result->{identifier}, 'my-repo', 'identifier';
};

subtest 'spec example: npub with relay and identifier' => sub {
    my $url = 'nostr://npub15qydau2hjma6ngxkl2cyar74wzyjshvl65za5k5rl69264ar2exs5cyejr/relay.ngit.dev/ngit';
    my $result = Net::Nostr::Git->parse_nostr_clone_url($url);
    is $result->{owner}, 'npub15qydau2hjma6ngxkl2cyar74wzyjshvl65za5k5rl69264ar2exs5cyejr', 'owner';
    is $result->{relay_hint}, 'wss://relay.ngit.dev', 'relay_hint';
    is $result->{identifier}, 'ngit', 'identifier';
};

subtest 'spec example: npub with emoji identifier' => sub {
    my $url = 'nostr://npub15qydau2hjma6ngxkl2cyar74wzyjshvl65za5k5rl69264ar2exs5cyejr/my%20%F0%9F%9A%80%20repo';
    my $result = Net::Nostr::Git->parse_nostr_clone_url($url);
    is $result->{owner}, 'npub15qydau2hjma6ngxkl2cyar74wzyjshvl65za5k5rl69264ar2exs5cyejr', 'owner';
    ok !exists $result->{relay_hint}, 'no relay_hint';
    is $result->{identifier}, "my \x{1F680} repo", 'identifier with emoji';
};

subtest 'spec example: nip05 with ws relay' => sub {
    my $url = 'nostr://danconwaydev.com/ws%3A%2F%2Flocalhost%3A7334/my-local-only-repo';
    my $result = Net::Nostr::Git->parse_nostr_clone_url($url);
    is $result->{owner}, 'danconwaydev.com', 'NIP-05 owner';
    is $result->{relay_hint}, 'ws://localhost:7334', 'ws:// relay';
    is $result->{identifier}, 'my-local-only-repo', 'identifier';
};

subtest 'spec example: nip05 with relay and identifier' => sub {
    my $url = 'nostr://danconwaydev.com/relay.ngit.dev/ngit';
    my $result = Net::Nostr::Git->parse_nostr_clone_url($url);
    is $result->{owner}, 'danconwaydev.com', 'NIP-05 owner';
    is $result->{relay_hint}, 'wss://relay.ngit.dev', 'relay_hint';
    is $result->{identifier}, 'ngit', 'identifier';
};

subtest 'round-trip: nostr_clone_url then parse (naddr)' => sub {
    my $naddr = encode_naddr(
        identifier => 'test-repo',
        pubkey     => $my_pubkey,
        kind       => 30617,
        relays     => ['wss://relay.example.com'],
    );
    my $url = Net::Nostr::Git->nostr_clone_url(naddr => $naddr);
    my $result = Net::Nostr::Git->parse_nostr_clone_url($url);
    is $result->{identifier}, 'test-repo', 'identifier round-trips';
    is $result->{pubkey}, $my_pubkey, 'pubkey round-trips';
    is $result->{kind}, 30617, 'kind round-trips';
};

subtest 'round-trip: nostr_clone_url then parse (owner with relay)' => sub {
    my $url = Net::Nostr::Git->nostr_clone_url(
        owner      => $npub,
        relay_hint => 'wss://relay.example.com',
        identifier => 'my project',
    );
    my $result = Net::Nostr::Git->parse_nostr_clone_url($url);
    is $result->{owner}, $npub, 'owner round-trips';
    is $result->{relay_hint}, 'wss://relay.example.com', 'relay_hint round-trips';
    is $result->{identifier}, 'my project', 'identifier round-trips with space';
};

subtest 'round-trip: nostr_clone_url then parse (owner without relay)' => sub {
    my $url = Net::Nostr::Git->nostr_clone_url(
        owner      => $npub,
        identifier => 'simple-repo',
    );
    my $result = Net::Nostr::Git->parse_nostr_clone_url($url);
    is $result->{owner}, $npub, 'owner round-trips';
    ok !exists $result->{relay_hint}, 'no relay_hint';
    is $result->{identifier}, 'simple-repo', 'identifier round-trips';
};

subtest 'round-trip: nostr_clone_url then parse (non-wss relay)' => sub {
    my $url = Net::Nostr::Git->nostr_clone_url(
        owner      => 'user@example.com',
        relay_hint => 'ws://localhost:7334',
        identifier => 'local-repo',
    );
    my $result = Net::Nostr::Git->parse_nostr_clone_url($url);
    is $result->{relay_hint}, 'ws://localhost:7334', 'ws:// relay round-trips';
    is $result->{identifier}, 'local-repo', 'identifier round-trips';
};

subtest 'parse_nostr_clone_url rejects invalid input' => sub {
    like dies { Net::Nostr::Git->parse_nostr_clone_url(undef) },
        qr/nostr:\/\/ URL required/, 'undef';
    like dies { Net::Nostr::Git->parse_nostr_clone_url('https://example.com') },
        qr/nostr:\/\/ URL required/, 'wrong scheme';
    like dies { Net::Nostr::Git->parse_nostr_clone_url('nostr://') },
        qr/nostr:\/\/ URL required/, 'empty path';
    like dies { Net::Nostr::Git->parse_nostr_clone_url('nostr://owner') },
        qr/identifier/, 'missing identifier';
};

done_testing;
