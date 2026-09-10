package Net::Nostr::PaymentTargets;

use strictures 2;
use Net::Nostr::_ConstructorArgs ();
use Net::Nostr::Event;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use URI::Escape ();
use Class::Tiny qw(_tags _content);

sub _validate_target {
    my ($target) = @_;
    croak 'target must contain exactly a type and an address'
        unless ref($target) eq 'ARRAY' && @$target == 2;
    my ($type, $address) = @$target;
    croak 'type must be a lowercase payment type'
        unless defined($type) && !ref($type) && $type =~ /\A[a-z][a-z0-9.-]*\z/;
    croak 'address must be a non-empty string without control characters'
        unless defined($address) && !ref($address) && length($address) && $address !~ /[[:cntrl:]]/;
}

sub new {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my @unknown = grep { $_ ne 'targets' && $_ ne 'content' } keys %args;
    croak 'unknown argument(s): ' . join(', ', sort @unknown) if @unknown;
    croak 'targets must be an array reference' unless ref($args{targets}) eq 'ARRAY';
    $args{content} = '' unless exists $args{content};
    croak 'content must be a string' unless defined($args{content}) && !ref($args{content});
    _validate_target($_) for @{$args{targets}};
    return bless { _tags => [map { ['payto', @$_] } @{$args{targets}}], _content => $args{content} }, $class;
}

sub targets {
    my ($self, @args) = @_;
    croak 'targets is read-only' if @args;
    return [map { [@$_[1,2]] } grep { $_->[0] eq 'payto' } @{$self->_tags}];
}

sub to_event {
    my $self = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    croak 'kind, content, and tags are supplied by the payment targets'
        if grep { exists $args{$_} } qw(kind content tags);
    return Net::Nostr::Event->new(%args, kind=>10133, content=>$self->_content,
        tags=>[map { [@$_] } @{$self->_tags}]);
}

sub from_event {
    my ($class, $event) = @_;
    croak 'event must be a Net::Nostr::Event'
        unless blessed($event) && $event->isa('Net::Nostr::Event');
    croak 'payment target event must be kind 10133' unless $event->kind == 10133;
    # Recheck basic formats in case a caller mutated the Event's accessors.
    my $checked = Net::Nostr::Event->new(%{$event->to_hash});
    my @targets;
    for my $tag (@{$checked->tags}) {
        croak 'target event tags must have a name' unless @$tag;
        next unless $tag->[0] eq 'payto';
        croak 'payto target tag must have exactly three fields' unless @$tag == 3;
        push @targets, [@$tag[1,2]];
    }
    my $self = $class->new(targets=>\@targets, content=>$checked->content);
    $self->_tags([map { [@$_] } @{$checked->tags}]);
    return $self;
}

sub uris {
    my ($self) = @_;
    return [map {
        my ($type, $address) = @$_;
        my $encoded = URI::Escape::uri_escape_utf8($address);
        ($type eq 'bitcoin' || $type eq 'ethereum')
            ? "$type:$encoded" : "payto://$type/$encoded";
    } @{$self->targets}];
}

1;

__END__

=head1 NAME

Net::Nostr::PaymentTargets - NIP-A3 payment target lists

=head1 SYNOPSIS

    use Net::Nostr::PaymentTargets;

    my $list = Net::Nostr::PaymentTargets->new(targets => [
        ['bitcoin', 'bc1qxq66e0t8d7ugdecwnmv58e90tpry23nc84pg9k'],
        ['nano', 'nano_1dctqbmqxfppo9pswbm6kg9d4s4mbraqn8i4m7ob9gnzz91aurmuho48jx3c'],
        ['unknowntype', 'l7tbta5b9xze6ckkfc99uohzxd009b0r'],
    ]);
    my $event = $list->to_event(
        pubkey => 'afc93622eb4d79c0fb75e56e0c14553f7214b0a466abeba14cb38968c6755e6a',
        created_at => 1000,
    );
    my $parsed = Net::Nostr::PaymentTargets->from_event($event);
    my $links = $parsed->uris;

=head1 DESCRIPTION

Builds and parses kind 10133 replaceable payment target lists. Order and
duplicates are preserved, including unknown payment types. An empty list
can replace a previously published list to remove its targets.

The library validates NIP-A3 structure and payment type syntax, but does not
check network-specific address checksums, account existence, or ownership.
Such checks depend on the target network and remain application policy.
No payment is initiated and no URI is opened by this module.

=head1 METHODS

=head2 new

Strict constructor accepting named arguments as either a flat list or a single hash
reference. Requires
C<targets>, an arrayref of pairs C<[$type, $address]>. Types use lowercase
RFC-8905 authority syntax: an ASCII letter followed by letters, digits,
hyphens, or periods. Addresses must be non-empty scalar strings without
control characters. Optional scalar C<content> defaults to an empty string.
Invalid structures and unknown arguments croak. Returned objects contain
structurally valid targets; no deferred validation is required.

=head2 targets

Returns a defensive copy of the ordered target pairs. Read-only.

=head2 to_event

Builds a structurally validated L<Net::Nostr::Event> of kind 10133. Requires
C<pubkey>; accepts other ordinary event fields such as C<created_at> and
C<sig>. The object's kind, content, and tags cannot be overridden. The
result is unsigned unless a signature was supplied; sign with the author's
key before publication. Event field formats are checked by its constructor.

=head2 from_event

Parses a L<Net::Nostr::Event>. Rechecks event field formats, requires kind
10133, and validates every C<payto> tag exactly as the constructor validates
target pairs. Other event tags and content are retained, so parsing then
serializing does not discard metadata or reorder tags. It does not verify
the event ID or signature; authenticate events before trusting their payment
targets. The returned target object requires no later structural validation.

=head2 uris

Returns an ordered arrayref of link strings. Uses C<bitcoin:> and
C<ethereum:> for those types and C<payto://type/address> for every other type,
including unknown ones. The address is encoded as a single UTF-8 URI component
so embedded query or fragment characters remain part of the address.
Type-specific URI options and payment amounts are outside this helper.

=head1 SEE ALSO

L<NIP-A3|https://github.com/nostr-protocol/nips/blob/master/A3.md>,
L<RFC-8905|https://datatracker.ietf.org/doc/html/rfc8905>,
L<Net::Nostr::Event>, L<Net::Nostr::Key>

=cut
