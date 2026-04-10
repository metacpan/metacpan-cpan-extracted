package Net::Nostr::Metadata;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Net::Nostr::Event;

use Class::Tiny qw(
    name
    display_name
    about
    picture
    website
    banner
    bot
    birthday
);

my $JSON = JSON->new->utf8->canonical;

# Fields to serialize into the kind 0 content JSON.
my @CONTENT_FIELDS = qw(name display_name about picture website banner bot birthday);

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub to_event {
    my ($class, %args) = @_;

    my %content;
    for my $field (@CONTENT_FIELDS) {
        next unless exists $args{$field};
        $content{$field} = delete $args{$field};
    }

    return Net::Nostr::Event->new(
        %args,
        kind    => 0,
        content => $JSON->encode(\%content),
        tags    => $args{tags} // [],
    );
}

sub from_event {
    my ($class, $event) = @_;
    return undef unless $event->kind == 0;

    my $data = eval { $JSON->decode($event->content) } // {};

    # Map deprecated fields
    $data->{display_name} //= $data->{displayName} if exists $data->{displayName};
    $data->{name}         //= $data->{username}     if exists $data->{username};

    my %attrs;
    for my $field (@CONTENT_FIELDS) {
        $attrs{$field} = $data->{$field} if exists $data->{$field};
    }

    return $class->new(%attrs);
}

sub validate {
    my ($class, $event) = @_;

    croak "metadata event MUST be kind 0" unless $event->kind == 0;

    eval { $JSON->decode($event->content) };
    croak "metadata content MUST be valid JSON: $@" if $@;

    return 1;
}

sub hashtag_tag {
    my ($class, $value) = @_;
    return ['t', lc $value];
}

sub url_tag {
    my ($class, $url) = @_;
    return ['r', $url];
}

sub title_tag {
    my ($class, $title) = @_;
    return ['title', $title];
}

sub external_id_tag {
    my ($class, $id) = @_;
    return ['i', $id];
}

1;

__END__


=head1 NAME

Net::Nostr::Metadata - NIP-24 Extra Metadata Fields and Tags

=head1 SYNOPSIS

    use Net::Nostr::Metadata;

    # Create a profile metadata event (kind 0)
    my $event = Net::Nostr::Metadata->to_event(
        pubkey       => $hex_pubkey,
        name         => 'alice',
        display_name => 'Alice in Wonderland',
        about        => 'Nostr enthusiast',
        picture      => 'https://example.com/avatar.jpg',
        website      => 'https://alice.example.com',
        banner       => 'https://example.com/banner.jpg',
        bot          => JSON::false,
        birthday     => { year => 1990, month => 6, day => 15 },
    );

    # Parse metadata from an event
    my $meta = Net::Nostr::Metadata->from_event($event);
    say $meta->name;          # alice
    say $meta->display_name;  # Alice in Wonderland

    # Validate
    Net::Nostr::Metadata->validate($event);

    # Standard tag helpers
    my $tag = Net::Nostr::Metadata->hashtag_tag('NoStr');  # ['t', 'nostr']
    my $url = Net::Nostr::Metadata->url_tag('https://example.com');
    my $title = Net::Nostr::Metadata->title_tag('My Event');
    my $ext = Net::Nostr::Metadata->external_id_tag('github:torvalds');

=head1 DESCRIPTION

Implements NIP-24 (Extra Metadata Fields and Tags). Provides a builder and
parser for kind 0 metadata events with the extra fields defined by this NIP,
plus standard tag helper methods.

Kind 0 is a replaceable event. The C<content> is a stringified JSON object
containing the user's profile metadata. NIP-01 defines C<name>, C<about>,
and C<picture>. This NIP adds:

=over 4

=item * C<display_name> - an alternative, bigger name with richer characters

=item * C<website> - a web URL related to the event author

=item * C<banner> - a URL to a wide (~1024x768) background image

=item * C<bot> - a boolean indicating automated content

=item * C<birthday> - an object with optional C<year>, C<month>, C<day> fields

=back

C<name> should always be set regardless of C<display_name>.

=head2 Deprecated fields

When parsing, the deprecated C<displayName> field is mapped to
C<display_name>, and C<username> is mapped to C<name>. The canonical
field takes precedence if both are present. These deprecated fields
are never emitted by L</to_event>.

=head2 Standard tags

NIP-24 defines standard tag meanings across event kinds:

=over 4

=item * C<t> - hashtag (value MUST be lowercase)

=item * C<r> - a web URL the event refers to

=item * C<title> - name of sets, calendar/live events, or listings

=item * C<i> - external ID (see NIP-73)

=back

=head1 CONSTRUCTOR

=head2 new

    my $meta = Net::Nostr::Metadata->new(
        name         => 'alice',
        display_name => 'Alice',
    );

Creates a new C<Net::Nostr::Metadata> object. All fields are optional.
Croaks on unknown arguments. Typically returned by L</from_event>.

=head1 CLASS METHODS

=head2 to_event

    my $event = Net::Nostr::Metadata->to_event(
        pubkey       => $hex_pubkey,          # required
        name         => 'alice',              # recommended
        display_name => 'Alice',              # optional
        about        => 'Hello',              # optional
        picture      => 'https://...',        # optional
        website      => 'https://...',        # optional
        banner       => 'https://...',        # optional
        bot          => JSON::true,           # optional
        birthday     => { year => 1990 },     # optional
        created_at   => time(),               # optional
    );

Creates a kind 0 metadata L<Net::Nostr::Event>. The metadata fields are
serialized as a JSON object in the event content. Only provided fields
are included in the JSON. Any remaining arguments are passed through to
L<Net::Nostr::Event/new>.

=head2 from_event

    my $meta = Net::Nostr::Metadata->from_event($event);

Parses a kind 0 event into a C<Net::Nostr::Metadata> object. Returns
C<undef> if the event kind is not 0. Handles deprecated field names
(C<displayName> -> C<display_name>, C<username> -> C<name>). Unknown
fields in the JSON are silently ignored (other NIPs define additional
fields like C<nip05>, C<lud16>, etc.).

=head2 validate

    Net::Nostr::Metadata->validate($event);

Validates a kind 0 metadata event. Croaks if the kind is not 0 or the
content is not valid JSON. Returns 1 on success.

=head2 hashtag_tag

    my $tag = Net::Nostr::Metadata->hashtag_tag('NoStr');  # ['t', 'nostr']

Returns a C<t> tag arrayref. The value is lowercased per the spec
requirement that hashtag values MUST be lowercase.

=head2 url_tag

    my $tag = Net::Nostr::Metadata->url_tag('https://example.com');

Returns an C<r> tag arrayref for a web URL the event refers to.

=head2 title_tag

    my $tag = Net::Nostr::Metadata->title_tag('My Event');

Returns a C<title> tag arrayref.

=head2 external_id_tag

    my $tag = Net::Nostr::Metadata->external_id_tag('github:torvalds');

Returns an C<i> tag arrayref for an external ID the event refers to.
See NIP-73 for external ID formats.

=head1 ACCESSORS

=head2 name

The user's name (NIP-01). Should always be set.

=head2 display_name

An alternative, bigger name with richer characters than C<name>.

=head2 about

A description of the user.

=head2 picture

A URL to the user's avatar image.

=head2 website

A web URL related to the user.

=head2 banner

A URL to a wide (~1024x768) background image for the profile.

=head2 bot

A boolean (C<JSON::true>/C<JSON::false>) indicating the content is
entirely or partially automated.

=head2 birthday

A hashref with optional C<year>, C<month>, and C<day> keys representing
the user's birth date. Each field MAY be omitted.

=head1 SEE ALSO

L<NIP-24|https://github.com/nostr-protocol/nips/blob/master/24.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
