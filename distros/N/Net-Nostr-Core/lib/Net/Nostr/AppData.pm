package Net::Nostr::AppData;

use strictures 2;

use Net::Nostr::_ConstructorArgs ();

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(
    kind
    d_tag
    content
    extra_tags
);

sub new {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    $args{extra_tags} //= [];
    my $self = bless { %args }, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub to_event {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);

    my $kind = delete $args{kind} // 30078;
    croak "app data event MUST be kind 78 or 30078"
        unless $kind == 78 || $kind == 30078;

    my $d_tag = delete $args{d_tag};
    croak "to_event requires 'd_tag'" if $kind == 30078 && !defined $d_tag;

    my @tags;
    push @tags, ['d', $d_tag] if defined $d_tag;

    my $extra = delete $args{extra_tags};
    if ($extra) {
        push @tags, @$extra;
    }

    return Net::Nostr::Event->new(
        %args,
        kind    => $kind,
        content => $args{content} // '',
        tags    => \@tags,
    );
}

sub from_event {
    my ($class, $event) = @_;
    return undef unless $event->kind == 78 || $event->kind == 30078;

    my $d_tag;
    my @extra;

    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'd') {
            $d_tag = $tag->[1];
        } else {
            push @extra, $tag;
        }
    }

    return $class->new(
        kind       => $event->kind,
        d_tag      => $d_tag,
        content    => $event->content // '',
        extra_tags => \@extra,
    );
}

sub validate {
    my ($class, $event) = @_;

    croak "app data event MUST be kind 78 or 30078"
        unless $event->kind == 78 || $event->kind == 30078;

    return 1 if $event->kind == 78;

    my $has_d;
    for my $tag (@{$event->tags}) {
        $has_d = 1 if $tag->[0] eq 'd';
    }
    croak "app data event MUST have a 'd' tag" unless $has_d;

    return 1;
}

1;

__END__


=head1 NAME

Net::Nostr::AppData - NIP-78 Arbitrary Custom App Data

=head1 SYNOPSIS

    use Net::Nostr::AppData;

    # Store app-specific data
    my $event = Net::Nostr::AppData->to_event(
        pubkey  => $pubkey,
        d_tag   => 'com.example.myapp/settings',
        content => '{"theme":"dark","fontSize":14}',
    );

    # Store multiple normal app data events
    my $entry = Net::Nostr::AppData->to_event(
        pubkey  => $pubkey,
        kind    => 78,
        content => '{"entry":1}',
    );

    # Parse app data from an event
    my $ad = Net::Nostr::AppData->from_event($event);
    say $ad->d_tag;    # com.example.myapp/settings
    say $ad->content;  # {"theme":"dark","fontSize":14}

    # Validate
    Net::Nostr::AppData->validate($event);

=head1 DESCRIPTION

Implements NIP-78 (Arbitrary Custom App Data). Provides
L<remoteStorage|https://remotestorage.io/>-like capabilities for custom
applications that do not care about interoperability.

Kind 30078 is the default addressable event form. The C<d> tag contains a
reference to the app name and context (or any other arbitrary string).
Kind 78 is a normal event form for app data that should not replace prior
events. The C<content> and other tags can be anything or in any format.

Use cases include:

=over 4

=item * User personal settings on Nostr clients

=item * Dynamic parameters propagated from client developers to users

=item * Private data for apps that use Nostr relays as a personal database

=back

=head1 CONSTRUCTOR

=head2 new

Accepts named arguments as either a flat list or a single hash reference.

    my $ad = Net::Nostr::AppData->new(
        kind    => 30078,
        d_tag   => 'myapp-settings',
        content => '{"theme":"dark"}',
    );

Creates a new C<Net::Nostr::AppData> object. All fields are optional.
C<extra_tags> defaults to C<[]>. Croaks on unknown arguments.
Typically returned by L</from_event>.

=head1 CLASS METHODS

=head2 to_event

    my $event = Net::Nostr::AppData->to_event(
        pubkey     => $hex_pubkey,
        kind       => 30078,
        d_tag      => 'com.example.myapp/settings',
        content    => '{"theme":"dark","fontSize":14}',
        extra_tags => [['version', '2']],
        created_at => time(),
    );

Creates a NIP-78 L<Net::Nostr::Event>. C<kind> defaults to C<30078>;
C<78> may be supplied for normal app data events. C<d_tag> is required
for kind 30078 and optional for kind 78. C<content> defaults to empty string.
C<extra_tags>, if provided, are appended after any C<d> tag. Any
remaining arguments are passed through to L<Net::Nostr::Event/new>.

=head2 from_event

    my $ad = Net::Nostr::AppData->from_event($event);

Parses a kind 78 or 30078 event into a C<Net::Nostr::AppData> object.
Returns C<undef> if the event kind is not 78 or 30078.

    my $ad = Net::Nostr::AppData->from_event($event);
    say $ad->d_tag;
    say $ad->content;

=head2 validate

    Net::Nostr::AppData->validate($event);

Validates a NIP-78 event. Kind must be 78 or 30078. Kind 30078 requires
a C<d> tag; kind 78 does not. Croaks if invalid. Returns 1 on success.

    eval { Net::Nostr::AppData->validate($event) };
    warn "Invalid: $@" if $@;

=head1 ACCESSORS

=head2 kind

The app data event kind, C<78> or C<30078>, when parsed from an event.

=head2 d_tag

The application identifier string from the C<d> tag. Can be any
arbitrary string referencing the app name and context.

=head2 content

The event content. Can be any format (JSON, plain text, etc.).

=head2 extra_tags

Arrayref of additional tags beyond the C<d> tag. Can be anything
in any format.

=head1 SEE ALSO

L<NIP-78|https://github.com/nostr-protocol/nips/blob/master/78.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
