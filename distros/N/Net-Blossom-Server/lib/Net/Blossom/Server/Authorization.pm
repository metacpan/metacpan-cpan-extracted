package Net::Blossom::Server::Authorization;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();
use Net::Blossom::Server::AuthorizationResult;
use Net::Blossom::Server::Error;
use Net::Blossom::Server::Request;

use Carp qw(croak);
use Class::Tiny qw(_domains clock clock_skew_seconds);
use JSON ();
use MIME::Base64 qw(decode_base64);
use Net::Nostr::Event;
use Scalar::Util qw(blessed);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;
my $DOMAIN = qr/\A[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)*\z/;
my $JSON = JSON->new->utf8;

sub new {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(domains clock clock_skew_seconds);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    $args{domains} = [] unless defined $args{domains};
    croak "domains must be an array reference" unless ref($args{domains}) eq 'ARRAY';
    for my $domain (@{$args{domains}}) {
        croak "domain must be a lowercase domain name"
            unless defined $domain && !ref($domain) && _valid_domain($domain);
    }
    $args{_domains} = [@{$args{domains}}];
    delete $args{domains};

    $args{clock} = sub { time } unless defined $args{clock};
    croak "clock must be a code reference" unless ref($args{clock}) eq 'CODE';

    $args{clock_skew_seconds} = 30 unless defined $args{clock_skew_seconds};
    croak "clock_skew_seconds must be a non-negative integer"
        unless $args{clock_skew_seconds} =~ /\A\d+\z/;

    return bless \%args, $class;
}

sub domains {
    my ($self) = @_;
    return [@{$self->_domains}];
}

sub authorize_request {
    my ($self, $request) = @_;
    my $result = $self->authorize($request);
    return defined $result ? $result->pubkey : undef;
}

sub authorize {
    my ($self, $request) = @_;
    croak "request must be a Net::Blossom::Server::Request"
        unless blessed($request) && $request->isa('Net::Blossom::Server::Request');

    my $requirements = _request_requirements($request);
    return undef unless defined $requirements;

    my $event = $self->_event_from_authorization_header($request->header('authorization'));
    return $self->_validate_event($event, %$requirements);
}

sub _request_requirements {
    my ($request) = @_;

    if ($request->path eq '/upload' && ($request->method eq 'PUT' || $request->method eq 'HEAD')) {
        my $sha256 = _required_sha256_header($request);
        return {
            action        => 'upload',
            sha256        => $sha256,
            hash_required => 1,
        };
    }

    if ($request->path eq '/media' && ($request->method eq 'PUT' || $request->method eq 'HEAD')) {
        my $sha256 = _required_sha256_header($request);
        return {
            action        => 'media',
            sha256        => $sha256,
            hash_required => 1,
        };
    }

    if ($request->path eq '/mirror' && $request->method eq 'PUT') {
        return {
            action        => 'upload',
            hash_required => 1,
            deferred_hash => 1,
        };
    }

    if ($request->path =~ m{\A/([0-9a-f]{64})(?:\.[^/]+)?\z}) {
        return {
            action        => 'get',
            sha256        => $1,
            hash_required => 0,
        } if $request->method eq 'GET' || $request->method eq 'HEAD';
    }

    if ($request->path =~ m{\A/([0-9a-f]{64})\z}) {
        return {
            action        => 'delete',
            sha256        => $1,
            hash_required => 1,
        } if $request->method eq 'DELETE';

        return undef;
    }

    if ($request->path =~ m{\A/list/[0-9a-f]{64}\z} && $request->method eq 'GET') {
        return {
            action        => 'list',
            hash_required => 0,
        };
    }

    return undef;
}

sub _required_sha256_header {
    my ($request) = @_;
    my $sha256 = $request->header('x-sha-256');
    _unauthorized('missing X-SHA-256 header') unless defined $sha256 && length $sha256;
    _unauthorized('X-SHA-256 must be 64-char lowercase hex') unless $sha256 =~ $HEX64;
    return $sha256;
}

sub _event_from_authorization_header {
    my ($self, $header) = @_;
    _unauthorized('authorization header is required')
        unless defined $header && length $header;

    my ($scheme, $payload) = split /\s+/, $header, 2;
    _unauthorized('expected Nostr authorization scheme')
        unless defined $scheme && $scheme eq 'Nostr';
    _unauthorized('authorization payload is required')
        unless defined $payload && length $payload;
    _unauthorized('authorization payload must be base64url')
        unless $payload =~ /\A[A-Za-z0-9_-]+\z/ && length($payload) % 4 != 1;

    my $b64 = $payload;
    $b64 =~ tr{-_}{+/};
    $b64 .= '=' while length($b64) % 4;
    my $json = decode_base64($b64);
    _unauthorized('authorization payload is empty')
        unless defined $json && length $json;

    my $data = eval { $JSON->decode($json) };
    _unauthorized('authorization payload must be JSON object')
        if $@ || ref($data) ne 'HASH';

    my $event = eval { Net::Nostr::Event->from_wire($data) };
    _unauthorized('authorization event is invalid') if $@;

    eval { $event->validate; 1 }
        or _unauthorized('authorization signature is invalid');

    return $event;
}

sub _validate_event {
    my ($self, $event, %requirements) = @_;
    my $now = $self->clock->();

    _unauthorized('authorization kind must be 24242')
        unless $event->kind == 24242;
    my $clock_skew_seconds = $self->clock_skew_seconds;
    my $created_at_ok = $clock_skew_seconds
        ? $event->created_at <= $now + $clock_skew_seconds
        : $event->created_at < $now;
    _unauthorized('authorization created_at is too far in the future')
        unless $created_at_ok;

    my $expiration = _first_tag_value($event, 'expiration');
    _unauthorized('authorization expiration tag is required')
        unless defined $expiration;
    _unauthorized('authorization expiration must be a non-negative integer')
        unless $expiration =~ /\A\d+\z/;
    _unauthorized('authorization token is expired')
        unless $expiration > $now;

    my @actions = _tag_values($event, 't');
    _unauthorized('authorization action tag is required')
        unless @actions;
    _unauthorized('authorization action does not match request')
        unless grep { $_ eq $requirements{action} } @actions;

    my @servers = _tag_values($event, 'server');
    if (@servers) {
        my %allowed = map { $_ => 1 } @{$self->_domains};
        _unauthorized('authorization server scope does not match')
            unless grep { $allowed{$_} } @servers;
    }

    my @hashes = _tag_values($event, 'x');
    for my $hash (@hashes) {
        _unauthorized('authorization x tag must be 64-char lowercase hex')
            unless defined $hash && $hash =~ $HEX64;
    }

    if ($requirements{hash_required}) {
        _unauthorized('authorization x tag is required')
            unless @hashes;
        if (!$requirements{deferred_hash}) {
            _unauthorized('authorization x tag does not match request hash')
                unless grep { $_ eq $requirements{sha256} } @hashes;
        }
    }
    elsif (defined $requirements{sha256} && @hashes) {
        _unauthorized('authorization x tag does not match request hash')
            unless grep { $_ eq $requirements{sha256} } @hashes;
    }

    return Net::Blossom::Server::AuthorizationResult->new(
        pubkey => $event->pubkey,
        action => $requirements{action},
        hashes => \@hashes,
    );
}

sub _tag_values {
    my ($event, $name) = @_;
    my @values;
    for my $tag (@{$event->tags}) {
        next unless @$tag >= 2 && defined $tag->[0] && $tag->[0] eq $name;
        push @values, $tag->[1];
    }
    return @values;
}

sub _first_tag_value {
    my ($event, $name) = @_;
    my @values = _tag_values($event, $name);
    return $values[0];
}

sub _unauthorized {
    my ($reason) = @_;
    Net::Blossom::Server::Error->throw(
        status  => 401,
        reason  => $reason,
        headers => { 'WWW-Authenticate' => 'Nostr' },
    );
}

sub _valid_domain {
    my ($domain) = @_;
    return length($domain) <= 253 && $domain =~ $DOMAIN;
}

1;

=pod

=head1 NAME

Net::Blossom::Server::Authorization - BUD-11 server authorization verifier

=head1 SYNOPSIS

    use Net::Blossom::Server::Authorization;

    my $auth = Net::Blossom::Server::Authorization->new(
        domains => ['cdn.example.com'],
    );

    my $pubkey = $auth->authorize_request($request);
    my $result = $auth->authorize($request);

=head1 DESCRIPTION

C<Net::Blossom::Server::Authorization> validates BUD-11 Blossom authorization
tokens. It parses C<Nostr> authorization headers, verifies the Nostr event ID
and signature with C<Net::Nostr::Event>, checks the BUD-11 tags, and returns the
event pubkey.

Authorization failures throw C<Net::Blossom::Server::Error> with status C<401>
and C<WWW-Authenticate: Nostr>.

=head1 CONSTRUCTOR

=head2 new

    my $auth = Net::Blossom::Server::Authorization->new(%args);

Optional arguments:

=over 4

=item * C<domains>

Array reference of lowercase server domain names. These are used to validate
BUD-11 C<server> tags. They are domains only, not URLs.

=item * C<clock>

Code reference returning the current Unix timestamp. Defaults to C<time>.

=item * C<clock_skew_seconds>

Non-negative integer number of seconds by which C<created_at> may be ahead of
the verifier clock. Defaults to C<30>. Set to C<0> to require C<created_at> to
be strictly in the past.

=back

Unknown arguments or invalid values croak.

=head1 ACCESSORS

=head2 domains

Returns a copy array reference of configured server domains.

=head2 clock

Returns the clock code reference.

=head2 clock_skew_seconds

Returns the accepted C<created_at> clock skew in seconds.

=head1 METHODS

=head2 authorize_request

    my $pubkey = $auth->authorize_request($request);

Validates the request's BUD-11 C<Authorization> header and returns the verified
event pubkey. The request must be a C<Net::Blossom::Server::Request>.

=head2 authorize

    my $result = $auth->authorize($request);

Validates the request and returns a
L<Net::Blossom::Server::AuthorizationResult>. This method is useful for
endpoints such as C<PUT /mirror>, where the authorized hash is not known until
after the server fetches and hashes the origin blob.

Implemented endpoint requirements are C<GET /E<lt>sha256E<gt>>,
C<HEAD /E<lt>sha256E<gt>>, C<PUT /upload>, C<HEAD /upload>,
C<DELETE /E<lt>sha256E<gt>>, C<GET /list/E<lt>pubkeyE<gt>>,
C<PUT /mirror>, C<PUT /media>, and C<HEAD /media>. Unknown routes return
C<undef> so the server core can return its normal routing response.

=cut
