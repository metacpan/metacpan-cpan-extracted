package Net::Nostr::Identifier;

use strictures 2;

use Carp qw(croak);
use JSON ();
use AnyEvent::HTTP;

use Class::Tiny qw(
    base_url
);

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub parse {
    my ($class, $identifier) = @_;
    croak "invalid NIP-05 identifier: missing \@"
        unless defined $identifier && $identifier =~ /@/;
    my @parts = split /@/, $identifier, -1;
    croak "invalid NIP-05 identifier: multiple \@" if @parts > 2;
    my ($local, $domain) = @parts;
    croak "invalid NIP-05 identifier: empty local-part"
        unless length $local;
    croak "invalid NIP-05 identifier: empty domain"
        unless length $domain;
    croak "invalid NIP-05 identifier: local-part contains invalid characters (must be a-z0-9-_.)"
        unless $local =~ /\A[a-z0-9\-_.]+\z/;
    croak "invalid NIP-05 identifier: domain contains invalid characters"
        if $domain =~ m{[\s/:?\#\[\]\x00-\x1f\x7f]};
    return ($local, $domain);
}

sub url {
    my ($class, $identifier) = @_;
    my ($local, $domain) = $class->parse($identifier);
    return "https://$domain/.well-known/nostr.json?name=$local";
}

sub display_name {
    my ($class, $identifier) = @_;
    my ($local, $domain) = $class->parse($identifier);
    return $domain if $local eq '_';
    return $identifier;
}

sub verify_response {
    my ($class, $response, $local_part, $pubkey) = @_;
    return 0 unless ref $response eq 'HASH';
    return 0 unless ref($response->{names}) eq 'HASH';
    my $found = $response->{names}{$local_part};
    return 0 unless defined $found;
    # Keys must be 64-char lowercase hex (32-byte pubkey)
    return 0 unless $found =~ /\A[a-f0-9]{64}\z/;
    return $found eq $pubkey ? 1 : 0;
}

sub extract_relays {
    my ($class, $response, $pubkey) = @_;
    return [] unless ref $response eq 'HASH';
    return [] unless ref($response->{relays}) eq 'HASH';
    my $list = $response->{relays}{$pubkey};
    return [] unless ref $list eq 'ARRAY';
    return $list;
}

sub _fetch {
    my ($self, $url, $cb) = @_;
    http_get $url,
        recurse => 0,  # MUST ignore redirects
        sub {
            my ($body, $headers) = @_;
            $cb->($body, $headers);
        };
}

sub _build_fetch_url {
    my ($self, $identifier) = @_;
    my ($local, $domain) = Net::Nostr::Identifier->parse($identifier);
    if (defined $self->base_url) {
        return ($self->base_url . "/.well-known/nostr.json?name=$local", $local);
    }
    return ("https://$domain/.well-known/nostr.json?name=$local", $local);
}

sub verify {
    my ($self, %args) = @_;
    my $identifier = $args{identifier} // croak "identifier required";
    my $pubkey     = $args{pubkey}     // croak "pubkey required";
    my $on_success = $args{on_success} // croak "on_success callback required";
    croak "on_success must be a CODE ref" unless ref($on_success) eq 'CODE';
    my $on_failure = $args{on_failure} // croak "on_failure callback required";
    croak "on_failure must be a CODE ref" unless ref($on_failure) eq 'CODE';

    my ($url, $local) = $self->_build_fetch_url($identifier);

    $self->_fetch($url, sub {
        my ($body, $headers) = @_;

        # Check for redirect (status 3xx)
        if ($headers->{Status} =~ /^3/) {
            $on_failure->("redirect: server returned HTTP $headers->{Status}");
            return;
        }

        unless ($headers->{Status} =~ /^2/) {
            $on_failure->("HTTP error: $headers->{Status} $headers->{Reason}");
            return;
        }

        my $response = eval { JSON::decode_json($body) };
        unless ($response) {
            $on_failure->("invalid JSON response");
            return;
        }

        if (Net::Nostr::Identifier->verify_response($response, $local, $pubkey)) {
            my $relays = Net::Nostr::Identifier->extract_relays($response, $pubkey);
            $on_success->($relays);
        } else {
            $on_failure->("pubkey mismatch for $local");
        }
    });
}

sub lookup {
    my ($self, %args) = @_;
    my $identifier = $args{identifier} // croak "identifier required";
    my $on_success = $args{on_success} // croak "on_success callback required";
    croak "on_success must be a CODE ref" unless ref($on_success) eq 'CODE';
    my $on_failure = $args{on_failure} // croak "on_failure callback required";
    croak "on_failure must be a CODE ref" unless ref($on_failure) eq 'CODE';

    my ($url, $local) = $self->_build_fetch_url($identifier);

    $self->_fetch($url, sub {
        my ($body, $headers) = @_;

        if ($headers->{Status} =~ /^3/) {
            $on_failure->("redirect: server returned HTTP $headers->{Status}");
            return;
        }

        unless ($headers->{Status} =~ /^2/) {
            $on_failure->("HTTP error: $headers->{Status} $headers->{Reason}");
            return;
        }

        my $response = eval { JSON::decode_json($body) };
        unless ($response) {
            $on_failure->("invalid JSON response");
            return;
        }

        unless (ref($response->{names}) eq 'HASH' && defined $response->{names}{$local}) {
            $on_failure->("name '$local' not found");
            return;
        }

        my $pubkey = $response->{names}{$local};
        unless ($pubkey =~ /\A[a-f0-9]{64}\z/) {
            $on_failure->("invalid pubkey format");
            return;
        }

        my $relays = Net::Nostr::Identifier->extract_relays($response, $pubkey);
        $on_success->($pubkey, $relays);
    });
}

1;

=head1 NAME

Net::Nostr::Identifier - Mapping Nostr keys to DNS-based internet identifiers

=head1 SYNOPSIS

    use AnyEvent;
    use Net::Nostr::Identifier;

    my $pubkey = 'b0635d6a9851d3aed0cd6c495b282167acf761729078d975fc341b22650b07b9';

    # Parse and validate an identifier
    my ($local, $domain) = Net::Nostr::Identifier->parse('bob@example.com');

    # Build the well-known URL
    my $url = Net::Nostr::Identifier->url('bob@example.com');
    # https://example.com/.well-known/nostr.json?name=bob

    # Display name (root identifier _@domain shows as domain)
    Net::Nostr::Identifier->display_name('bob@example.com');  # "bob@example.com"
    Net::Nostr::Identifier->display_name('_@bob.com');         # "bob.com"

    # Verify a nostr.json response
    my $response = { names => { bob => $pubkey } };
    if (Net::Nostr::Identifier->verify_response($response, 'bob', $pubkey)) {
        print "Verified!\n";
    }

    # Async verification via HTTP (requires an AnyEvent loop)
    my $cv = AnyEvent->condvar;
    my $ident = Net::Nostr::Identifier->new;
    $ident->verify(
        identifier => 'bob@example.com',
        pubkey     => $pubkey,
        on_success => sub { my ($relays) = @_; print "Verified!\n"; $cv->send },
        on_failure => sub { my ($reason) = @_; warn "Failed: $reason"; $cv->send },
    );
    $cv->recv;

    # Async lookup (find pubkey from identifier)
    $cv = AnyEvent->condvar;
    $ident->lookup(
        identifier => 'bob@example.com',
        on_success => sub { my ($pubkey, $relays) = @_; $cv->send },
        on_failure => sub { my ($reason) = @_; $cv->send },
    );
    $cv->recv;

=head1 DESCRIPTION

Implements NIP-05 for mapping Nostr public keys to DNS-based internet
identifiers. An identifier has the form C<local-part@domain> where the
local-part uses only characters C<a-z0-9-_.>.

Clients verify an identifier by fetching
C<https://E<lt>domainE<gt>/.well-known/nostr.json?name=E<lt>local-partE<gt>>
and checking that the returned C<"names"> mapping contains the expected
public key.

The special identifier C<_@domain> is treated as a root identifier and
may be displayed as just the domain.

=head1 CLASS METHODS

=head2 parse

    my ($local_part, $domain) = Net::Nostr::Identifier->parse('bob@example.com');

Splits an identifier into its local-part and domain. Strictly validates
both parts. Croaks if the identifier is invalid:

=over 4

=item * missing or multiple C<@>

=item * empty local-part or domain

=item * local-part contains characters outside C<a-z0-9-_.>

=item * domain contains whitespace, C</>, C<:>, C<?>, C<#>, C<[>, C<]>, or control characters

=back

Bracketed IPv6 addresses (e.g. C<[::1]>) are rejected because NIP-05 is
DNS-based. Ports are rejected because the spec constructs HTTPS URLs from
the domain directly.

=head2 url

    my $url = Net::Nostr::Identifier->url('bob@example.com');

Returns the well-known URL for verifying the identifier.

=head2 display_name

    my $name = Net::Nostr::Identifier->display_name('bob@example.com');  # "bob@example.com"
    my $root = Net::Nostr::Identifier->display_name('_@bob.com');        # "bob.com"

Returns the display form of the identifier. Root identifiers (C<_@domain>)
are displayed as just the domain. All other identifiers are returned as-is.

=head2 verify_response

    my $ok = Net::Nostr::Identifier->verify_response($hashref, $local_part, $pubkey);

Returns true if the response hashref maps the given local-part to the given
pubkey. Keys must be 64-character lowercase hex (32-byte public keys).

=head2 extract_relays

    my $relays = Net::Nostr::Identifier->extract_relays($hashref, $pubkey);

Returns an arrayref of relay URLs for the given pubkey, or an empty arrayref
if none are found.

=head1 CONSTRUCTOR

=head2 new

    my $ident = Net::Nostr::Identifier->new(%args);

Croaks on unknown arguments.

=over 4

=item base_url

Optional base URL override for testing. When set, HTTP requests go to
this URL instead of C<https://E<lt>domainE<gt>>.

=back

=head1 INSTANCE METHODS

=head2 verify

    $ident->verify(
        identifier => 'bob@example.com',
        pubkey     => $hex_pubkey,
        on_success => sub { my ($relays) = @_ },
        on_failure => sub { my ($reason) = @_ },
    );

Asynchronously fetches the well-known URL and verifies that the identifier
maps to the given pubkey. HTTP redirects are ignored per the spec. Requires
an L<AnyEvent> event loop to be running. Croaks if any required argument is
missing or if C<on_success>/C<on_failure> are not CODE refs.

The C<on_success> callback receives an arrayref of relay URLs (may be empty).
The C<on_failure> callback receives an error reason string.

=head2 lookup

    $ident->lookup(
        identifier => 'bob@example.com',
        on_success => sub { my ($pubkey, $relays) = @_ },
        on_failure => sub { my ($reason) = @_ },
    );

Asynchronously fetches the well-known URL and returns the pubkey associated
with the identifier. HTTP redirects are ignored per the spec. Requires
an L<AnyEvent> event loop to be running. Croaks if any required argument is
missing or if C<on_success>/C<on_failure> are not CODE refs.

The C<on_success> callback receives the hex pubkey and an arrayref of relay
URLs. The C<on_failure> callback receives an error reason string.

=head1 SECURITY

The C</.well-known/nostr.json> endpoint B<MUST NOT> return any HTTP redirects.
This module ignores all HTTP redirects, treating them as verification failures.

=head1 SEE ALSO

L<NIP-05|https://github.com/nostr-protocol/nips/blob/master/05.md>

=cut
