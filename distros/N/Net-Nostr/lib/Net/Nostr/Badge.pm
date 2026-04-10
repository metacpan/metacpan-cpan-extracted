package Net::Nostr::Badge;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(
    identifier
    name
    description
    image
    thumbs
    badge
    awardees
    badges
    badge_sets
);

sub new {
    my $class = shift;
    my %args = @_;
    $args{thumbs}     //= [];
    $args{awardees}   //= [];
    $args{badges}     //= [];
    $args{badge_sets} //= [];
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub definition {
    my ($class, %args) = @_;

    my $identifier = delete $args{identifier}
        // croak "definition requires 'identifier'";

    my @tags;
    push @tags, ['d', $identifier];

    push @tags, ['name', delete $args{name}] if defined $args{name};
    delete $args{name};

    push @tags, ['description', delete $args{description}] if defined $args{description};
    delete $args{description};

    if (my $image = delete $args{image}) {
        push @tags, ['image', @$image];
    }

    if (my $thumbs = delete $args{thumbs}) {
        for my $thumb (@$thumbs) {
            push @tags, ['thumb', @$thumb];
        }
    }

    return Net::Nostr::Event->new(
        %args,
        kind    => 30009,
        content => '',
        tags    => \@tags,
    );
}

sub award {
    my ($class, %args) = @_;

    my $badge = delete $args{badge}
        // croak "award requires 'badge'";
    my $awardees = delete $args{awardees}
        // croak "award requires 'awardees'";

    croak "award requires at least one awardee" unless @$awardees;

    my @tags;
    push @tags, ['a', $badge];

    for my $awardee (@$awardees) {
        push @tags, ['p', @$awardee];
    }

    return Net::Nostr::Event->new(
        %args,
        kind    => 8,
        content => '',
        tags    => \@tags,
    );
}

sub profile_badges {
    my ($class, %args) = @_;

    my $badges = delete $args{badges}
        // croak "profile_badges requires 'badges'";
    my $badge_sets = delete $args{badge_sets};

    my @tags;
    for my $entry (@$badges) {
        push @tags, ['a', $entry->{definition}];
        my @e = ('e', $entry->{award});
        push @e, $entry->{award_relay} if defined $entry->{award_relay};
        push @tags, \@e;
    }

    if ($badge_sets) {
        for my $set (@$badge_sets) {
            push @tags, ['a', $set];
        }
    }

    return Net::Nostr::Event->new(
        %args,
        kind    => 10008,
        content => '',
        tags    => \@tags,
    );
}

sub badge_set {
    my ($class, %args) = @_;

    my $identifier = delete $args{identifier}
        // croak "badge_set requires 'identifier'";
    my $badges = delete $args{badges}
        // croak "badge_set requires 'badges'";

    my @tags;
    push @tags, ['d', $identifier];

    for my $entry (@$badges) {
        push @tags, ['a', $entry->{definition}];
        my @e = ('e', $entry->{award});
        push @e, $entry->{award_relay} if defined $entry->{award_relay};
        push @tags, \@e;
    }

    return Net::Nostr::Event->new(
        %args,
        kind    => 30008,
        content => '',
        tags    => \@tags,
    );
}

sub from_event {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    if ($kind == 30009) {
        return $class->_parse_definition($event);
    } elsif ($kind == 8) {
        return $class->_parse_award($event);
    } elsif ($kind == 10008) {
        return $class->_parse_profile_badges($event);
    } elsif ($kind == 30008) {
        return $class->_parse_badge_set($event);
    }

    return undef;
}

sub _parse_definition {
    my ($class, $event) = @_;

    my ($identifier, $name, $description, $image, @thumbs);

    for my $tag (@{$event->tags}) {
        my $t = $tag->[0];
        if ($t eq 'd') {
            $identifier = $tag->[1];
        } elsif ($t eq 'name') {
            $name = $tag->[1];
        } elsif ($t eq 'description') {
            $description = $tag->[1];
        } elsif ($t eq 'image') {
            $image = [@{$tag}[1 .. $#$tag]];
        } elsif ($t eq 'thumb') {
            push @thumbs, [@{$tag}[1 .. $#$tag]];
        }
    }

    return $class->new(
        identifier  => $identifier,
        name        => $name,
        description => $description,
        image       => $image,
        thumbs      => \@thumbs,
    );
}

sub _parse_award {
    my ($class, $event) = @_;

    my ($badge, @awardees);

    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'a') {
            $badge = $tag->[1];
        } elsif ($tag->[0] eq 'p') {
            push @awardees, [@{$tag}[1 .. $#$tag]];
        }
    }

    return $class->new(
        badge    => $badge,
        awardees => \@awardees,
    );
}

sub _parse_profile_badges {
    my ($class, $event) = @_;
    return $class->_parse_badge_pairs($event);
}

sub _parse_badge_set {
    my ($class, $event) = @_;

    my $identifier;
    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'd') {
            $identifier = $tag->[1];
            last;
        }
    }

    # Deprecated: kind 30008 with d=profile_badges is treated as profile badges
    if (defined $identifier && $identifier eq 'profile_badges') {
        return $class->_parse_badge_pairs($event);
    }

    my $obj = $class->_parse_badge_pairs($event);
    $obj->{identifier} = $identifier;
    return $obj;
}

sub _parse_badge_pairs {
    my ($class, $event) = @_;

    my @badges;
    my $pending_def;

    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'a' && defined $tag->[1] && $tag->[1] =~ /^30009:/) {
            # If we had a pending def without an e, discard it
            $pending_def = $tag->[1];
        } elsif ($tag->[0] eq 'e' && defined $pending_def) {
            my %entry = (
                definition => $pending_def,
                award      => $tag->[1],
            );
            $entry{award_relay} = $tag->[2] if defined $tag->[2] && $tag->[2] ne '';
            push @badges, \%entry;
            $pending_def = undef;
        } elsif ($tag->[0] eq 'e') {
            # e without preceding a -- ignore
        }
    }

    return $class->new(badges => \@badges);
}

sub validate {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    croak "badge event MUST be kind 30009, 8, 10008, or 30008"
        unless $kind == 30009 || $kind == 8 || $kind == 10008 || $kind == 30008;

    if ($kind == 30009) {
        my $has_d = grep { $_->[0] eq 'd' } @{$event->tags};
        croak "badge definition MUST have a 'd' tag" unless $has_d;
    }

    if ($kind == 8) {
        my $has_a = grep {
            $_->[0] eq 'a' && defined $_->[1] && $_->[1] =~ /^30009:/
        } @{$event->tags};
        croak "badge award MUST have an 'a' tag referencing a kind 30009 badge definition" unless $has_a;
        my $has_p = grep { $_->[0] eq 'p' } @{$event->tags};
        croak "badge award MUST have at least one 'p' tag" unless $has_p;
    }

    if ($kind == 30008) {
        my $has_d = grep { $_->[0] eq 'd' } @{$event->tags};
        croak "badge set MUST have a 'd' tag" unless $has_d;
    }

    return 1;
}

1;

__END__


=head1 NAME

Net::Nostr::Badge - NIP-58 Badges

=head1 SYNOPSIS

    use Net::Nostr::Badge;

    # Define a badge (kind 30009, addressable)
    my $event = Net::Nostr::Badge->definition(
        pubkey      => $issuer_pubkey,
        identifier  => 'bravery',
        name        => 'Medal of Bravery',
        description => 'Awarded to users demonstrating bravery',
        image       => ['https://nostr.academy/awards/bravery.png', '1024x1024'],
        thumbs      => [
            ['https://nostr.academy/awards/bravery_256x256.png', '256x256'],
        ],
    );

    # Award a badge (kind 8)
    my $award = Net::Nostr::Badge->award(
        pubkey   => $issuer_pubkey,
        badge    => '30009:issuer_pk:bravery',
        awardees => [[$recipient_pk, 'wss://relay']],
    );

    # Display badges on profile (kind 10008, replaceable)
    my $profile = Net::Nostr::Badge->profile_badges(
        pubkey => $user_pubkey,
        badges => [
            { definition => '30009:issuer:bravery', award => $award_event_id },
        ],
    );

    # Categorize badges into a set (kind 30008, addressable)
    my $set = Net::Nostr::Badge->badge_set(
        pubkey     => $user_pubkey,
        identifier => 'my-favorites',
        badges     => [
            { definition => '30009:issuer:bravery', award => $award_event_id },
        ],
    );

    # Parse any badge event
    my $badge = Net::Nostr::Badge->from_event($event);

    # Validate
    Net::Nostr::Badge->validate($event);

=head1 DESCRIPTION

Implements NIP-58 (Badges). Four event kinds are used to define, award,
display, and categorize badges:

=over 4

=item * B<Badge Definition> (kind 30009) - Addressable event defining a badge.
Published by the badge issuer. Can be updated.

=item * B<Badge Award> (kind 8) - Awards a badge to one or more pubkeys.
Immutable and non-transferable.

=item * B<Profile Badges> (kind 10008) - Replaceable event listing badges
a user has accepted, in display order.

=item * B<Badge Set> (kind 30008) - Addressable event categorizing accepted
badges into labeled groups.

=back

Badge image recommended aspect ratio is 1:1 with a high-res size of
1024x1024 pixels. Recommended thumbnail dimensions are 512x512 (xl),
256x256 (l), 64x64 (m), 32x32 (s), and 16x16 (xs).

=head1 CONSTRUCTOR

=head2 new

    my $badge = Net::Nostr::Badge->new(%fields);

Creates a new C<Net::Nostr::Badge> object. Typically returned by
L</from_event>. Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 definition

    my $event = Net::Nostr::Badge->definition(
        pubkey      => $hex_pubkey,             # required
        identifier  => 'bravery',               # required (d tag)
        name        => 'Medal of Bravery',      # optional (MAY)
        description => 'Awarded to brave users', # optional (MAY)
        image       => ['url', '1024x1024'],    # optional (MAY, dims optional)
        thumbs      => [['url', '256x256']],    # optional (MAY, dims optional)
        created_at  => time(),                  # optional
    );

Creates a kind 30009 badge definition L<Net::Nostr::Event>. C<identifier>
is required and becomes the C<d> tag. All other fields are optional per
the spec.

=head2 award

    my $event = Net::Nostr::Badge->award(
        pubkey   => $hex_pubkey,                       # required
        badge    => '30009:issuer_pk:bravery',         # required (a tag)
        awardees => [[$pk, 'wss://relay'], [$pk2]],   # required (p tags)
    );

Creates a kind 8 badge award L<Net::Nostr::Event>. C<badge> is the
coordinate of a kind 30009 badge definition. C<awardees> is an arrayref
of arrayrefs, each containing a pubkey and optional relay URL. At least
one awardee is required.

=head2 profile_badges

    my $event = Net::Nostr::Badge->profile_badges(
        pubkey     => $hex_pubkey,                     # required
        badges     => [                                # required
            { definition => '30009:pk:id', award => $eid, award_relay => 'wss://...' },
        ],
        badge_sets => ['30008:pk:set-name'],           # optional
    );

Creates a kind 10008 profile badges L<Net::Nostr::Event>. C<badges> is an
arrayref of hashrefs, each with C<definition> (badge coordinate),
C<award> (award event id), and optional C<award_relay>. Tags are emitted
as consecutive C<a>/C<e> pairs in order. C<badge_sets> optionally
references kind 30008 badge set coordinates.

=head2 badge_set

    my $event = Net::Nostr::Badge->badge_set(
        pubkey     => $hex_pubkey,                     # required
        identifier => 'my-favorites',                  # required (d tag)
        badges     => [                                # required
            { definition => '30009:pk:id', award => $eid },
        ],
    );

Creates a kind 30008 badge set L<Net::Nostr::Event>. C<identifier> is
required and becomes the C<d> tag. C<badges> uses the same format as
L</profile_badges>.

=head2 from_event

    my $badge = Net::Nostr::Badge->from_event($event);

Parses a badge event into a C<Net::Nostr::Badge> object. Recognizes kinds
30009, 8, 10008, and 30008. Returns C<undef> for unrecognized kinds.

For kind 30009 (definition): C<identifier>, C<name>, C<description>,
C<image>, C<thumbs>.

For kind 8 (award): C<badge>, C<awardees>.

For kind 10008 (profile badges): C<badges>.

For kind 30008 (badge set): C<identifier>, C<badges>.

Deprecated kind 30008 events with C<d=profile_badges> are treated as
equivalent to kind 10008.

Profile badges and badge sets expect consecutive C<a>/C<e> tag pairs.
Unpaired C<a> tags (without a following C<e>) and unpaired C<e> tags
(without a preceding C<a>) are ignored, per the spec recommendation.

=head2 validate

    Net::Nostr::Badge->validate($event);

Validates a NIP-58 badge event. Croaks if:

=over

=item * Kind is not 30009, 8, 10008, or 30008

=item * Kind 30009 missing C<d> tag

=item * Kind 8 missing C<a> tag referencing a kind 30009 definition, or missing C<p> tag

=item * Kind 30008 missing C<d> tag

=back

Returns 1 on success.

=head1 ACCESSORS

=head2 identifier

The C<d> tag value (badge definitions and badge sets).

=head2 name

The badge name (from C<name> tag), or C<undef>.

=head2 description

The badge description (from C<description> tag), or C<undef>.

=head2 image

Arrayref of the image URL and optional dimensions (e.g.
C<['url', '1024x1024']>), or C<undef>.

=head2 thumbs

Arrayref of arrayrefs, each containing a thumbnail URL and optional
dimensions. Defaults to C<[]>.

=head2 badge

The badge definition coordinate (from C<a> tag in award events).

=head2 awardees

Arrayref of arrayrefs, each containing a pubkey and optional relay URL.
Defaults to C<[]>.

=head2 badges

Arrayref of hashrefs for profile badges and badge sets. Each entry has
C<definition>, C<award>, and optional C<award_relay>. Defaults to C<[]>.

=head2 badge_sets

Arrayref of badge set coordinates (from profile badges events).
Defaults to C<[]>.

=head1 SEE ALSO

L<NIP-58|https://github.com/nostr-protocol/nips/blob/master/58.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
