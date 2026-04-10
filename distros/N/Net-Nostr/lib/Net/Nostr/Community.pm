package Net::Nostr::Community;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Net::Nostr::Event;

use Class::Tiny qw(
    identifier
    name
    description
    image
    moderators
    relays
    communities
    post_id
    post_coordinate
    post_author
    post_kind
);

my $JSON = JSON->new->utf8->canonical;
my $HEX64 = qr/\A[0-9a-f]{64}\z/;

sub new {
    my $class = shift;
    my %args = @_;
    $args{moderators}  //= [];
    $args{relays}      //= [];
    $args{communities} //= [];
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub community {
    my ($class, %args) = @_;

    my $pubkey     = $args{pubkey}     // croak "community requires 'pubkey'";
    my $identifier = $args{identifier} // croak "community requires 'identifier'";

    my @tags;
    push @tags, ['d', $identifier];

    push @tags, ['name', $args{name}] if defined $args{name};
    push @tags, ['description', $args{description}] if defined $args{description};

    if ($args{image}) {
        my @img = ('image', @{$args{image}});
        push @tags, \@img;
    }

    for my $mod (@{$args{moderators} // []}) {
        croak "moderator pubkey must be 64-char lowercase hex" unless $mod->{pubkey} =~ $HEX64;
        push @tags, ['p', $mod->{pubkey}, $mod->{relay} // '', 'moderator'];
    }

    for my $r (@{$args{relays} // []}) {
        my @tag = ('relay', $r->{url});
        push @tag, $r->{marker} if defined $r->{marker};
        push @tags, \@tag;
    }

    for my $t (@{$args{extra_tags} // []}) {
        push @tags, $t;
    }

    return Net::Nostr::Event->new(
        kind    => 34550,
        pubkey  => $pubkey,
        content => '',
        tags    => \@tags,
        (defined $args{created_at} ? (created_at => $args{created_at}) : ()),
    );
}

sub post {
    my ($class, %args) = @_;

    my $pubkey  = $args{pubkey}  // croak "post requires 'pubkey'";
    my $content = $args{content} // croak "post requires 'content'";
    my $cpk     = $args{community_pubkey} // croak "post requires 'community_pubkey'";
    my $cd      = $args{community_d}      // croak "post requires 'community_d'";

    croak "community_pubkey must be 64-char lowercase hex" unless $cpk =~ $HEX64;

    my $coord = "34550:$cpk:$cd";
    my $relay = $args{relay};

    my @tags;
    # Top-level: uppercase and lowercase both point to community
    if (defined $relay) {
        push @tags, ['A', $coord, $relay];
        push @tags, ['a', $coord, $relay];
        push @tags, ['P', $cpk, $relay];
        push @tags, ['p', $cpk, $relay];
    } else {
        push @tags, ['A', $coord];
        push @tags, ['a', $coord];
        push @tags, ['P', $cpk];
        push @tags, ['p', $cpk];
    }
    push @tags, ['K', '34550'];
    push @tags, ['k', '34550'];

    return Net::Nostr::Event->new(
        kind    => 1111,
        pubkey  => $pubkey,
        content => $content,
        tags    => \@tags,
        (defined $args{created_at} ? (created_at => $args{created_at}) : ()),
    );
}

sub reply {
    my ($class, %args) = @_;

    my $pubkey  = $args{pubkey}  // croak "reply requires 'pubkey'";
    my $content = $args{content} // croak "reply requires 'content'";
    my $cpk     = $args{community_pubkey} // croak "reply requires 'community_pubkey'";
    my $cd      = $args{community_d}      // croak "reply requires 'community_d'";
    my $pid     = $args{parent_id}        // croak "reply requires 'parent_id'";
    my $ppk     = $args{parent_pubkey}    // croak "reply requires 'parent_pubkey'";
    my $pkind   = $args{parent_kind}      // croak "reply requires 'parent_kind'";

    croak "community_pubkey must be 64-char lowercase hex" unless $cpk =~ $HEX64;
    croak "parent_pubkey must be 64-char lowercase hex" unless $ppk =~ $HEX64;

    my $coord = "34550:$cpk:$cd";
    my $relay = $args{relay};

    my @tags;
    # Uppercase tags: community definition (root scope)
    if (defined $relay) {
        push @tags, ['A', $coord, $relay];
        push @tags, ['P', $cpk, $relay];
    } else {
        push @tags, ['A', $coord];
        push @tags, ['P', $cpk];
    }
    push @tags, ['K', '34550'];

    # Lowercase tags: parent post/reply
    if (defined $relay) {
        push @tags, ['e', $pid, $relay];
        push @tags, ['p', $ppk, $relay];
    } else {
        push @tags, ['e', $pid];
        push @tags, ['p', $ppk];
    }
    push @tags, ['k', $pkind];

    return Net::Nostr::Event->new(
        kind    => 1111,
        pubkey  => $pubkey,
        content => $content,
        tags    => \@tags,
        (defined $args{created_at} ? (created_at => $args{created_at}) : ()),
    );
}

sub approval {
    my ($class, %args) = @_;

    my $pubkey = $args{pubkey} // croak "approval requires 'pubkey'";
    my $post   = $args{post}   // croak "approval requires 'post'";

    my @tags;

    # Community a tags
    if ($args{communities}) {
        for my $c (@{$args{communities}}) {
            croak "community pubkey must be 64-char lowercase hex" unless $c->{pubkey} =~ $HEX64;
            my $coord = "34550:$c->{pubkey}:$c->{d}";
            my @tag = ('a', $coord);
            push @tag, $c->{relay} if defined $c->{relay};
            push @tags, \@tag;
        }
    } else {
        my $cpk = $args{community_pubkey} // croak "approval requires 'community_pubkey'";
        my $cd  = $args{community_d}      // croak "approval requires 'community_d'";
        croak "community_pubkey must be 64-char lowercase hex" unless $cpk =~ $HEX64;
        my $coord = "34550:$cpk:$cd";
        my @tag = ('a', $coord);
        push @tag, $args{relay} if defined $args{relay};
        push @tags, \@tag;
    }

    # Post reference: e tag, a tag, or both
    my $via = $args{approve_via} // 'e';

    if ($via eq 'e' || $via eq 'both') {
        my @e = ('e', $post->id);
        push @e, $args{relay} if defined $args{relay};
        push @tags, \@e;
    }
    if (($via eq 'a' || $via eq 'both') && $post->is_addressable) {
        my $post_coord = $post->kind . ':' . $post->pubkey . ':' . $post->d_tag;
        my @a = ('a', $post_coord);
        push @a, $args{relay} if defined $args{relay};
        push @tags, \@a;
    }

    # Post author p tag
    my @p = ('p', $post->pubkey);
    push @p, $args{relay} if defined $args{relay};
    push @tags, \@p;

    # Post kind k tag
    push @tags, ['k', '' . $post->kind];

    # Content SHOULD be JSON-stringified post
    my $content = $JSON->encode($post->to_hash);

    return Net::Nostr::Event->new(
        kind    => 4550,
        pubkey  => $pubkey,
        content => $content,
        tags    => \@tags,
        (defined $args{created_at} ? (created_at => $args{created_at}) : ()),
    );
}

sub from_event {
    my ($class, $event) = @_;

    if ($event->kind == 34550) {
        return $class->_parse_community($event);
    } elsif ($event->kind == 4550) {
        return $class->_parse_approval($event);
    }

    return undef;
}

sub _parse_community {
    my ($class, $event) = @_;

    my ($identifier, $name, $description, @image, @moderators, @relays);

    for my $tag (@{$event->tags}) {
        my $t = $tag->[0];
        if ($t eq 'd') {
            $identifier = $tag->[1];
        } elsif ($t eq 'name') {
            $name = $tag->[1];
        } elsif ($t eq 'description') {
            $description = $tag->[1];
        } elsif ($t eq 'image') {
            @image = @{$tag}[1 .. $#$tag];
        } elsif ($t eq 'p' && defined $tag->[3] && $tag->[3] eq 'moderator') {
            my %mod = (pubkey => $tag->[1]);
            $mod{relay} = $tag->[2] if defined $tag->[2] && $tag->[2] ne '';
            push @moderators, \%mod;
        } elsif ($t eq 'relay') {
            my %r = (url => $tag->[1]);
            $r{marker} = $tag->[2] if defined $tag->[2];
            push @relays, \%r;
        }
    }

    return $class->new(
        identifier  => $identifier,
        name        => $name,
        description => $description,
        image       => @image ? \@image : undef,
        moderators  => \@moderators,
        relays      => \@relays,
    );
}

sub _parse_approval {
    my ($class, $event) = @_;

    my (@communities, $post_id, $post_coord, $post_author, $post_kind);

    for my $tag (@{$event->tags}) {
        my $t = $tag->[0];
        if ($t eq 'a' && defined $tag->[1] && $tag->[1] =~ /^34550:/) {
            push @communities, $tag->[1];
        } elsif ($t eq 'e') {
            $post_id = $tag->[1];
        } elsif ($t eq 'a' && defined $tag->[1] && $tag->[1] !~ /^34550:/) {
            $post_coord = $tag->[1];
        } elsif ($t eq 'p') {
            $post_author //= $tag->[1];
        } elsif ($t eq 'k') {
            $post_kind = $tag->[1];
        }
    }

    return $class->new(
        communities    => \@communities,
        post_id        => $post_id,
        post_coordinate => $post_coord,
        post_author    => $post_author,
        post_kind      => $post_kind,
    );
}

sub validate {
    my ($class, $event) = @_;

    croak "community event MUST be kind 34550 or 4550"
        unless $event->kind == 34550 || $event->kind == 4550;

    if ($event->kind == 34550) {
        my $has_d = grep { $_->[0] eq 'd' } @{$event->tags};
        croak "community MUST include a d tag" unless $has_d;
    }

    if ($event->kind == 4550) {
        my $has_community = grep {
            $_->[0] eq 'a' && defined $_->[1] && $_->[1] =~ /^34550:/
        } @{$event->tags};
        croak "approval MUST include a community a tag" unless $has_community;

        my $has_post = grep {
            $_->[0] eq 'e' || ($_->[0] eq 'a' && defined $_->[1] && $_->[1] !~ /^34550:/)
        } @{$event->tags};
        croak "approval MUST include an e or a tag for the post" unless $has_post;

        my $has_p = grep { $_->[0] eq 'p' } @{$event->tags};
        croak "approval MUST include a p tag for the post author" unless $has_p;
    }

    return 1;
}

sub community_filter {
    my ($class, %args) = @_;
    my %filter = (kinds => [34550]);
    $filter{'#d'} = $args{identifiers} if $args{identifiers};
    $filter{authors} = $args{authors} if $args{authors};
    return \%filter;
}

sub approval_filter {
    my ($class, %args) = @_;
    my %filter = (kinds => [4550]);
    $filter{'#a'} = [$args{community}] if $args{community};
    $filter{authors} = $args{authors} if $args{authors};
    return \%filter;
}

sub legacy_post_filter {
    my ($class, %args) = @_;
    return {
        kinds => [1],
        '#a'  => [$args{community}],
    };
}

1;

__END__

=head1 NAME

Net::Nostr::Community - NIP-72 moderated communities

=head1 SYNOPSIS

    use Net::Nostr::Community;

    # Define a community
    my $event = Net::Nostr::Community->community(
        pubkey      => $owner_pubkey,
        identifier  => 'my-community',
        name        => 'My Community',
        description => 'A place for discussion',
        image       => ['https://example.com/banner.jpg', '1200x400'],
        moderators  => [
            { pubkey => $mod_pubkey, relay => 'wss://relay1' },
        ],
        relays      => [
            { url => 'wss://relay.example.com', marker => 'requests' },
        ],
    );

    # Post to a community (top-level, kind 1111)
    my $post = Net::Nostr::Community->post(
        pubkey           => $user_pubkey,
        content          => 'Hello community!',
        community_pubkey => $owner_pubkey,
        community_d      => 'my-community',
    );

    # Reply to a post (nested, kind 1111)
    my $reply = Net::Nostr::Community->reply(
        pubkey           => $user_pubkey,
        content          => 'Great post!',
        community_pubkey => $owner_pubkey,
        community_d      => 'my-community',
        parent_id        => $parent_event_id,
        parent_pubkey    => $parent_author,
        parent_kind      => '1111',
    );

    # Approve a post (moderator action, kind 4550)
    my $approval = Net::Nostr::Community->approval(
        pubkey           => $mod_pubkey,
        community_pubkey => $owner_pubkey,
        community_d      => 'my-community',
        post             => $post_event,
    );

    # Parse a community or approval event
    my $info = Net::Nostr::Community->from_event($event);
    say $info->name;  # 'My Community'

=head1 DESCRIPTION

Implements NIP-72 moderated communities (Reddit-style). Communities are
defined by kind 34550 addressable events that list moderators, relays, and
metadata. Users post to communities using kind 1111 (NIP-22) events with
community-scoped tags. Moderators approve posts with kind 4550 events.

The C<d> tag of a community definition MAY double as its name, but if a
C<name> tag is provided, clients SHOULD display it instead.

Posts use uppercase tags (C<A>, C<P>, C<K>) for root scope (the community)
and lowercase tags (C<a>/C<e>, C<p>, C<k>) for the parent. For top-level
posts, both sets point to the community itself.

=head1 CONSTRUCTOR

=head2 new

    my $info = Net::Nostr::Community->new(%fields);

Creates a new C<Net::Nostr::Community> object. Typically returned by
L</from_event>; calling C<new> directly is useful for testing or
manual construction.

    my $info = Net::Nostr::Community->new(
        identifier  => 'my-community',
        name        => 'My Community',
        description => 'A place for discussion.',
    );

Accepted fields: C<identifier>, C<name>, C<description>, C<image>,
C<moderators> (defaults to C<[]>), C<relays> (defaults to C<[]>),
C<communities> (defaults to C<[]>), C<post_id>, C<post_coordinate>,
C<post_author>, C<post_kind>. Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 community

    my $event = Net::Nostr::Community->community(
        pubkey      => $hex_pubkey,           # required
        identifier  => 'my-community',        # required (d tag)
        name        => 'Display Name',        # optional (SHOULD)
        description => 'About this place',    # optional
        image       => ['url', '800x600'],    # optional (with optional dims)
        moderators  => [                      # optional
            { pubkey => $pk, relay => 'wss://...' },
        ],
        relays      => [                      # optional (MAY)
            { url => 'wss://...', marker => 'requests' },
        ],
        extra_tags  => [['rules', '...']],    # optional
    );

Creates a kind 34550 community definition L<Net::Nostr::Event>.

Moderator entries become C<p> tags with the C<moderator> role. The relay
field is optional per moderator. Relay entries become C<relay> tags with
an optional marker (C<author>, C<requests>, C<approvals>).

=head2 post

    my $event = Net::Nostr::Community->post(
        pubkey           => $hex_pubkey,       # required
        content          => 'Hello!',          # required
        community_pubkey => $community_owner,  # required
        community_d      => 'my-community',    # required
        relay            => 'wss://...',       # optional
    );

Creates a kind 1111 top-level post to a community. Both uppercase and
lowercase NIP-22 tags point to the community definition, as specified
by the NIP.

=head2 reply

    my $event = Net::Nostr::Community->reply(
        pubkey           => $hex_pubkey,       # required
        content          => 'I agree!',        # required
        community_pubkey => $community_owner,  # required
        community_d      => 'my-community',    # required
        parent_id        => $event_id,         # required
        parent_pubkey    => $parent_pk,        # required
        parent_kind      => '1111',            # required
        relay            => 'wss://...',       # optional
    );

Creates a kind 1111 nested reply. Uppercase tags point to the community
definition (root scope), lowercase tags point to the parent post or reply.

=head2 approval

    my $event = Net::Nostr::Community->approval(
        pubkey           => $mod_pubkey,       # required
        community_pubkey => $community_owner,  # required (or use communities)
        community_d      => 'my-community',    # required (or use communities)
        post             => $post_event,       # required
        relay            => 'wss://...',       # optional
        approve_via      => 'e',               # optional: 'e', 'a', or 'both'
    );

Creates a kind 4550 approval event. The C<content> is the JSON-stringified
post event. The approval MUST include a community C<a> tag, a post reference
(C<e> or C<a> tag), the post author's C<p> tag, and a C<k> tag with the
post kind.

For replaceable events, C<approve_via> controls how the post is referenced:

=over 4

=item C<e> (default) - approve this specific version

=item C<a> - authorize the author to make future changes

=item C<both> - approve current version and authorize changes

=back

For approving a post across multiple communities:

    my $event = Net::Nostr::Community->approval(
        pubkey      => $mod_pubkey,
        communities => [
            { pubkey => $pk1, d => 'comm1', relay => 'wss://r1' },
            { pubkey => $pk2, d => 'comm2' },
        ],
        post        => $post_event,
    );

=head2 from_event

    my $info = Net::Nostr::Community->from_event($event);

Parses a kind 34550 or 4550 event. Returns a C<Net::Nostr::Community>
object with accessors, or C<undef> if the event kind is not recognized.

For kind 34550 (community definition), the returned object has
C<identifier>, C<name>, C<description>, C<image>, C<moderators>,
and C<relays> accessors.

For kind 4550 (approval), the returned object has C<communities>,
C<post_id>, C<post_coordinate>, C<post_author>, and C<post_kind>
accessors.

=head2 validate

    Net::Nostr::Community->validate($event);

Validates that an event is a well-formed NIP-72 event. Croaks if:

=over

=item * Kind is not 34550 or 4550

=item * Kind 34550 missing C<d> tag

=item * Kind 4550 missing community C<a> tag (34550:...)

=item * Kind 4550 missing C<e> or C<a> tag for the post

=item * Kind 4550 missing C<p> tag for the post author

=back

=head2 community_filter

    my $filter = Net::Nostr::Community->community_filter(
        identifiers => ['my-community'],
        authors     => [$owner_pk],
    );

Returns a hashref filter for querying community definitions.

=head2 approval_filter

    my $filter = Net::Nostr::Community->approval_filter(
        community => '34550:pubkey:identifier',
        authors   => [$mod_pk],
    );

Returns a hashref filter for querying approval events.

=head2 legacy_post_filter

    my $filter = Net::Nostr::Community->legacy_post_filter(
        community => '34550:pubkey:identifier',
    );

Returns a hashref filter for querying legacy kind 1 posts tagged with a
community. Clients MAY use this for backwards compatibility but SHOULD NOT
create new kind 1 posts for communities.

=head1 ACCESSORS

These are available on objects returned by L</from_event>.

=head2 identifier

    my $id = $info->identifier;

The C<d> tag value (community definition).

=head2 name

    my $name = $info->name;  # or undef

The C<name> tag value, or C<undef>. When C<undef>, the C<identifier> MAY
be used as a display name.

=head2 description

    my $desc = $info->description;  # or undef

The community description, or C<undef>.

=head2 image

    my $img = $info->image;  # ['url', '800x600'] or ['url'] or undef

Arrayref of the image URL and optional dimensions, or C<undef>.

=head2 moderators

    my $mods = $info->moderators;
    # [{ pubkey => '...', relay => '...' }, ...]

Arrayref of hashrefs, each with C<pubkey> and optional C<relay>.

=head2 relays

    my $relays = $info->relays;
    # [{ url => 'wss://...', marker => 'requests' }, ...]

Arrayref of hashrefs, each with C<url> and optional C<marker>.

=head2 communities

    my $comms = $info->communities;  # ['34550:pk:id', ...]

Arrayref of community coordinates (from approval events).

=head2 post_id

    my $id = $info->post_id;  # or undef

The approved post's event ID (from C<e> tag), or C<undef>.

=head2 post_coordinate

    my $coord = $info->post_coordinate;  # or undef

The approved post's event coordinate (from non-community C<a> tag),
or C<undef>.

=head2 post_author

    my $pk = $info->post_author;

The approved post author's pubkey (from C<p> tag).

=head2 post_kind

    my $kind = $info->post_kind;  # '1111'

The approved post's kind (from C<k> tag).

=head1 SEE ALSO

L<NIP-72|https://github.com/nostr-protocol/nips/blob/master/72.md>,
L<Net::Nostr::Comment>, L<Net::Nostr>, L<Net::Nostr::Event>

=cut
