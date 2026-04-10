#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Git;

my $alice_pk = 'a' x 64;
my $bob_pk   = 'b' x 64;
my $carol_pk = 'c' x 64;

my $event_id  = '1' x 64;
my $event_id2 = '2' x 64;
my $event_id3 = '3' x 64;

my $commit_id  = 'abc123' . ('0' x 58);
my $commit_id2 = 'def456' . ('0' x 58);
my $commit_id3 = 'ghi789' . ('0' x 58);

###############################################################################
# Repository announcements (kind 30617)
###############################################################################

subtest 'repository: kind 30617' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey => $alice_pk,
        id     => 'my-project',
    );
    is $repo->kind, 30617, 'kind 30617';
};

subtest 'repository: is addressable' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey => $alice_pk,
        id     => 'my-project',
    );
    ok $repo->is_addressable, 'addressable event';
};

subtest 'repository: d tag required' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey => $alice_pk,
        id     => 'my-project',
    );
    my @d = grep { $_->[0] eq 'd' } @{$repo->tags};
    is scalar @d, 1, 'has d tag';
    is $d[0][1], 'my-project', 'd tag value is repo id';
};

subtest 'repository: d tag is only required tag' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey => $alice_pk,
        id     => 'my-project',
    );
    # Only d tag should be present when no optional tags given
    is scalar @{$repo->tags}, 1, 'only d tag';
};

subtest 'repository: name tag' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey => $alice_pk,
        id     => 'my-project',
        name   => 'My Project',
    );
    my @n = grep { $_->[0] eq 'name' } @{$repo->tags};
    is $n[0][1], 'My Project', 'name tag value';
};

subtest 'repository: description tag' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey      => $alice_pk,
        id          => 'my-project',
        description => 'A great project',
    );
    my @desc = grep { $_->[0] eq 'description' } @{$repo->tags};
    is $desc[0][1], 'A great project', 'description tag value';
};

subtest 'repository: web tags (multiple values)' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey => $alice_pk,
        id     => 'my-project',
        web    => ['https://git.example.com/repo', 'https://github.com/repo'],
    );
    my @w = grep { $_->[0] eq 'web' } @{$repo->tags};
    is scalar @w, 1, 'single web tag with multiple values';
    is $w[0][1], 'https://git.example.com/repo', 'first web url';
    is $w[0][2], 'https://github.com/repo', 'second web url';
};

subtest 'repository: clone tags (multiple values)' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey => $alice_pk,
        id     => 'my-project',
        clone  => ['https://git.example.com/repo.git', 'git@github.com:user/repo.git'],
    );
    my @c = grep { $_->[0] eq 'clone' } @{$repo->tags};
    is scalar @c, 1, 'single clone tag';
    is $c[0][1], 'https://git.example.com/repo.git', 'first clone url';
    is $c[0][2], 'git@github.com:user/repo.git', 'second clone url';
};

subtest 'repository: relays tags (multiple values)' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey => $alice_pk,
        id     => 'my-project',
        relays => ['wss://relay1.example.com', 'wss://relay2.example.com'],
    );
    my @r = grep { $_->[0] eq 'relays' } @{$repo->tags};
    is scalar @r, 1, 'single relays tag';
    is $r[0][1], 'wss://relay1.example.com', 'first relay';
    is $r[0][2], 'wss://relay2.example.com', 'second relay';
};

subtest 'repository: r tag with euc marker' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey              => $alice_pk,
        id                  => 'my-project',
        earliest_unique_commit => $commit_id,
    );
    my @r = grep { $_->[0] eq 'r' } @{$repo->tags};
    is scalar @r, 1, 'has r tag';
    is $r[0][1], $commit_id, 'r tag commit id';
    is $r[0][2], 'euc', 'r tag has euc marker';
};

subtest 'repository: maintainers tag' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey      => $alice_pk,
        id          => 'my-project',
        maintainers => [$bob_pk, $carol_pk],
    );
    my @m = grep { $_->[0] eq 'maintainers' } @{$repo->tags};
    is scalar @m, 1, 'single maintainers tag';
    is $m[0][1], $bob_pk, 'first maintainer';
    is $m[0][2], $carol_pk, 'second maintainer';
};

subtest 'repository: personal-fork t tag' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey        => $alice_pk,
        id            => 'my-fork',
        personal_fork => 1,
    );
    my @t = grep { $_->[0] eq 't' && $_->[1] eq 'personal-fork' } @{$repo->tags};
    is scalar @t, 1, 'has personal-fork t tag';
};

subtest 'repository: hashtag t tags' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey   => $alice_pk,
        id       => 'my-project',
        hashtags => ['nostr', 'perl'],
    );
    my @t = grep { $_->[0] eq 't' } @{$repo->tags};
    is scalar @t, 2, 'two t tags';
    is $t[0][1], 'nostr', 'first hashtag';
    is $t[1][1], 'perl', 'second hashtag';
};

subtest 'repository: content is empty string' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey => $alice_pk,
        id     => 'my-project',
    );
    is $repo->content, '', 'content is empty';
};

subtest 'repository: all optional tags together' => sub {
    my $repo = Net::Nostr::Git->repository(
        pubkey              => $alice_pk,
        id                  => 'my-project',
        name                => 'My Project',
        description         => 'A project',
        web                 => ['https://example.com'],
        clone               => ['https://example.com/repo.git'],
        relays              => ['wss://relay.example.com'],
        earliest_unique_commit => $commit_id,
        maintainers         => [$bob_pk],
        personal_fork       => 1,
        hashtags            => ['test'],
    );
    is $repo->kind, 30617, 'kind';
    my @tags = @{$repo->tags};
    my %seen = map { $_->[0] => 1 } @tags;
    ok $seen{d}, 'has d';
    ok $seen{name}, 'has name';
    ok $seen{description}, 'has description';
    ok $seen{web}, 'has web';
    ok $seen{clone}, 'has clone';
    ok $seen{relays}, 'has relays';
    ok $seen{r}, 'has r';
    ok $seen{maintainers}, 'has maintainers';
    ok $seen{t}, 'has t';
};

subtest 'repository: requires id' => sub {
    ok dies { Net::Nostr::Git->repository(pubkey => $alice_pk) },
        'croaks without id';
};

subtest 'repository: requires pubkey' => sub {
    ok dies { Net::Nostr::Git->repository(id => 'test') },
        'croaks without pubkey';
};

###############################################################################
# Repository state announcements (kind 30618)
###############################################################################

subtest 'repository_state: kind 30618' => sub {
    my $state = Net::Nostr::Git->repository_state(
        pubkey => $alice_pk,
        id     => 'my-project',
    );
    is $state->kind, 30618, 'kind 30618';
};

subtest 'repository_state: is addressable' => sub {
    my $state = Net::Nostr::Git->repository_state(
        pubkey => $alice_pk,
        id     => 'my-project',
    );
    ok $state->is_addressable, 'addressable event';
};

subtest 'repository_state: d tag matches repo id' => sub {
    my $state = Net::Nostr::Git->repository_state(
        pubkey => $alice_pk,
        id     => 'my-project',
    );
    is $state->d_tag, 'my-project', 'd tag matches repo id';
};

subtest 'repository_state: refs tags' => sub {
    my $state = Net::Nostr::Git->repository_state(
        pubkey => $alice_pk,
        id     => 'my-project',
        refs   => [
            ['refs/heads/main', $commit_id],
            ['refs/heads/dev',  $commit_id2],
            ['refs/tags/v1.0',  $commit_id3],
        ],
    );
    my @refs = grep { $_->[0] =~ m{^refs/} } @{$state->tags};
    is scalar @refs, 3, 'three refs tags';
    is $refs[0][0], 'refs/heads/main', 'first ref name';
    is $refs[0][1], $commit_id, 'first ref commit';
    is $refs[2][0], 'refs/tags/v1.0', 'tag ref';
};

subtest 'repository_state: no refs tags means stopped tracking' => sub {
    my $state = Net::Nostr::Git->repository_state(
        pubkey => $alice_pk,
        id     => 'my-project',
    );
    my @refs = grep { $_->[0] =~ m{^refs/} } @{$state->tags};
    is scalar @refs, 0, 'no refs tags';
};

subtest 'repository_state: HEAD tag' => sub {
    my $state = Net::Nostr::Git->repository_state(
        pubkey => $alice_pk,
        id     => 'my-project',
        head   => 'main',
    );
    my @h = grep { $_->[0] eq 'HEAD' } @{$state->tags};
    is scalar @h, 1, 'has HEAD tag';
    is $h[0][1], 'ref: refs/heads/main', 'HEAD value';
};

subtest 'repository_state: refs with ancestor commit ids (MAY)' => sub {
    my $state = Net::Nostr::Git->repository_state(
        pubkey => $alice_pk,
        id     => 'my-project',
        refs   => [
            ['refs/heads/main', $commit_id, 'abc1234', 'def5678'],
        ],
    );
    my @refs = grep { $_->[0] eq 'refs/heads/main' } @{$state->tags};
    is scalar @{$refs[0]}, 4, 'ref tag has 4 elements (name, commit, parent, grandparent)';
    is $refs[0][2], 'abc1234', 'shorthand parent commit';
    is $refs[0][3], 'def5678', 'shorthand grandparent commit';
};

subtest 'repository_state: content is empty' => sub {
    my $state = Net::Nostr::Git->repository_state(
        pubkey => $alice_pk,
        id     => 'my-project',
    );
    is $state->content, '', 'empty content';
};

###############################################################################
# Patches (kind 1617)
###############################################################################

my $patch_content = <<'PATCH';
From abc123 Mon Sep 17 00:00:00 2001
From: Alice <alice@example.com>
Date: Mon, 1 Jan 2024 00:00:00 +0000
Subject: Fix bug

---
 lib/Foo.pm | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
PATCH

my $repo_coord = "30617:${alice_pk}:my-project";

subtest 'patch: kind 1617' => sub {
    my $patch = Net::Nostr::Git->patch(
        pubkey     => $bob_pk,
        content    => $patch_content,
        repository => $repo_coord,
    );
    is $patch->kind, 1617, 'kind 1617';
};

subtest 'patch: a tag points to repository' => sub {
    my $patch = Net::Nostr::Git->patch(
        pubkey     => $bob_pk,
        content    => $patch_content,
        repository => $repo_coord,
    );
    my @a = grep { $_->[0] eq 'a' } @{$patch->tags};
    is $a[0][1], $repo_coord, 'a tag has repo coordinate';
};

subtest 'patch: r tag for earliest unique commit' => sub {
    my $patch = Net::Nostr::Git->patch(
        pubkey              => $bob_pk,
        content             => $patch_content,
        repository          => $repo_coord,
        earliest_unique_commit => $commit_id,
    );
    my @r = grep { $_->[0] eq 'r' && $_->[1] eq $commit_id } @{$patch->tags};
    is scalar @r, 1, 'has r tag for euc';
};

subtest 'patch: p tags for repo owner and others' => sub {
    my $patch = Net::Nostr::Git->patch(
        pubkey       => $bob_pk,
        content      => $patch_content,
        repository   => $repo_coord,
        repo_owner   => $alice_pk,
        notify       => [$carol_pk],
    );
    my @p = grep { $_->[0] eq 'p' } @{$patch->tags};
    is scalar @p, 2, 'two p tags';
    is $p[0][1], $alice_pk, 'repo owner p tag';
    is $p[1][1], $carol_pk, 'notify p tag';
};

subtest 'patch: root tag for first patch in series' => sub {
    my $patch = Net::Nostr::Git->patch(
        pubkey     => $bob_pk,
        content    => $patch_content,
        repository => $repo_coord,
        root       => 1,
    );
    my @t = grep { $_->[0] eq 't' && $_->[1] eq 'root' } @{$patch->tags};
    is scalar @t, 1, 'has root t tag';
};

subtest 'patch: root-revision tag' => sub {
    my $patch = Net::Nostr::Git->patch(
        pubkey        => $bob_pk,
        content       => $patch_content,
        repository    => $repo_coord,
        root_revision => 1,
    );
    my @t = grep { $_->[0] eq 't' && $_->[1] eq 'root-revision' } @{$patch->tags};
    is scalar @t, 1, 'has root-revision t tag';
};

subtest 'patch: no root tag for non-root patches' => sub {
    my $patch = Net::Nostr::Git->patch(
        pubkey     => $bob_pk,
        content    => $patch_content,
        repository => $repo_coord,
    );
    my @t = grep { $_->[0] eq 't' && $_->[1] eq 'root' } @{$patch->tags};
    is scalar @t, 0, 'no root tag';
};

subtest 'patch: commit metadata tags (MAY)' => sub {
    my $patch = Net::Nostr::Git->patch(
        pubkey        => $bob_pk,
        content       => $patch_content,
        repository    => $repo_coord,
        commit        => $commit_id,
        parent_commit => $commit_id2,
        commit_pgp_sig => '-----BEGIN PGP SIGNATURE-----...',
        committer     => ['Alice', 'alice@example.com', '1704067200', '+0000'],
    );
    my @commit = grep { $_->[0] eq 'commit' } @{$patch->tags};
    is $commit[0][1], $commit_id, 'commit tag';

    # r tag for current commit id
    my @r = grep { $_->[0] eq 'r' && $_->[1] eq $commit_id } @{$patch->tags};
    is scalar @r, 1, 'r tag for commit id';

    my @parent = grep { $_->[0] eq 'parent-commit' } @{$patch->tags};
    is $parent[0][1], $commit_id2, 'parent-commit tag';

    my @pgp = grep { $_->[0] eq 'commit-pgp-sig' } @{$patch->tags};
    is $pgp[0][1], '-----BEGIN PGP SIGNATURE-----...', 'pgp sig tag';

    my @cm = grep { $_->[0] eq 'committer' } @{$patch->tags};
    is $cm[0][1], 'Alice', 'committer name';
    is $cm[0][2], 'alice@example.com', 'committer email';
    is $cm[0][3], '1704067200', 'committer timestamp';
    is $cm[0][4], '+0000', 'committer timezone';
};

subtest 'patch: NIP-10 e reply tag for patch series (SHOULD)' => sub {
    my $patch = Net::Nostr::Git->patch(
        pubkey              => $bob_pk,
        content             => $patch_content,
        repository          => $repo_coord,
        previous_patch      => $event_id,
        previous_patch_relay => 'wss://relay.example.com',
    );
    my @e = grep { $_->[0] eq 'e' } @{$patch->tags};
    is scalar @e, 1, 'has e tag';
    is $e[0][1], $event_id, 'e tag points to previous patch';
    is $e[0][2], 'wss://relay.example.com', 'e tag relay hint';
    is $e[0][3], 'reply', 'e tag has NIP-10 reply marker';
};

subtest 'patch: content is git format-patch output' => sub {
    my $patch = Net::Nostr::Git->patch(
        pubkey     => $bob_pk,
        content    => $patch_content,
        repository => $repo_coord,
    );
    is $patch->content, $patch_content, 'content is patch text';
};

subtest 'patch: first patch revision SHOULD e reply to original root (SHOULD)' => sub {
    my $patch = Net::Nostr::Git->patch(
        pubkey         => $bob_pk,
        content        => $patch_content,
        repository     => $repo_coord,
        root_revision  => 1,
        previous_patch => $event_id,
    );
    my @e = grep { $_->[0] eq 'e' } @{$patch->tags};
    is scalar @e, 1, 'has e reply tag';
    is $e[0][1], $event_id, 'points to original root patch';
    is $e[0][3], 'reply', 'e tag has NIP-10 reply marker';
    my @t = grep { $_->[0] eq 't' && $_->[1] eq 'root-revision' } @{$patch->tags};
    is scalar @t, 1, 'has root-revision tag';
};

subtest 'patch: first patch MAY be a cover letter' => sub {
    # Spec: "The first patch in a series MAY be a cover letter in the format
    # produced by git format-patch."
    my $cover_letter = <<'COVER';
From 0000000000000000000000000000000000000000 Mon Sep 17 00:00:00 2001
From: Alice <alice@example.com>
Date: Mon, 1 Jan 2024 00:00:00 +0000
Subject: [PATCH 0/3] Fix parsing bugs

This patch series fixes several parsing bugs.

Alice (3):
  Fix tokenizer edge case
  Handle empty input
  Add regression tests
COVER
    my $patch = Net::Nostr::Git->patch(
        pubkey     => $bob_pk,
        content    => $cover_letter,
        repository => $repo_coord,
        root       => 1,
    );
    is $patch->kind, 1617, 'cover letter is still kind 1617';
    is $patch->content, $cover_letter, 'cover letter content preserved';
    my @t = grep { $_->[0] eq 't' && $_->[1] eq 'root' } @{$patch->tags};
    is scalar @t, 1, 'cover letter can be root patch';
};

###############################################################################
# Pull Requests (kind 1618)
###############################################################################

subtest 'pull_request: kind 1618' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey     => $bob_pk,
        content    => 'Please merge this feature.',
        repository => $repo_coord,
        subject    => 'Add feature X',
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
    );
    is $pr->kind, 1618, 'kind 1618';
};

subtest 'pull_request: a tag points to repository' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey     => $bob_pk,
        content    => 'Merge this',
        repository => $repo_coord,
        subject    => 'Feature',
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
    );
    my @a = grep { $_->[0] eq 'a' } @{$pr->tags};
    is $a[0][1], $repo_coord, 'a tag repo coordinate';
};

subtest 'pull_request: r tag for earliest unique commit' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey              => $bob_pk,
        content             => 'Merge',
        repository          => $repo_coord,
        subject             => 'Feature',
        commit              => $commit_id,
        clone               => ['https://example.com/fork.git'],
        earliest_unique_commit => $commit_id2,
    );
    my @r = grep { $_->[0] eq 'r' && $_->[1] eq $commit_id2 } @{$pr->tags};
    is scalar @r, 1, 'r tag for euc';
};

subtest 'pull_request: p tags' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey     => $bob_pk,
        content    => 'Merge',
        repository => $repo_coord,
        subject    => 'Feature',
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
        repo_owner => $alice_pk,
        notify     => [$carol_pk],
    );
    my @p = grep { $_->[0] eq 'p' } @{$pr->tags};
    is $p[0][1], $alice_pk, 'repo owner';
    is $p[1][1], $carol_pk, 'notify user';
};

subtest 'pull_request: subject tag' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey     => $bob_pk,
        content    => 'Merge',
        repository => $repo_coord,
        subject    => 'Add feature X',
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
    );
    my @s = grep { $_->[0] eq 'subject' } @{$pr->tags};
    is $s[0][1], 'Add feature X', 'subject tag';
};

subtest 'pull_request: t tags for labels (optional)' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey     => $bob_pk,
        content    => 'Merge',
        repository => $repo_coord,
        subject    => 'Feature',
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
        labels     => ['enhancement', 'urgent'],
    );
    my @t = grep { $_->[0] eq 't' } @{$pr->tags};
    is scalar @t, 2, 'two label tags';
    is $t[0][1], 'enhancement', 'first label';
    is $t[1][1], 'urgent', 'second label';
};

subtest 'pull_request: c tag for tip commit' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey     => $bob_pk,
        content    => 'Merge',
        repository => $repo_coord,
        subject    => 'Feature',
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
    );
    my @c = grep { $_->[0] eq 'c' } @{$pr->tags};
    is $c[0][1], $commit_id, 'c tag commit id';
};

subtest 'pull_request: clone tags' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey     => $bob_pk,
        content    => 'Merge',
        repository => $repo_coord,
        subject    => 'Feature',
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git', 'git@github.com:user/fork.git'],
    );
    my @cl = grep { $_->[0] eq 'clone' } @{$pr->tags};
    is $cl[0][1], 'https://example.com/fork.git', 'first clone url';
    is $cl[0][2], 'git@github.com:user/fork.git', 'second clone url';
};

subtest 'pull_request: branch-name tag (optional)' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey      => $bob_pk,
        content     => 'Merge',
        repository  => $repo_coord,
        subject     => 'Feature',
        commit      => $commit_id,
        clone       => ['https://example.com/fork.git'],
        branch_name => 'feature-x',
    );
    my @b = grep { $_->[0] eq 'branch-name' } @{$pr->tags};
    is $b[0][1], 'feature-x', 'branch-name tag';
};

subtest 'pull_request: e tag for patch revision (optional)' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey     => $bob_pk,
        content    => 'Revision of patch',
        repository => $repo_coord,
        subject    => 'Feature',
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
        revises    => $event_id,
    );
    my @e = grep { $_->[0] eq 'e' } @{$pr->tags};
    is $e[0][1], $event_id, 'e tag for revised patch';
};

subtest 'pull_request: merge-base tag (optional)' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey     => $bob_pk,
        content    => 'Merge',
        repository => $repo_coord,
        subject    => 'Feature',
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
        merge_base => $commit_id2,
    );
    my @mb = grep { $_->[0] eq 'merge-base' } @{$pr->tags};
    is $mb[0][1], $commit_id2, 'merge-base tag';
};

subtest 'pull_request: content is markdown' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey     => $bob_pk,
        content    => '## Changes\n\n- Added feature X',
        repository => $repo_coord,
        subject    => 'Feature',
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
    );
    is $pr->content, '## Changes\n\n- Added feature X', 'markdown content';
};

subtest 'pull_request: requires commit' => sub {
    ok dies {
        Net::Nostr::Git->pull_request(
            pubkey     => $bob_pk,
            content    => 'Merge',
            repository => $repo_coord,
            subject    => 'Feature',
            clone      => ['https://example.com/fork.git'],
        )
    }, 'croaks without commit';
};

subtest 'pull_request: requires clone' => sub {
    ok dies {
        Net::Nostr::Git->pull_request(
            pubkey     => $bob_pk,
            content    => 'Merge',
            repository => $repo_coord,
            subject    => 'Feature',
            commit     => $commit_id,
        )
    }, 'croaks without clone';
};

###############################################################################
# Pull Request Updates (kind 1619)
###############################################################################

subtest 'pull_request_update: kind 1619' => sub {
    my $update = Net::Nostr::Git->pull_request_update(
        pubkey     => $bob_pk,
        repository => $repo_coord,
        pr_event   => $event_id,
        pr_author  => $alice_pk,
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
    );
    is $update->kind, 1619, 'kind 1619';
};

subtest 'pull_request_update: a tag' => sub {
    my $update = Net::Nostr::Git->pull_request_update(
        pubkey     => $bob_pk,
        repository => $repo_coord,
        pr_event   => $event_id,
        pr_author  => $alice_pk,
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
    );
    my @a = grep { $_->[0] eq 'a' } @{$update->tags};
    is $a[0][1], $repo_coord, 'a tag';
};

subtest 'pull_request_update: NIP-22 E and P tags' => sub {
    my $update = Net::Nostr::Git->pull_request_update(
        pubkey     => $bob_pk,
        repository => $repo_coord,
        pr_event   => $event_id,
        pr_author  => $alice_pk,
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
    );
    my @E = grep { $_->[0] eq 'E' } @{$update->tags};
    is $E[0][1], $event_id, 'E tag points to PR event';
    my @P = grep { $_->[0] eq 'P' } @{$update->tags};
    is $P[0][1], $alice_pk, 'P tag has PR author';
};

subtest 'pull_request_update: c tag for updated tip' => sub {
    my $update = Net::Nostr::Git->pull_request_update(
        pubkey     => $bob_pk,
        repository => $repo_coord,
        pr_event   => $event_id,
        pr_author  => $alice_pk,
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
    );
    my @c = grep { $_->[0] eq 'c' } @{$update->tags};
    is $c[0][1], $commit_id, 'c tag';
};

subtest 'pull_request_update: clone tags' => sub {
    my $update = Net::Nostr::Git->pull_request_update(
        pubkey     => $bob_pk,
        repository => $repo_coord,
        pr_event   => $event_id,
        pr_author  => $alice_pk,
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
    );
    my @cl = grep { $_->[0] eq 'clone' } @{$update->tags};
    is $cl[0][1], 'https://example.com/fork.git', 'clone tag';
};

subtest 'pull_request_update: merge-base (optional)' => sub {
    my $update = Net::Nostr::Git->pull_request_update(
        pubkey     => $bob_pk,
        repository => $repo_coord,
        pr_event   => $event_id,
        pr_author  => $alice_pk,
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
        merge_base => $commit_id2,
    );
    my @mb = grep { $_->[0] eq 'merge-base' } @{$update->tags};
    is $mb[0][1], $commit_id2, 'merge-base tag';
};

subtest 'pull_request_update: r tag for euc' => sub {
    my $update = Net::Nostr::Git->pull_request_update(
        pubkey              => $bob_pk,
        repository          => $repo_coord,
        pr_event            => $event_id,
        pr_author           => $alice_pk,
        commit              => $commit_id,
        clone               => ['https://example.com/fork.git'],
        earliest_unique_commit => $commit_id2,
    );
    my @r = grep { $_->[0] eq 'r' && $_->[1] eq $commit_id2 } @{$update->tags};
    is scalar @r, 1, 'r tag for euc';
};

subtest 'pull_request_update: p tags for repo owner and notify' => sub {
    my $update = Net::Nostr::Git->pull_request_update(
        pubkey     => $bob_pk,
        repository => $repo_coord,
        pr_event   => $event_id,
        pr_author  => $alice_pk,
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
        repo_owner => $alice_pk,
        notify     => [$carol_pk],
    );
    my @p = grep { $_->[0] eq 'p' } @{$update->tags};
    is $p[0][1], $alice_pk, 'repo owner p tag';
    is $p[1][1], $carol_pk, 'notify p tag';
};

subtest 'pull_request_update: content is empty' => sub {
    my $update = Net::Nostr::Git->pull_request_update(
        pubkey     => $bob_pk,
        repository => $repo_coord,
        pr_event   => $event_id,
        pr_author  => $alice_pk,
        commit     => $commit_id,
        clone      => ['https://example.com/fork.git'],
    );
    is $update->content, '', 'empty content';
};

###############################################################################
# Issues (kind 1621)
###############################################################################

subtest 'issue: kind 1621' => sub {
    my $issue = Net::Nostr::Git->issue(
        pubkey     => $bob_pk,
        content    => 'Found a bug in parsing.',
        repository => $repo_coord,
    );
    is $issue->kind, 1621, 'kind 1621';
};

subtest 'issue: a tag points to repository' => sub {
    my $issue = Net::Nostr::Git->issue(
        pubkey     => $bob_pk,
        content    => 'Bug report',
        repository => $repo_coord,
    );
    my @a = grep { $_->[0] eq 'a' } @{$issue->tags};
    is $a[0][1], $repo_coord, 'a tag';
};

subtest 'issue: p tag for repo owner' => sub {
    my $issue = Net::Nostr::Git->issue(
        pubkey     => $bob_pk,
        content    => 'Bug',
        repository => $repo_coord,
        repo_owner => $alice_pk,
    );
    my @p = grep { $_->[0] eq 'p' } @{$issue->tags};
    is $p[0][1], $alice_pk, 'p tag';
};

subtest 'issue: subject tag (MAY)' => sub {
    my $issue = Net::Nostr::Git->issue(
        pubkey     => $bob_pk,
        content    => 'Details here',
        repository => $repo_coord,
        subject    => 'Crash on startup',
    );
    my @s = grep { $_->[0] eq 'subject' } @{$issue->tags};
    is $s[0][1], 'Crash on startup', 'subject tag';
};

subtest 'issue: t tags for labels (MAY)' => sub {
    my $issue = Net::Nostr::Git->issue(
        pubkey     => $bob_pk,
        content    => 'Details',
        repository => $repo_coord,
        labels     => ['bug', 'critical'],
    );
    my @t = grep { $_->[0] eq 't' } @{$issue->tags};
    is scalar @t, 2, 'two label tags';
    is $t[0][1], 'bug', 'first label';
    is $t[1][1], 'critical', 'second label';
};

subtest 'issue: content is markdown' => sub {
    my $issue = Net::Nostr::Git->issue(
        pubkey     => $bob_pk,
        content    => '## Bug\n\nSteps to reproduce...',
        repository => $repo_coord,
    );
    is $issue->content, '## Bug\n\nSteps to reproduce...', 'markdown content';
};

###############################################################################
# Replies follow NIP-22 comment
###############################################################################

subtest 'replies: spec says replies to issues/patches/PRs follow NIP-22' => sub {
    # This is a cross-NIP requirement: replies to kind 1621 (issue),
    # kind 1617 (patch), kind 1618 (PR) should use NIP-22 Comment.
    # Verify Net::Nostr::Comment->comment works with these kinds.
    require Net::Nostr::Comment;

    my $issue = make_event(
        id => $event_id, pubkey => $bob_pk, kind => 1621,
        content => 'Bug report',
        tags => [['a', $repo_coord], ['p', $alice_pk]],
    );
    my $reply = Net::Nostr::Comment->comment(
        event   => $issue,
        pubkey  => $carol_pk,
        content => 'I can reproduce this.',
    );
    is $reply->kind, 1111, 'reply to issue is NIP-22 comment';
    my @K = grep { $_->[0] eq 'K' } @{$reply->tags};
    is $K[0][1], '1621', 'root kind is issue kind';
};

subtest 'replies: comment on patch' => sub {
    require Net::Nostr::Comment;
    my $patch = make_event(
        id => $event_id, pubkey => $bob_pk, kind => 1617,
        content => $patch_content,
    );
    my $reply = Net::Nostr::Comment->comment(
        event   => $patch,
        pubkey  => $carol_pk,
        content => 'Looks good!',
    );
    is $reply->kind, 1111, 'reply to patch is NIP-22 comment';
    my @K = grep { $_->[0] eq 'K' } @{$reply->tags};
    is $K[0][1], '1617', 'root kind is patch kind';
};

subtest 'replies: comment on pull request' => sub {
    require Net::Nostr::Comment;
    my $pr = make_event(
        id => $event_id, pubkey => $bob_pk, kind => 1618,
        content => 'PR text',
    );
    my $reply = Net::Nostr::Comment->comment(
        event   => $pr,
        pubkey  => $carol_pk,
        content => 'Please add tests.',
    );
    is $reply->kind, 1111, 'reply to PR is NIP-22 comment';
    my @K = grep { $_->[0] eq 'K' } @{$reply->tags};
    is $K[0][1], '1618', 'root kind is PR kind';
};

###############################################################################
# Status events (kinds 1630-1633)
###############################################################################

subtest 'status: kind 1630 (Open)' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'open',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
    );
    is $status->kind, 1630, 'kind 1630 for open';
};

subtest 'status: kind 1631 (Applied/Merged/Resolved)' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'applied',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
    );
    is $status->kind, 1631, 'kind 1631 for applied';
};

subtest 'status: kind 1632 (Closed)' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'closed',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
    );
    is $status->kind, 1632, 'kind 1632 for closed';
};

subtest 'status: kind 1633 (Draft)' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'draft',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
    );
    is $status->kind, 1633, 'kind 1633 for draft';
};

subtest 'status: e root tag for target' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'open',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
    );
    my @e = grep { $_->[0] eq 'e' && defined $_->[3] && $_->[3] eq 'root' } @{$status->tags};
    is scalar @e, 1, 'has e root tag';
    is $e[0][1], $event_id, 'e root tag event id';
};

subtest 'status: e reply tag for accepted revision' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'applied',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
        accepted_revision => $event_id2,
    );
    my @e = grep { $_->[0] eq 'e' && defined $_->[3] && $_->[3] eq 'reply' } @{$status->tags};
    is scalar @e, 1, 'has e reply tag';
    is $e[0][1], $event_id2, 'e reply tag revision id';
};

subtest 'status: p tags for repo owner, root event author, revision author' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'applied',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
        revision_author => $carol_pk,
    );
    my @p = grep { $_->[0] eq 'p' } @{$status->tags};
    is scalar @p, 3, 'three p tags';
    is $p[0][1], $alice_pk, 'repo owner';
    is $p[1][1], $bob_pk, 'root event author';
    is $p[2][1], $carol_pk, 'revision author';
};

subtest 'status: optional a tag for filter efficiency' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'open',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
        repository => $repo_coord,
        repository_relay => 'wss://relay.example.com',
    );
    my @a = grep { $_->[0] eq 'a' } @{$status->tags};
    is $a[0][1], $repo_coord, 'a tag';
    is $a[0][2], 'wss://relay.example.com', 'a tag relay hint';
};

subtest 'status: optional r tag for euc' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'open',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
        earliest_unique_commit => $commit_id,
    );
    my @r = grep { $_->[0] eq 'r' && $_->[1] eq $commit_id } @{$status->tags};
    is scalar @r, 1, 'r tag for euc';
};

subtest 'status: 1631 q tags for applied/merged patches (optional)' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'applied',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
        applied_patches => [
            { id => $event_id2, relay_url => 'wss://relay.com', pubkey => $bob_pk },
        ],
    );
    my @q = grep { $_->[0] eq 'q' } @{$status->tags};
    is scalar @q, 1, 'has q tag';
    is $q[0][1], $event_id2, 'q tag event id';
    is $q[0][2], 'wss://relay.com', 'q tag relay';
    is $q[0][3], $bob_pk, 'q tag pubkey';
};

subtest 'status: 1631 multiple q tags ("for each")' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'applied',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
        applied_patches => [
            { id => $event_id2, relay_url => 'wss://relay.com', pubkey => $bob_pk },
            { id => $event_id3, relay_url => 'wss://relay2.com', pubkey => $carol_pk },
        ],
    );
    my @q = grep { $_->[0] eq 'q' } @{$status->tags};
    is scalar @q, 2, 'two q tags';
    is $q[0][1], $event_id2, 'first q tag event id';
    is $q[1][1], $event_id3, 'second q tag event id';
    is $q[1][2], 'wss://relay2.com', 'second q tag relay';
    is $q[1][3], $carol_pk, 'second q tag pubkey';
};

subtest 'status: 1631 merge-commit tag (optional)' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'applied',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
        merge_commit => $commit_id,
    );
    my @mc = grep { $_->[0] eq 'merge-commit' } @{$status->tags};
    is $mc[0][1], $commit_id, 'merge-commit tag';
    # Also r tag for merge commit
    my @r = grep { $_->[0] eq 'r' && $_->[1] eq $commit_id } @{$status->tags};
    is scalar @r, 1, 'r tag for merge commit';
};

subtest 'status: 1631 applied-as-commits tag (optional)' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'applied',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
        applied_as_commits => [$commit_id, $commit_id2],
    );
    my @ac = grep { $_->[0] eq 'applied-as-commits' } @{$status->tags};
    is $ac[0][1], $commit_id, 'first applied commit';
    is $ac[0][2], $commit_id2, 'second applied commit';
    # r tags for each applied commit
    my @r = grep { $_->[0] eq 'r' } @{$status->tags};
    is scalar @r, 2, 'r tags for each applied commit';
};

subtest 'status: content is markdown' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'closed',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
        content    => 'Closing as wontfix.',
    );
    is $status->content, 'Closing as wontfix.', 'markdown content';
};

subtest 'status: merged and resolved are aliases for 1631' => sub {
    for my $name ('merged', 'resolved') {
        my $status = Net::Nostr::Git->status(
            pubkey        => $alice_pk,
            status        => $name,
            target        => $event_id,
            repo_owner    => $alice_pk,
            target_author => $bob_pk,
        );
        is $status->kind, 1631, "$name maps to kind 1631";
    }
};

subtest 'status: default content is empty string' => sub {
    my $status = Net::Nostr::Git->status(
        pubkey        => $alice_pk,
        status        => 'open',
        target        => $event_id,
        repo_owner    => $alice_pk,
        target_author => $bob_pk,
    );
    is $status->content, '', 'default content is empty';
};

subtest 'status: invalid status name' => sub {
    ok dies {
        Net::Nostr::Git->status(
            pubkey     => $alice_pk,
            status     => 'invalid',
            target     => $event_id,
            repo_owner => $alice_pk,
            target_author => $bob_pk,
        )
    }, 'croaks on invalid status';
};

###############################################################################
# User grasp list (kind 10317)
###############################################################################

subtest 'grasp_list: kind 10317' => sub {
    my $list = Net::Nostr::Git->grasp_list(
        pubkey => $alice_pk,
    );
    is $list->kind, 10317, 'kind 10317';
};

subtest 'grasp_list: is replaceable' => sub {
    my $list = Net::Nostr::Git->grasp_list(
        pubkey => $alice_pk,
    );
    ok $list->is_replaceable, 'replaceable event';
};

subtest 'grasp_list: g tags for grasp servers (SHOULD)' => sub {
    my $list = Net::Nostr::Git->grasp_list(
        pubkey  => $alice_pk,
        servers => ['wss://grasp1.example.com', 'wss://grasp2.example.com'],
    );
    my @g = grep { $_->[0] eq 'g' } @{$list->tags};
    is scalar @g, 2, 'two g tags';
    is $g[0][1], 'wss://grasp1.example.com', 'first server';
    is $g[1][1], 'wss://grasp2.example.com', 'second server';
};

subtest 'grasp_list: zero g tags allowed' => sub {
    my $list = Net::Nostr::Git->grasp_list(
        pubkey => $alice_pk,
    );
    my @g = grep { $_->[0] eq 'g' } @{$list->tags};
    is scalar @g, 0, 'zero g tags ok';
};

subtest 'grasp_list: g tags preserve order of preference (SHOULD)' => sub {
    my $list = Net::Nostr::Git->grasp_list(
        pubkey  => $alice_pk,
        servers => ['wss://primary.example.com', 'wss://secondary.example.com', 'wss://tertiary.example.com'],
    );
    my @g = grep { $_->[0] eq 'g' } @{$list->tags};
    is scalar @g, 3, 'three g tags';
    is $g[0][1], 'wss://primary.example.com', 'first = highest preference';
    is $g[1][1], 'wss://secondary.example.com', 'second';
    is $g[2][1], 'wss://tertiary.example.com', 'third = lowest preference';
};

subtest 'grasp_list: content is empty' => sub {
    my $list = Net::Nostr::Git->grasp_list(
        pubkey => $alice_pk,
    );
    is $list->content, '', 'empty content';
};

###############################################################################
# from_event
###############################################################################

subtest 'from_event: repository (30617)' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 30617, content => '',
        tags => [
            ['d', 'my-project'],
            ['name', 'My Project'],
            ['description', 'A project'],
            ['web', 'https://example.com'],
            ['clone', 'https://example.com/repo.git'],
            ['relays', 'wss://relay.example.com'],
            ['r', $commit_id, 'euc'],
            ['maintainers', $bob_pk],
            ['t', 'nostr'],
        ],
    );
    my $info = Net::Nostr::Git->from_event($event);
    ok defined $info, 'returns Git object';
    is $info->event_type, 'repository', 'event_type';
    is $info->repo_id, 'my-project', 'repo_id';
    is $info->repo_name, 'My Project', 'repo_name';
    is $info->repo_description, 'A project', 'description';
    is $info->web->[0], 'https://example.com', 'web urls';
    is $info->clone_urls->[0], 'https://example.com/repo.git', 'clone urls';
    is $info->relay_urls->[0], 'wss://relay.example.com', 'relay urls';
    is $info->earliest_unique_commit, $commit_id, 'euc';
    is $info->maintainer_pubkeys->[0], $bob_pk, 'maintainers';
};

subtest 'from_event: repository_state (30618)' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 30618, content => '',
        tags => [
            ['d', 'my-project'],
            ['refs/heads/main', $commit_id],
            ['HEAD', 'ref: refs/heads/main'],
        ],
    );
    my $info = Net::Nostr::Git->from_event($event);
    is $info->event_type, 'repository_state', 'event_type';
    is $info->repo_id, 'my-project', 'repo_id';
};

subtest 'from_event: patch (1617)' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1617, content => $patch_content,
        tags => [
            ['a', $repo_coord],
            ['r', $commit_id],
            ['p', $alice_pk],
            ['t', 'root'],
            ['commit', $commit_id2],
        ],
    );
    my $info = Net::Nostr::Git->from_event($event);
    is $info->event_type, 'patch', 'event_type';
    is $info->repository_address, $repo_coord, 'repository address';
};

subtest 'from_event: pull_request (1618)' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1618, content => 'PR text',
        tags => [
            ['a', $repo_coord],
            ['p', $alice_pk],
            ['subject', 'Add feature'],
            ['c', $commit_id],
            ['clone', 'https://example.com/fork.git'],
        ],
    );
    my $info = Net::Nostr::Git->from_event($event);
    is $info->event_type, 'pull_request', 'event_type';
    is $info->subject, 'Add feature', 'subject';
};

subtest 'from_event: issue (1621)' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1621, content => 'Bug report',
        tags => [
            ['a', $repo_coord],
            ['p', $alice_pk],
            ['subject', 'Crash'],
            ['t', 'bug'],
        ],
    );
    my $info = Net::Nostr::Git->from_event($event);
    is $info->event_type, 'issue', 'event_type';
    is $info->subject, 'Crash', 'subject';
};

subtest 'from_event: status (1630-1633)' => sub {
    for my $pair ([1630, 'open'], [1631, 'applied'], [1632, 'closed'], [1633, 'draft']) {
        my ($kind, $name) = @$pair;
        my $event = make_event(
            pubkey => $alice_pk, kind => $kind, content => '',
            tags => [
                ['e', $event_id, '', 'root'],
                ['p', $alice_pk],
                ['p', $bob_pk],
            ],
        );
        my $info = Net::Nostr::Git->from_event($event);
        is $info->event_type, 'status', "event_type for kind $kind";
        is $info->status_name, $name, "status_name for kind $kind";
    }
};

subtest 'from_event: grasp_list (10317)' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 10317, content => '',
        tags => [
            ['g', 'wss://grasp1.example.com'],
            ['g', 'wss://grasp2.example.com'],
        ],
    );
    my $info = Net::Nostr::Git->from_event($event);
    is $info->event_type, 'grasp_list', 'event_type';
    is scalar @{$info->grasp_servers}, 2, 'grasp servers count';
    is $info->grasp_servers->[0], 'wss://grasp1.example.com', 'first server';
};

subtest 'from_event: pull_request_update (1619)' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1619, content => '',
        tags => [
            ['a', $repo_coord],
            ['E', $event_id],
            ['P', $alice_pk],
            ['c', $commit_id],
            ['clone', 'https://example.com/fork.git'],
        ],
    );
    my $info = Net::Nostr::Git->from_event($event);
    is $info->event_type, 'pull_request_update', 'event_type';
    is $info->repository_address, $repo_coord, 'repository address';
};

subtest 'from_event: returns undef for non-NIP-34 events' => sub {
    my $event = make_event(pubkey => $alice_pk, kind => 1, content => 'hello');
    my $info = Net::Nostr::Git->from_event($event);
    is $info, undef, 'undef for kind 1';
};

###############################################################################
# validate
###############################################################################

subtest 'validate: valid repository' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 30617, content => '',
        tags => [['d', 'my-project']],
    );
    ok lives { Net::Nostr::Git->validate($event) }, 'valid repository';
};

subtest 'validate: repository requires d tag' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 30617, content => '',
        tags => [],
    );
    ok dies { Net::Nostr::Git->validate($event) }, 'rejects repo without d tag';
};

subtest 'validate: repository_state requires d tag' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 30618, content => '',
        tags => [],
    );
    ok dies { Net::Nostr::Git->validate($event) }, 'rejects state without d tag';
};

subtest 'validate: patch requires a tag' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1617, content => $patch_content,
        tags => [],
    );
    ok dies { Net::Nostr::Git->validate($event) }, 'rejects patch without a tag';
};

subtest 'validate: valid patch' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1617, content => $patch_content,
        tags => [['a', $repo_coord]],
    );
    ok lives { Net::Nostr::Git->validate($event) }, 'valid patch';
};

subtest 'validate: pull_request requires a, c, clone tags' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1618, content => 'PR',
        tags => [['a', $repo_coord]],
    );
    ok dies { Net::Nostr::Git->validate($event) }, 'rejects PR without c tag';

    $event = make_event(
        pubkey => $bob_pk, kind => 1618, content => 'PR',
        tags => [['a', $repo_coord], ['c', $commit_id]],
    );
    ok dies { Net::Nostr::Git->validate($event) }, 'rejects PR without clone tag';
};

subtest 'validate: valid pull_request' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1618, content => 'PR',
        tags => [['a', $repo_coord], ['c', $commit_id], ['clone', 'https://example.com/fork.git']],
    );
    ok lives { Net::Nostr::Git->validate($event) }, 'valid PR';
};

subtest 'validate: pull_request_update requires E and P tags' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1619, content => '',
        tags => [['a', $repo_coord], ['c', $commit_id], ['clone', 'url']],
    );
    ok dies { Net::Nostr::Git->validate($event) }, 'rejects update without E/P';
};

subtest 'validate: valid pull_request_update' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1619, content => '',
        tags => [['a', $repo_coord], ['E', $event_id], ['P', $alice_pk],
                 ['c', $commit_id], ['clone', 'url']],
    );
    ok lives { Net::Nostr::Git->validate($event) }, 'valid PR update';
};

subtest 'validate: issue requires a tag' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1621, content => 'Bug',
        tags => [],
    );
    ok dies { Net::Nostr::Git->validate($event) }, 'rejects issue without a tag';
};

subtest 'validate: valid issue' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1621, content => 'Bug report',
        tags => [['a', $repo_coord]],
    );
    ok lives { Net::Nostr::Git->validate($event) }, 'valid issue';
};

subtest 'validate: valid grasp_list' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 10317, content => '',
        tags => [['g', 'wss://grasp.example.com']],
    );
    ok lives { Net::Nostr::Git->validate($event) }, 'valid grasp list';
};

subtest 'validate: status requires e root tag' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 1630, content => '',
        tags => [['p', $alice_pk]],
    );
    ok dies { Net::Nostr::Git->validate($event) }, 'rejects status without e root';
};

subtest 'validate: valid status' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 1630, content => '',
        tags => [['e', $event_id, '', 'root'], ['p', $alice_pk], ['p', $bob_pk]],
    );
    ok lives { Net::Nostr::Git->validate($event) }, 'valid status';
};

subtest 'validate: rejects non-NIP-34 kind' => sub {
    my $event = make_event(pubkey => $alice_pk, kind => 1, content => 'hello');
    ok dies { Net::Nostr::Git->validate($event) }, 'rejects kind 1';
};

###############################################################################
# Spec JSON examples as test vectors
###############################################################################

subtest 'spec example: repository announcement' => sub {
    # From spec: kind 30617 with all tags
    my $repo = Net::Nostr::Git->repository(
        pubkey              => $alice_pk,
        id                  => 'my-project',
        name                => 'My Cool Project',
        description         => 'brief human-readable project description',
        web                 => ['https://example.com/repo'],
        clone               => ['https://example.com/repo.git'],
        relays              => ['wss://relay.example.com'],
        earliest_unique_commit => $commit_id,
        maintainers         => [$bob_pk],
        personal_fork       => 1,
        hashtags            => ['nostr'],
    );
    is $repo->kind, 30617, 'kind';
    is $repo->content, '', 'empty content';
    is $repo->d_tag, 'my-project', 'd tag';
};

subtest 'spec example: repository state' => sub {
    my $state = Net::Nostr::Git->repository_state(
        pubkey => $alice_pk,
        id     => 'my-project',
        refs   => [
            ['refs/heads/main', $commit_id],
            ['refs/tags/v1.0',  $commit_id2],
        ],
        head => 'main',
    );
    is $state->kind, 30618, 'kind';
    my @head = grep { $_->[0] eq 'HEAD' } @{$state->tags};
    is $head[0][1], 'ref: refs/heads/main', 'HEAD ref';
};

subtest 'spec example: patch' => sub {
    my $patch = Net::Nostr::Git->patch(
        pubkey     => $bob_pk,
        content    => $patch_content,
        repository => $repo_coord,
        earliest_unique_commit => $commit_id,
        repo_owner => $alice_pk,
        root       => 1,
        commit     => $commit_id2,
        parent_commit => $commit_id3,
        commit_pgp_sig => '',
        committer => ['Bob', 'bob@example.com', '1704067200', '+0000'],
    );
    is $patch->kind, 1617, 'kind';
    my @a = grep { $_->[0] eq 'a' } @{$patch->tags};
    is $a[0][1], $repo_coord, 'a tag';
    my @t = grep { $_->[0] eq 't' && $_->[1] eq 'root' } @{$patch->tags};
    is scalar @t, 1, 'root tag present';
};

subtest 'spec example: pull request' => sub {
    my $pr = Net::Nostr::Git->pull_request(
        pubkey     => $bob_pk,
        content    => 'Please review',
        repository => $repo_coord,
        earliest_unique_commit => $commit_id,
        repo_owner => $alice_pk,
        subject    => 'Add feature',
        labels     => ['enhancement'],
        commit     => $commit_id2,
        clone      => ['https://example.com/fork.git'],
        branch_name => 'feature-branch',
        merge_base => $commit_id3,
    );
    is $pr->kind, 1618, 'kind';
    my @s = grep { $_->[0] eq 'subject' } @{$pr->tags};
    is $s[0][1], 'Add feature', 'subject';
};

subtest 'spec example: pull request update' => sub {
    my $update = Net::Nostr::Git->pull_request_update(
        pubkey     => $bob_pk,
        repository => $repo_coord,
        earliest_unique_commit => $commit_id,
        repo_owner => $alice_pk,
        pr_event   => $event_id,
        pr_author  => $alice_pk,
        commit     => $commit_id2,
        clone      => ['https://example.com/fork.git'],
        merge_base => $commit_id3,
    );
    is $update->kind, 1619, 'kind';
    my @E = grep { $_->[0] eq 'E' } @{$update->tags};
    is $E[0][1], $event_id, 'E tag';
};

subtest 'spec example: issue' => sub {
    my $issue = Net::Nostr::Git->issue(
        pubkey     => $bob_pk,
        content    => 'Bug details here',
        repository => $repo_coord,
        repo_owner => $alice_pk,
        subject    => 'Crash on startup',
        labels     => ['bug', 'critical'],
    );
    is $issue->kind, 1621, 'kind';
    my @s = grep { $_->[0] eq 'subject' } @{$issue->tags};
    is $s[0][1], 'Crash on startup', 'subject';
    my @t = grep { $_->[0] eq 't' } @{$issue->tags};
    is scalar @t, 2, 'two labels';
};

subtest 'spec example: status events' => sub {
    # Status for applied with merge commit
    my $status = Net::Nostr::Git->status(
        pubkey     => $alice_pk,
        status     => 'applied',
        target     => $event_id,
        repo_owner => $alice_pk,
        target_author => $bob_pk,
        repository => $repo_coord,
        earliest_unique_commit => $commit_id,
        applied_patches => [
            { id => $event_id2, relay_url => '', pubkey => $bob_pk },
        ],
        merge_commit => $commit_id2,
    );
    is $status->kind, 1631, 'kind 1631';
    my @mc = grep { $_->[0] eq 'merge-commit' } @{$status->tags};
    is $mc[0][1], $commit_id2, 'merge-commit';
};

###############################################################################
# hex64 validation for pubkeys and event IDs in tags
###############################################################################

subtest 'hex64 validation rejects invalid pubkeys and event IDs in tags' => sub {
    my $bad_short    = 'abcd';
    my $bad_upper    = 'A' x 64;
    my $bad_chars    = 'z' x 64;

    # repository: maintainers
    ok dies { Net::Nostr::Git->repository(pubkey => $alice_pk, id => 'r', maintainers => [$bad_short]) },
        'repository rejects short maintainer';
    ok dies { Net::Nostr::Git->repository(pubkey => $alice_pk, id => 'r', maintainers => [$bad_upper]) },
        'repository rejects uppercase maintainer';

    # patch: repo_owner
    ok dies { Net::Nostr::Git->patch(pubkey => $alice_pk, content => 'x', repository => $repo_coord, repo_owner => $bad_short) },
        'patch rejects short repo_owner';

    # patch: notify
    ok dies { Net::Nostr::Git->patch(pubkey => $alice_pk, content => 'x', repository => $repo_coord, notify => [$bad_chars]) },
        'patch rejects invalid notify';

    # patch: previous_patch
    ok dies { Net::Nostr::Git->patch(pubkey => $alice_pk, content => 'x', repository => $repo_coord, previous_patch => $bad_upper) },
        'patch rejects uppercase previous_patch';

    # pull_request: repo_owner
    ok dies { Net::Nostr::Git->pull_request(pubkey => $alice_pk, content => 'x', repository => $repo_coord, commit => $commit_id, clone => ['url'], repo_owner => $bad_short) },
        'pull_request rejects short repo_owner';

    # pull_request: notify
    ok dies { Net::Nostr::Git->pull_request(pubkey => $alice_pk, content => 'x', repository => $repo_coord, commit => $commit_id, clone => ['url'], notify => [$bad_upper]) },
        'pull_request rejects uppercase notify';

    # pull_request: revises
    ok dies { Net::Nostr::Git->pull_request(pubkey => $alice_pk, content => 'x', repository => $repo_coord, commit => $commit_id, clone => ['url'], revises => $bad_chars) },
        'pull_request rejects invalid revises';

    # pull_request_update: pr_event
    ok dies { Net::Nostr::Git->pull_request_update(pubkey => $alice_pk, repository => $repo_coord, pr_event => $bad_short, pr_author => $bob_pk, commit => $commit_id, clone => ['url']) },
        'pull_request_update rejects short pr_event';

    # pull_request_update: pr_author
    ok dies { Net::Nostr::Git->pull_request_update(pubkey => $alice_pk, repository => $repo_coord, pr_event => $event_id, pr_author => $bad_upper, commit => $commit_id, clone => ['url']) },
        'pull_request_update rejects uppercase pr_author';

    # pull_request_update: repo_owner
    ok dies { Net::Nostr::Git->pull_request_update(pubkey => $alice_pk, repository => $repo_coord, pr_event => $event_id, pr_author => $bob_pk, commit => $commit_id, clone => ['url'], repo_owner => $bad_chars) },
        'pull_request_update rejects invalid repo_owner';

    # issue: repo_owner
    ok dies { Net::Nostr::Git->issue(pubkey => $alice_pk, content => 'x', repository => $repo_coord, repo_owner => $bad_short) },
        'issue rejects short repo_owner';

    # status: target
    ok dies { Net::Nostr::Git->status(pubkey => $alice_pk, status => 'open', target => $bad_short, repo_owner => $alice_pk, target_author => $bob_pk) },
        'status rejects short target';

    # status: repo_owner
    ok dies { Net::Nostr::Git->status(pubkey => $alice_pk, status => 'open', target => $event_id, repo_owner => $bad_upper, target_author => $bob_pk) },
        'status rejects uppercase repo_owner';

    # status: target_author
    ok dies { Net::Nostr::Git->status(pubkey => $alice_pk, status => 'open', target => $event_id, repo_owner => $alice_pk, target_author => $bad_chars) },
        'status rejects invalid target_author';

    # status: accepted_revision
    ok dies { Net::Nostr::Git->status(pubkey => $alice_pk, status => 'open', target => $event_id, repo_owner => $alice_pk, target_author => $bob_pk, accepted_revision => $bad_short) },
        'status rejects short accepted_revision';

    # status: revision_author
    ok dies { Net::Nostr::Git->status(pubkey => $alice_pk, status => 'open', target => $event_id, repo_owner => $alice_pk, target_author => $bob_pk, revision_author => $bad_upper) },
        'status rejects uppercase revision_author';

    # status: applied_patches id
    ok dies { Net::Nostr::Git->status(pubkey => $alice_pk, status => 'applied', target => $event_id, repo_owner => $alice_pk, target_author => $bob_pk, applied_patches => [{id => $bad_short}]) },
        'status rejects short applied_patches id';

    # status: applied_patches pubkey
    ok dies { Net::Nostr::Git->status(pubkey => $alice_pk, status => 'applied', target => $event_id, repo_owner => $alice_pk, target_author => $bob_pk, applied_patches => [{id => $event_id, pubkey => $bad_upper}]) },
        'status rejects uppercase applied_patches pubkey';

    # valid hex64 still works
    ok lives { Net::Nostr::Git->repository(pubkey => $alice_pk, id => 'r', maintainers => [$bob_pk]) },
        'valid hex64 maintainer accepted';
    ok lives { Net::Nostr::Git->status(pubkey => $alice_pk, status => 'open', target => $event_id, repo_owner => $alice_pk, target_author => $bob_pk) },
        'valid hex64 status params accepted';
};

subtest 'spec example: grasp list' => sub {
    my $list = Net::Nostr::Git->grasp_list(
        pubkey  => $alice_pk,
        servers => ['wss://grasp.example.com'],
    );
    is $list->kind, 10317, 'kind';
    my @g = grep { $_->[0] eq 'g' } @{$list->tags};
    is $g[0][1], 'wss://grasp.example.com', 'g tag';
};

done_testing;
