package Protocol::UWSGI;
# ABSTRACT: support for the UWSGI protocol
use strict;
use warnings;

use parent qw(Exporter);

our $VERSION = '1.000';

=head1 NAME

Protocol::UWSGI - handle the UWSGI wire protocol

=head1 VERSION

Version 1.000

=head1 SYNOPSIS

 use strict;
 use warnings;
 use Protocol::UWSGI qw(:all);
 # Encode...
 my $req = build_request(
   uri    => 'http://localhost',
   method => 'GET',
   remote => '1.2.3.4:1234',
 );
 # ... and decode again
 warn "URI was " . uri_from_env(
   extract_frame(\$req)
 );

=head1 DESCRIPTION

Provides protocol-level support for UWSGI packet generation/decoding, as
defined by L<http://uwsgi-docs.readthedocs.org/en/latest/Protocol.html>.
Currently expects to deal with PSGI data (modifier 1 == 5), although this
may be extended later if there's any demand for the other packet types.

This is unlikely to be useful in an application - it's intended to provide
support for dealing with the protocol in an existing framework: it deals
with the abstract protocol only, and has no network transport handling at
all. Try L<Net::Async::UWSGI> for an implementation that actually does
something useful.

Typically you'd create a UNIX socket and listen for requests, passing
any data to the L</extract_frame> function and handling the resulting
data if that function returns something other than undef:

 # Detect read - first packet is usually the UWSGI header, everything
 # after that would be the HTTP request body if there is one:
 sub on_read {
   my ($self, $buffref) = @_;
   while(my $pkt = extract_frame($buffref)) {
     $self->handle_uwsgi($pkt);
   }
 }

 # and probably an EOF handler to detect client hangup
 # sub on_eof { ... }

=head1 IMPLEMENTATION - Server

A server implementation typically accepts requests from a reverse
proxy, such as nginx, and returns HTTP responses.

Import the :server tag to get L</uri_from_env>, L</extract_frame>
and in future maybe L</psgi_from_env> functions:

 use Protocol::UWSGI qw(:server);

=head1 IMPLEMENTATION - Client

A client implementation typically accepts HTTP requests and converts
them to UWSGI for passing to a UWSGI-capable application.

Import the :client tag to get L</build_request>:

 use Protocol::UWSGI qw(:client);

=cut

use Encode ();
use URI;

use constant {
	PSGI_MODIFIER1 => 5,
	PSGI_MODIFIER2 => 0,
};

our @EXPORT_OK = qw(
	extract_frame
	uri_from_env

	build_request

	PSGI_MODIFIER1
	PSGI_MODIFIER2
);
our %EXPORT_TAGS = (
	'server' => [qw(extract_frame uri_from_env)],
	'client' => [qw(build_request)],
	'all' => \@EXPORT_OK
);

=head1 FUNCTIONS

If you're handling incoming UWSGI requests, you'll need to instantiate
via L</new> then decode the request using L</extract_frame>.

If you're making UWSGI requests against an external UWSGI server,
that'll be L</build_request>.

Just want to decode captured traffic? L</extract_frame> again.

=cut

=head2 extract_frame

Attempts to extract a single UWSGI packet from the given buffer (which
should be passed as a scalar ref, e.g.

 my $buffref = \"...";
 my $req = Protocol::UWSGI->extract_frame($buffref)
   or die "could not find UWSGI frame";

If we had enough data for a packet, that packet will be removed from
the buffer and returned. There may be additional packet data that
can be extracted, or non-UWSGI data such as HTTP request body.

If this returns undef, there's not enough data to process - in this case,
the buffer is guaranteed not to be modified.

This may be called as a class method or an instance method.
The instance state will remain unchanged after calling this method.

Note that there is no constructor provided in this
class - if you want to call this as an instance method,
you'll need to bless manually or be applying this as
a role/mixin.

=cut

sub extract_frame {
	my ($buffref) = @_;

	my ($modifier1, $length, $modifier2) = unpack 'C1v1C1', $$buffref;
	# no, still too short
	return undef unless $length && length $$buffref >= $length + 4;

	# then do the modifier-specific handling
	die "Unsupported modifier1 $modifier1" unless $modifier1 == PSGI_MODIFIER1;

	# hack bits off the buffer
	substr $$buffref, 0, 4, '';

	my %env = unpack '(v1/a*)*', substr $$buffref, 0, $length, '';
	\%env
}

# For cases where non-PSGI modifiers are wanted. Takes about 2.5x as long.
sub extract_frame_universal {
	my $buffref = shift;
	# too short
	return undef unless length $$buffref >= 4;

	my ($modifier1, $length, $modifier2) = unpack 'C1v1C1', $$buffref;
	# no, still too short
	return undef unless length $$buffref >= $length + 4;

	# hack bits off the buffer
	substr $$buffref, 0, 4, '';

	# then do the modifier-specific handling
	return extract_modifier(
		modifier1 => $modifier1,
		modifier2 => $modifier2,
		length    => $length,
		buffer    => $buffref,
	);
}

=head2 bytes_required

Returns the number of additional bytes we'll need in order to proceed.

If zero, this means we should be able to extract a valid frame.

=cut

sub bytes_required {
	my $buffref = shift;
	return 4 - length($$buffref) unless length $$buffref >= 4;

	(undef, my $length) = unpack 'C1v1', $$buffref;
	return ($length + 4) - length $$buffref unless length $$buffref >= $length + 4;

	return 0;
}

=head2 build_request

Builds an UWSGI request using the given modifier, defaulting
to modifier1 == 5 and modifier2 == 0, i.e. PSGI request.

Takes the following named parameters:

=over 4

=item * modifier1 - the modifier1 value, defaults to 5 if not provided

=item * modifier2 - the modifier2 value, defaults to 0 if not provided

=item * method - the HTTP request method

=item * uri - which L<URI> we're requesting, can be passed as a plain string
in which case we'll upgrade to a L<URI> object internally

=item * headers - a hashref of HTTP headers, e.g. { 'Content-Type' => 'text/html' }

=back

Returns a scalar containing packet data or raises an exception on failure.

=cut

sub build_request {
	my %args = @_;

#	my $type = delete $args{type} or die 'no type provided';
	my $uri = delete $args{uri} or die 'no URI provided';
	$uri = URI->new($uri) unless ref $uri;

	my %env;
	$env{REQUEST_METHOD} = uc delete $args{method};
	$env{UWSGI_SCHEME} = $uri->scheme;
	$env{HTTP_HOST} = $uri->host;
	$env{SERVER_PORT} = $uri->port // 80;
	$env{PATH_INFO} = $uri->path;
	$env{QUERY_STRING} = $uri->query if defined $uri->query;
	@env{qw(REMOTE_ADDR REMOTE_PORT)} = split ':', delete $args{remote}, 2 if $args{remote};

	$args{headers} ||= {};
	foreach my $k (keys %{$args{headers}}) {
		(my $env_k = uc $k) =~ tr/-/_/;
		$env{"HTTP_$env_k"} = $args{headers}{$k} // '';
	}
	delete $args{headers};

	my @modifier = delete @args{qw(modifier1 modifier2)};
	my $data = '';
	%env = (%args, %env);
	foreach my $k (sort keys %env) {
		die "Undef value found for $k" unless defined $env{$k};
		$data .= pack 'v1/av1/a', map { Encode::encode('utf8', $_) } $k, $env{$k};
	}

	return pack('C1v1C1',
		$modifier[0] // PSGI_MODIFIER1,
		length($data),
		$modifier[1] // PSGI_MODIFIER2,
	) . $data;
}

=head2 extract_modifier

Used internally to extract and handle the modifier-specific data.

=cut

sub extract_modifier {
	my %args = @_;

	die "Unsupported modifier1 $args{modifier1}" unless $args{modifier1} == PSGI_MODIFIER1;

	my $len = delete $args{length} or die "no length found";
	my $buffer = delete $args{buffer} or die "no buffer found";
	my %env;
	while($len) {
		my ($k, $v) = unpack 'v1/a*v1/a*', $$buffer;
		$env{$k} = $v;
		my $sublen = 4 + length($k) + length($v);
		substr $$buffer, 0, $sublen, '';
		$len -= $sublen;
	}
	return \%env;
}

=head2 uri_from_env

Returns a L<URI> object parsed from a request ("environment").

=cut

sub uri_from_env {
	my ($env) = @_;
	my $uri = $env->{UWSGI_SCHEME} . '://' . $env->{HTTP_HOST} . ':' . $env->{SERVER_PORT} . $env->{PATH_INFO};
	$uri .= '?' . $env->{QUERY_STRING} if length($env->{QUERY_STRING} // '');
	return URI->new($uri);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2014. Licensed under the same terms as Perl itself.
