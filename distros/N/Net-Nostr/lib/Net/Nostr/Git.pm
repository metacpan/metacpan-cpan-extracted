package Net::Nostr::Git;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

use Class::Tiny qw(
    event_type
    repo_id
    repo_name
    repo_description
    web
    clone_urls
    relay_urls
    earliest_unique_commit
    maintainer_pubkeys
    repository_address
    subject
    status_name
    grasp_servers
);

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

my %STATUS_KINDS = (
    open    => 1630,
    applied => 1631,
    merged  => 1631,
    resolved => 1631,
    closed  => 1632,
    draft   => 1633,
);

my %KIND_STATUS = (
    1630 => 'open',
    1631 => 'applied',
    1632 => 'closed',
    1633 => 'draft',
);

my %NIP34_KINDS = map { $_ => 1 } (30617, 30618, 1617, 1618, 1619, 1621,
                                     1630, 1631, 1632, 1633, 10317);

sub repository {
    my ($class, %args) = @_;

    my $pubkey = $args{pubkey} // croak "repository requires 'pubkey'";
    my $id     = $args{id}     // croak "repository requires 'id'";

    my @tags;
    push @tags, ['d', $id];
    push @tags, ['name', $args{name}] if defined $args{name};
    push @tags, ['description', $args{description}] if defined $args{description};
    push @tags, ['web', @{$args{web}}] if $args{web};
    push @tags, ['clone', @{$args{clone}}] if $args{clone};
    push @tags, ['relays', @{$args{relays}}] if $args{relays};
    push @tags, ['r', $args{earliest_unique_commit}, 'euc'] if defined $args{earliest_unique_commit};
    if ($args{maintainers}) {
        for my $m (@{$args{maintainers}}) {
            croak "maintainers must be 64-char lowercase hex" unless $m =~ $HEX64;
        }
        push @tags, ['maintainers', @{$args{maintainers}}];
    }
    push @tags, ['t', 'personal-fork'] if $args{personal_fork};

    if ($args{hashtags}) {
        push @tags, ['t', $_] for @{$args{hashtags}};
    }

    delete @args{qw(id name description web clone relays earliest_unique_commit
                    maintainers personal_fork hashtags)};
    return Net::Nostr::Event->new(%args, kind => 30617, content => '', tags => \@tags);
}

sub repository_state {
    my ($class, %args) = @_;

    my $pubkey = $args{pubkey} // croak "repository_state requires 'pubkey'";
    my $id     = $args{id}     // croak "repository_state requires 'id'";

    my @tags;
    push @tags, ['d', $id];

    if ($args{refs}) {
        for my $ref (@{$args{refs}}) {
            push @tags, [@$ref];
        }
    }

    if (defined $args{head}) {
        push @tags, ['HEAD', 'ref: refs/heads/' . $args{head}];
    }

    delete @args{qw(id refs head)};
    return Net::Nostr::Event->new(%args, kind => 30618, content => '', tags => \@tags);
}

sub patch {
    my ($class, %args) = @_;

    my $pubkey     = $args{pubkey}     // croak "patch requires 'pubkey'";
    my $content    = $args{content}    // croak "patch requires 'content'";
    my $repository = $args{repository} // croak "patch requires 'repository'";

    my @tags;
    push @tags, ['a', $repository];
    push @tags, ['r', $args{earliest_unique_commit}] if defined $args{earliest_unique_commit};

    if (defined $args{repo_owner}) {
        croak "repo_owner must be 64-char lowercase hex" unless $args{repo_owner} =~ $HEX64;
        push @tags, ['p', $args{repo_owner}];
    }
    if ($args{notify}) {
        for my $n (@{$args{notify}}) {
            croak "notify must be 64-char lowercase hex" unless $n =~ $HEX64;
        }
        push @tags, ['p', $_] for @{$args{notify}};
    }

    push @tags, ['t', 'root'] if $args{root};
    push @tags, ['t', 'root-revision'] if $args{root_revision};

    # Commit metadata (MAY)
    if (defined $args{commit}) {
        push @tags, ['commit', $args{commit}];
        push @tags, ['r', $args{commit}];
    }
    push @tags, ['parent-commit', $args{parent_commit}] if defined $args{parent_commit};
    push @tags, ['commit-pgp-sig', $args{commit_pgp_sig}] if defined $args{commit_pgp_sig};
    push @tags, ['committer', @{$args{committer}}] if $args{committer};

    # NIP-10 e reply tag for patch series
    if (defined $args{previous_patch}) {
        croak "previous_patch must be 64-char lowercase hex" unless $args{previous_patch} =~ $HEX64;
        push @tags, ['e', $args{previous_patch}, $args{previous_patch_relay} // '', 'reply'];
    }

    delete @args{qw(repository earliest_unique_commit repo_owner notify root
                    root_revision commit parent_commit commit_pgp_sig committer
                    previous_patch previous_patch_relay)};
    return Net::Nostr::Event->new(%args, kind => 1617, tags => \@tags);
}

sub pull_request {
    my ($class, %args) = @_;

    my $pubkey     = $args{pubkey}     // croak "pull_request requires 'pubkey'";
    my $content    = $args{content}    // croak "pull_request requires 'content'";
    my $repository = $args{repository} // croak "pull_request requires 'repository'";
    my $commit     = $args{commit}     // croak "pull_request requires 'commit'";
    my $clone      = $args{clone}      // croak "pull_request requires 'clone'";

    my @tags;
    push @tags, ['a', $repository];
    push @tags, ['r', $args{earliest_unique_commit}] if defined $args{earliest_unique_commit};

    if (defined $args{repo_owner}) {
        croak "repo_owner must be 64-char lowercase hex" unless $args{repo_owner} =~ $HEX64;
        push @tags, ['p', $args{repo_owner}];
    }
    if ($args{notify}) {
        for my $n (@{$args{notify}}) {
            croak "notify must be 64-char lowercase hex" unless $n =~ $HEX64;
        }
        push @tags, ['p', $_] for @{$args{notify}};
    }

    push @tags, ['subject', $args{subject}] if defined $args{subject};

    if ($args{labels}) {
        push @tags, ['t', $_] for @{$args{labels}};
    }

    push @tags, ['c', $commit];
    push @tags, ['clone', @$clone];
    push @tags, ['branch-name', $args{branch_name}] if defined $args{branch_name};
    if (defined $args{revises}) {
        croak "revises must be 64-char lowercase hex" unless $args{revises} =~ $HEX64;
        push @tags, ['e', $args{revises}];
    }
    push @tags, ['merge-base', $args{merge_base}] if defined $args{merge_base};

    delete @args{qw(repository earliest_unique_commit repo_owner notify subject
                    labels commit clone branch_name revises merge_base)};
    return Net::Nostr::Event->new(%args, kind => 1618, tags => \@tags);
}

sub pull_request_update {
    my ($class, %args) = @_;

    my $pubkey     = $args{pubkey}     // croak "pull_request_update requires 'pubkey'";
    my $repository = $args{repository} // croak "pull_request_update requires 'repository'";
    my $pr_event   = $args{pr_event}   // croak "pull_request_update requires 'pr_event'";
    my $pr_author  = $args{pr_author}  // croak "pull_request_update requires 'pr_author'";
    my $commit     = $args{commit}     // croak "pull_request_update requires 'commit'";
    my $clone      = $args{clone}      // croak "pull_request_update requires 'clone'";

    croak "pr_event must be 64-char lowercase hex" unless $pr_event =~ $HEX64;
    croak "pr_author must be 64-char lowercase hex" unless $pr_author =~ $HEX64;

    my @tags;
    push @tags, ['a', $repository];
    push @tags, ['r', $args{earliest_unique_commit}] if defined $args{earliest_unique_commit};

    if (defined $args{repo_owner}) {
        croak "repo_owner must be 64-char lowercase hex" unless $args{repo_owner} =~ $HEX64;
        push @tags, ['p', $args{repo_owner}];
    }
    if ($args{notify}) {
        for my $n (@{$args{notify}}) {
            croak "notify must be 64-char lowercase hex" unless $n =~ $HEX64;
        }
        push @tags, ['p', $_] for @{$args{notify}};
    }

    # NIP-22 tags
    push @tags, ['E', $pr_event];
    push @tags, ['P', $pr_author];

    push @tags, ['c', $commit];
    push @tags, ['clone', @$clone];
    push @tags, ['merge-base', $args{merge_base}] if defined $args{merge_base};

    delete @args{qw(repository earliest_unique_commit repo_owner notify
                    pr_event pr_author commit clone merge_base)};
    return Net::Nostr::Event->new(%args, kind => 1619, content => '', tags => \@tags);
}

sub issue {
    my ($class, %args) = @_;

    my $pubkey     = $args{pubkey}     // croak "issue requires 'pubkey'";
    my $content    = $args{content}    // croak "issue requires 'content'";
    my $repository = $args{repository} // croak "issue requires 'repository'";

    my @tags;
    push @tags, ['a', $repository];

    if (defined $args{repo_owner}) {
        croak "repo_owner must be 64-char lowercase hex" unless $args{repo_owner} =~ $HEX64;
        push @tags, ['p', $args{repo_owner}];
    }

    push @tags, ['subject', $args{subject}] if defined $args{subject};

    if ($args{labels}) {
        push @tags, ['t', $_] for @{$args{labels}};
    }

    delete @args{qw(repository repo_owner subject labels)};
    return Net::Nostr::Event->new(%args, kind => 1621, tags => \@tags);
}

sub status {
    my ($class, %args) = @_;

    my $pubkey        = $args{pubkey}        // croak "status requires 'pubkey'";
    my $status        = $args{status}        // croak "status requires 'status'";
    my $target        = $args{target}        // croak "status requires 'target'";
    my $repo_owner    = $args{repo_owner}    // croak "status requires 'repo_owner'";
    my $target_author = $args{target_author} // croak "status requires 'target_author'";

    croak "target must be 64-char lowercase hex" unless $target =~ $HEX64;
    croak "repo_owner must be 64-char lowercase hex" unless $repo_owner =~ $HEX64;
    croak "target_author must be 64-char lowercase hex" unless $target_author =~ $HEX64;

    my $kind = $STATUS_KINDS{$status};
    croak "unknown status: $status (must be open, applied, merged, resolved, closed, or draft)"
        unless defined $kind;

    my $content = $args{content} // '';

    my @tags;
    push @tags, ['e', $target, '', 'root'];

    if (defined $args{accepted_revision}) {
        croak "accepted_revision must be 64-char lowercase hex" unless $args{accepted_revision} =~ $HEX64;
        push @tags, ['e', $args{accepted_revision}, '', 'reply'];
    }

    push @tags, ['p', $repo_owner];
    push @tags, ['p', $target_author];

    if (defined $args{revision_author}) {
        croak "revision_author must be 64-char lowercase hex" unless $args{revision_author} =~ $HEX64;
        push @tags, ['p', $args{revision_author}];
    }

    # Optional filter efficiency tags
    if (defined $args{repository}) {
        push @tags, ['a', $args{repository}, $args{repository_relay} // ''];
    }
    if (defined $args{earliest_unique_commit}) {
        push @tags, ['r', $args{earliest_unique_commit}];
    }

    # 1631-specific optional tags
    if ($args{applied_patches}) {
        for my $p (@{$args{applied_patches}}) {
            croak "applied_patches id must be 64-char lowercase hex" if defined $p->{id} && $p->{id} !~ $HEX64;
            croak "applied_patches pubkey must be 64-char lowercase hex" if defined $p->{pubkey} && $p->{pubkey} ne '' && $p->{pubkey} !~ $HEX64;
            push @tags, ['q', $p->{id}, $p->{relay_url} // '', $p->{pubkey} // ''];
        }
    }
    if (defined $args{merge_commit}) {
        push @tags, ['merge-commit', $args{merge_commit}];
        push @tags, ['r', $args{merge_commit}];
    }
    if ($args{applied_as_commits}) {
        push @tags, ['applied-as-commits', @{$args{applied_as_commits}}];
        push @tags, ['r', $_] for @{$args{applied_as_commits}};
    }

    delete @args{qw(status target repo_owner target_author accepted_revision
                    revision_author repository repository_relay
                    earliest_unique_commit applied_patches merge_commit
                    applied_as_commits)};
    return Net::Nostr::Event->new(%args, kind => $kind, content => $content, tags => \@tags);
}

sub grasp_list {
    my ($class, %args) = @_;

    my $pubkey = $args{pubkey} // croak "grasp_list requires 'pubkey'";

    my @tags;
    if ($args{servers}) {
        push @tags, ['g', $_] for @{$args{servers}};
    }

    delete @args{qw(servers)};
    return Net::Nostr::Event->new(%args, kind => 10317, content => '', tags => \@tags);
}

sub from_event {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    return undef unless $NIP34_KINDS{$kind};

    if ($kind == 30617) {
        return _parse_repository($class, $event);
    } elsif ($kind == 30618) {
        return _parse_repository_state($class, $event);
    } elsif ($kind == 1617) {
        return _parse_patch($class, $event);
    } elsif ($kind == 1618) {
        return _parse_pull_request($class, $event);
    } elsif ($kind == 1619) {
        return _parse_pull_request($class, $event);
    } elsif ($kind == 1621) {
        return _parse_issue($class, $event);
    } elsif ($kind >= 1630 && $kind <= 1633) {
        return _parse_status($class, $event);
    } elsif ($kind == 10317) {
        return _parse_grasp_list($class, $event);
    }

    return undef;
}

sub _parse_repository {
    my ($class, $event) = @_;
    my (%info, @web, @clone_urls, @relay_urls, @maintainers, $euc);

    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        if ($name eq 'd')           { $info{repo_id} = $tag->[1]; }
        elsif ($name eq 'name')     { $info{repo_name} = $tag->[1]; }
        elsif ($name eq 'description') { $info{repo_description} = $tag->[1]; }
        elsif ($name eq 'web')      { push @web, @{$tag}[1 .. $#$tag]; }
        elsif ($name eq 'clone')    { push @clone_urls, @{$tag}[1 .. $#$tag]; }
        elsif ($name eq 'relays')   { push @relay_urls, @{$tag}[1 .. $#$tag]; }
        elsif ($name eq 'r' && defined $tag->[2] && $tag->[2] eq 'euc') {
            $euc = $tag->[1];
        }
        elsif ($name eq 'maintainers') { push @maintainers, @{$tag}[1 .. $#$tag]; }
    }

    return $class->new(
        event_type             => 'repository',
        repo_id                => $info{repo_id},
        repo_name              => $info{repo_name},
        repo_description       => $info{repo_description},
        web                    => \@web,
        clone_urls             => \@clone_urls,
        relay_urls             => \@relay_urls,
        earliest_unique_commit => $euc,
        maintainer_pubkeys     => \@maintainers,
    );
}

sub _parse_repository_state {
    my ($class, $event) = @_;
    my $repo_id;
    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'd') { $repo_id = $tag->[1]; last; }
    }
    return $class->new(
        event_type => 'repository_state',
        repo_id    => $repo_id,
    );
}

sub _parse_patch {
    my ($class, $event) = @_;
    my ($repo_addr, $subject);
    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'a')       { $repo_addr = $tag->[1]; }
        elsif ($tag->[0] eq 'subject') { $subject = $tag->[1]; }
    }
    return $class->new(
        event_type         => 'patch',
        repository_address => $repo_addr,
        subject            => $subject,
    );
}

sub _parse_pull_request {
    my ($class, $event) = @_;
    my ($repo_addr, $subject);
    my $type = $event->kind == 1618 ? 'pull_request' : 'pull_request_update';
    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'a')       { $repo_addr = $tag->[1]; }
        elsif ($tag->[0] eq 'subject') { $subject = $tag->[1]; }
    }
    return $class->new(
        event_type         => $type,
        repository_address => $repo_addr,
        subject            => $subject,
    );
}

sub _parse_issue {
    my ($class, $event) = @_;
    my ($repo_addr, $subject);
    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'a')       { $repo_addr = $tag->[1]; }
        elsif ($tag->[0] eq 'subject') { $subject = $tag->[1]; }
    }
    return $class->new(
        event_type         => 'issue',
        repository_address => $repo_addr,
        subject            => $subject,
    );
}

sub _parse_status {
    my ($class, $event) = @_;
    return $class->new(
        event_type  => 'status',
        status_name => $KIND_STATUS{$event->kind},
    );
}

sub _parse_grasp_list {
    my ($class, $event) = @_;
    my @servers;
    for my $tag (@{$event->tags}) {
        push @servers, $tag->[1] if $tag->[0] eq 'g';
    }
    return $class->new(
        event_type    => 'grasp_list',
        grasp_servers => \@servers,
    );
}

sub validate {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    croak "not a NIP-34 event kind: $kind" unless $NIP34_KINDS{$kind};

    if ($kind == 30617 || $kind == 30618) {
        my $has_d;
        for my $tag (@{$event->tags}) {
            $has_d = 1 if $tag->[0] eq 'd';
        }
        croak "repository event MUST have a 'd' tag" unless $has_d;
    }
    elsif ($kind == 1617) {
        _require_tag($event, 'a', 'patch');
    }
    elsif ($kind == 1618) {
        _require_tag($event, 'a', 'pull request');
        _require_tag($event, 'c', 'pull request');
        _require_tag($event, 'clone', 'pull request');
    }
    elsif ($kind == 1619) {
        _require_tag($event, 'a', 'pull request update');
        _require_tag($event, 'E', 'pull request update');
        _require_tag($event, 'P', 'pull request update');
        _require_tag($event, 'c', 'pull request update');
        _require_tag($event, 'clone', 'pull request update');
    }
    elsif ($kind == 1621) {
        _require_tag($event, 'a', 'issue');
    }
    elsif ($kind >= 1630 && $kind <= 1633) {
        my $has_root;
        for my $tag (@{$event->tags}) {
            if ($tag->[0] eq 'e' && defined $tag->[3] && $tag->[3] eq 'root') {
                $has_root = 1;
                last;
            }
        }
        croak "status event MUST have an 'e' tag with 'root' marker" unless $has_root;
    }

    return 1;
}

sub _require_tag {
    my ($event, $tag_name, $type) = @_;
    for my $tag (@{$event->tags}) {
        return if $tag->[0] eq $tag_name;
    }
    croak "$type MUST have a '$tag_name' tag";
}

1;

__END__

=head1 NAME

Net::Nostr::Git - NIP-34 git collaboration over Nostr

=head1 SYNOPSIS

    use Net::Nostr::Git;

    # Announce a repository
    my $repo = Net::Nostr::Git->repository(
        pubkey      => $my_pubkey,
        id          => 'my-project',
        name        => 'My Project',
        description => 'A Nostr library',
        clone       => ['https://github.com/user/repo.git'],
        relays      => ['wss://relay.example.com'],
    );

    # Announce repository state
    my $state = Net::Nostr::Git->repository_state(
        pubkey => $my_pubkey,
        id     => 'my-project',
        refs   => [
            ['refs/heads/main', $commit_id],
            ['refs/tags/v1.0',  $tag_commit_id],
        ],
        head => 'main',
    );

    # Submit a patch
    my $patch = Net::Nostr::Git->patch(
        pubkey     => $my_pubkey,
        content    => $git_format_patch_output,
        repository => "30617:$owner_pk:my-project",
        repo_owner => $owner_pk,
        root       => 1,
    );

    # Open a pull request
    my $pr = Net::Nostr::Git->pull_request(
        pubkey     => $my_pubkey,
        content    => 'Please review these changes.',
        repository => "30617:$owner_pk:my-project",
        subject    => 'Add feature X',
        commit     => $tip_commit_id,
        clone      => ['https://github.com/user/fork.git'],
    );

    # File an issue
    my $issue = Net::Nostr::Git->issue(
        pubkey     => $my_pubkey,
        content    => 'Found a bug in parsing.',
        repository => "30617:$owner_pk:my-project",
        repo_owner => $owner_pk,
        subject    => 'Crash on startup',
        labels     => ['bug'],
    );

    # Set status
    my $status = Net::Nostr::Git->status(
        pubkey        => $my_pubkey,
        status        => 'applied',
        target        => $patch_event_id,
        repo_owner    => $my_pubkey,
        target_author => $author_pk,
    );

    # Update a pull request
    my $update = Net::Nostr::Git->pull_request_update(
        pubkey     => $my_pubkey,
        repository => "30617:$owner_pk:my-project",
        pr_event   => $pr_event_id,
        pr_author  => $pr_author_pk,
        commit     => $new_tip_commit_id,
        clone      => ['https://github.com/user/fork.git'],
    );

    # User grasp list
    my $list = Net::Nostr::Git->grasp_list(
        pubkey  => $my_pubkey,
        servers => ['wss://grasp.example.com'],
    );

    # Parse any NIP-34 event
    my $info = Net::Nostr::Git->from_event($event);
    say $info->event_type;  # 'repository', 'patch', 'issue', etc.

    # Validate a NIP-34 event
    Net::Nostr::Git->validate($event);

=head1 DESCRIPTION

Implements NIP-34 git collaboration over Nostr. Provides methods to create
all NIP-34 event kinds: repository announcements, repository state, patches,
pull requests, pull request updates, issues, status events, and user grasp
lists.

Replies to patches, PRs, and issues follow NIP-22 comment threading (see
L<Net::Nostr::Comment>).

=head1 CONSTRUCTOR

=head2 new

    my $info = Net::Nostr::Git->new(%fields);

Creates a new C<Net::Nostr::Git> object.  Typically returned by
L</from_event>; calling C<new> directly is useful for testing or
manual construction.

    my $info = Net::Nostr::Git->new(
        event_type => 'repository',
        repo_id    => 'my-project',
    );

Accepted fields: C<event_type>, C<repo_id>, C<repo_name>,
C<repo_description>, C<web>, C<clone_urls>, C<relay_urls>,
C<earliest_unique_commit>, C<maintainer_pubkeys>,
C<repository_address>, C<subject>, C<status_name>, C<grasp_servers>.
Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 repository

    my $event = Net::Nostr::Git->repository(
        pubkey              => $hex_pubkey,
        id                  => 'repo-id',          # required, becomes d tag
        name                => 'Human Name',       # optional
        description         => 'Description',      # optional
        web                 => ['https://...'],     # optional, multiple values
        clone               => ['https://...git'],  # optional, multiple values
        relays              => ['wss://...'],       # optional, multiple values
        earliest_unique_commit => $commit_hex,      # optional, r tag with euc
        maintainers         => [$pubkey, ...],      # optional, multiple values
        personal_fork       => 1,                   # optional, adds t:personal-fork
        hashtags            => ['tag1', 'tag2'],    # optional
    );

Creates a kind 30617 (addressable) repository announcement event.
Only C<pubkey> and C<id> are required; all other tags are optional per spec.

The C<web>, C<clone>, C<relays>, and C<maintainers> tags support multiple
values passed as arrayrefs.

=head2 repository_state

    my $event = Net::Nostr::Git->repository_state(
        pubkey => $hex_pubkey,
        id     => 'repo-id',
        refs   => [
            ['refs/heads/main', $commit_id],
            ['refs/heads/dev',  $commit_id, $parent_short, $grandparent_short],
        ],
        head => 'main',  # optional, becomes HEAD tag
    );

Creates a kind 30618 (addressable) repository state event. The C<d> tag
matches the corresponding repository announcement.

Each ref is an arrayref of C<[ref-path, commit-id, ...]>. Additional elements
after the commit ID are optional shorthand ancestor commits for client use.

If no C<refs> are provided, the author signals they are no longer tracking
state.

=head2 patch

    my $event = Net::Nostr::Git->patch(
        pubkey     => $hex_pubkey,
        content    => $git_format_patch_output,
        repository => '30617:<owner-pk>:<repo-id>',
        repo_owner => $owner_pk,              # optional p tag
        notify     => [$other_pk],            # optional additional p tags
        earliest_unique_commit => $commit_id, # optional r tag
        root       => 1,                      # optional t:root for first patch
        root_revision => 1,                   # optional t:root-revision
        previous_patch => $event_id,          # optional NIP-10 e reply tag
        previous_patch_relay => 'wss://...',  # optional relay hint for e tag
        commit        => $commit_id,          # optional stable commit id
        parent_commit => $commit_id,          # optional
        commit_pgp_sig => '...',              # optional
        committer => [$name, $email, $ts, $tz],  # optional
    );

Creates a kind 1617 patch event. Content should be the output of
C<git format-patch>. The first patch in a series MAY be a cover letter
in the format produced by C<git format-patch --cover-letter>.

Set C<root> for the first patch in a series. Set C<root_revision> for the
first patch in a revision. Use C<previous_patch> (with optional
C<previous_patch_relay>) for NIP-10 C<e> reply threading within a patch
series.

=head2 pull_request

    my $event = Net::Nostr::Git->pull_request(
        pubkey      => $hex_pubkey,
        content     => 'Markdown description',
        repository  => '30617:<owner-pk>:<repo-id>',
        subject     => 'PR title',            # optional
        commit      => $tip_commit_id,        # required, c tag
        clone       => ['https://...git'],    # required, at least one
        repo_owner  => $owner_pk,             # optional p tag
        notify      => [$other_pk],           # optional
        labels      => ['enhancement'],       # optional t tags
        branch_name => 'feature-x',           # optional
        revises     => $root_patch_event_id,  # optional e tag
        merge_base  => $commit_id,            # optional
        earliest_unique_commit => $commit_id, # optional r tag
    );

Creates a kind 1618 pull request event. C<commit> and C<clone> are required.

=head2 pull_request_update

    my $event = Net::Nostr::Git->pull_request_update(
        pubkey     => $hex_pubkey,
        repository => '30617:<owner-pk>:<repo-id>',
        pr_event   => $pr_event_id,       # E tag
        pr_author  => $pr_author_pk,      # P tag
        commit     => $new_tip_commit_id, # c tag
        clone      => ['https://...git'], # clone tag
        repo_owner => $owner_pk,          # optional
        notify     => [$other_pk],        # optional
        merge_base => $commit_id,         # optional
        earliest_unique_commit => $cid,   # optional r tag
    );

Creates a kind 1619 pull request update event with NIP-22 C<E> and C<P>
tags pointing to the original PR.

=head2 issue

    my $event = Net::Nostr::Git->issue(
        pubkey     => $hex_pubkey,
        content    => 'Markdown bug report',
        repository => '30617:<owner-pk>:<repo-id>',
        repo_owner => $owner_pk,           # optional
        subject    => 'Issue title',       # optional
        labels     => ['bug', 'critical'], # optional t tags
    );

Creates a kind 1621 issue event with Markdown content. Issues may
optionally include a C<subject> tag and one or more C<t> label tags.

=head2 status

    my $event = Net::Nostr::Git->status(
        pubkey        => $hex_pubkey,
        status        => 'open',          # open|applied|merged|resolved|closed|draft
        target        => $event_id,       # e root tag
        repo_owner    => $owner_pk,       # p tag
        target_author => $author_pk,      # p tag
        content            => 'Optional note',    # optional, markdown
        accepted_revision  => $event_id,          # optional, e reply tag
        revision_author    => $pk,                # optional, p tag
        repository         => $repo_coord,        # optional, a tag
        repository_relay   => 'wss://...',        # optional, relay hint
        earliest_unique_commit => $commit_id,     # optional, r tag
        applied_patches    => [{id => $eid, relay_url => $r, pubkey => $pk}],  # optional (1631)
        merge_commit       => $commit_id,         # optional (1631)
        applied_as_commits => [$cid1, $cid2],     # optional (1631)
    );

Creates a status event: kind 1630 (Open), 1631 (Applied/Merged/Resolved),
1632 (Closed), or 1633 (Draft).

Per spec, the most recent status event (by C<created_at>) from either the
issue/patch author or a maintainer is considered the current status. The
status of a patch-revision inherits from its root-patch, or becomes Closed
(1632) if the root-patch is Applied/Merged (1631) and the revision is not
tagged in the Applied event.

=head2 grasp_list

    my $event = Net::Nostr::Git->grasp_list(
        pubkey  => $hex_pubkey,
        servers => ['wss://grasp1.com', 'wss://grasp2.com'],
    );

Creates a kind 10317 (replaceable) user grasp list event with C<g> tags
for grasp server URLs in order of preference. C<servers> is optional;
zero or more grasp server URLs may be provided.

=head2 from_event

    my $info = Net::Nostr::Git->from_event($event);

Parses a NIP-34 event and returns a C<Net::Nostr::Git> object with
appropriate accessors populated, or C<undef> if the event is not a
NIP-34 kind.

    say $info->event_type;  # 'repository', 'patch', 'issue', etc.
    say $info->repo_id;     # for repository/state events
    say $info->subject;     # for PR/issue events

=head2 validate

    Net::Nostr::Git->validate($event);

Validates that an event is a well-formed NIP-34 event. Croaks if
required tags are missing for the given kind. Returns 1 on success.

    eval { Net::Nostr::Git->validate($event) };
    warn "Invalid: $@" if $@;

=head1 ACCESSORS

Available on objects returned by L</from_event>.

=head2 event_type

    my $type = $info->event_type;
    # 'repository', 'repository_state', 'patch', 'pull_request',
    # 'pull_request_update', 'issue', 'status', 'grasp_list'

=head2 repo_id

    my $id = $info->repo_id;  # d tag value

=head2 repo_name

    my $name = $info->repo_name;

=head2 repo_description

    my $desc = $info->repo_description;

=head2 web

    my $urls = $info->web;  # arrayref

=head2 clone_urls

    my $urls = $info->clone_urls;  # arrayref

=head2 relay_urls

    my $urls = $info->relay_urls;  # arrayref

=head2 earliest_unique_commit

    my $commit = $info->earliest_unique_commit;

=head2 maintainer_pubkeys

    my $pks = $info->maintainer_pubkeys;  # arrayref

=head2 repository_address

    my $addr = $info->repository_address;  # a tag value

=head2 subject

    my $subj = $info->subject;

=head2 status_name

    my $name = $info->status_name;  # 'open', 'applied', 'closed', 'draft'

=head2 grasp_servers

    my $servers = $info->grasp_servers;  # arrayref of URLs

=head1 SEE ALSO

L<NIP-34|https://github.com/nostr-protocol/nips/blob/master/34.md>,
L<Net::Nostr::Comment>, L<Net::Nostr>, L<Net::Nostr::Event>

=cut
