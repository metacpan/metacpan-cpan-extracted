#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Git;

my $my_pubkey = 'a' x 64;
my $owner_pk  = 'b' x 64;
my $author_pk = 'c' x 64;

my $commit_id     = 'abc123' . ('0' x 58);
my $tag_commit_id = 'def456' . ('0' x 58);
my $tip_commit_id = 'ghi789' . ('0' x 58);

my $new_tip_commit_id = 'jkl012' . ('0' x 58);

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

done_testing;
