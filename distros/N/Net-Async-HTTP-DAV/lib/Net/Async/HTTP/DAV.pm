package Net::Async::HTTP::DAV;
# ABSTRACT: WebDAV using Net::Async::HTTP
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '0.001';

=head1 NAME

Net::Async::HTTP::DAV - support for WebDAV over L<Net::Async::HTTP>

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::HTTP;
 use Net::Async::HTTP::DAV;
 use POSIX qw(strftime);
 my $loop = IO::Async::Loop->new;
 $loop->add(my $dav = Net::Async::HTTP::DAV->new(
 	host => 'cpan.perlsite.co.uk',
 ));
 $dav->propfind(
 	path => '/authors/id/T/TE/TEAM/',
 	on_item => sub {
 		my ($item) = @_;
 		printf "%-32.32s %-64.64s %12d\n", strftime("%Y-%m-%d %H:%M:%S", localtime $item->{modified}), $item->{displayname}, $item->{size};
 	},
 )->get;

=head1 DESCRIPTION

Does some very basic WebDAV stuff.

See L<http://www.webdav.org/specs/rfc2518.html>.

Highly experimental, no documentation, see examples/ in source distribution.
API is likely to change.

=cut

use Net::Async::HTTP;
use Net::Async::HTTP::DAV::Response;

use File::Spec;
use Scalar::Util qw(weaken);
use Encode qw(encode_utf8);

=head1 METHODS

=cut

=head2 configure

Accepts configuration parameters (can also be passed to L</new>).

=over 4

=item * host - which host we're connecting to

=item * path - base path for requests

=item * user - optional username

=item * pass - optional password, Basic auth

=item * http - a pre-existing L<Net::Async::HTTP> instance

=back

=cut

sub configure {
	my ($self, %args) = @_;
	foreach (qw(user pass path host http)) {
		$self->{$_} = delete $args{$_} if exists $args{$_};
	}
	return $self;
}

=head2 http

Accessor for the internal L<Net::Async::HTTP> instance.

=cut

sub http {
	my $self = shift;
	if(@_) {
		shift->{http} = shift;
		return $self
	}
	unless($self->{http}) {
		my $ua = $self->ua_factory;
		$self->add_child($ua);
		Scalar::Util::weaken($self->{http} = $ua);
	}
	return $self->{http};
}

=head2 ua_factory

Populates the L<Net::Async::HTTP> instance via factory or default settings.

=cut

sub ua_factory {
	my ($self) = @_;
	$self->{ua_factory}->() if $self->{ua_factory};
	Net::Async::HTTP->new(
		decode_content  => 0,
		fail_on_error   => 1,
		max_connections_per_host => 4,
		stall_timeout   => 60,
	)
}

=head2 path

Base path for requests.

=cut

sub path { shift->{path} }

=head2 propfind

Does a propfind request.

Parameters are basically 'path' and on_item for a per-item callback.

=cut

sub propfind {
	my $self = shift;
	my %args = @_;
	# want a trailing /
	my $uri = $self->uri_from_path(File::Spec->catdir(($self->path // ()), $args{path}) . '/') or die "Invalid URL?";
	my $body = <<"EOF";
<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
 <D:allprop/>
</D:propfind>
EOF

	my $req = HTTP::Request->new(
		PROPFIND => $uri->path, [
			'Host'		=> $uri->host,
			'Depth'		=> 1,
			'Content-Type'	=> 'text/xml'
		], encode_utf8($body)
	);
	$req->protocol('HTTP/1.1');
	$req->authorization_basic($self->user, $self->pass) if defined($self->user);
	$self->http->do_request(
		request		=> $req,
		host		=> $uri->host,
		port		=> $uri->scheme || 80,
		SSL		=> $uri->scheme eq 'https' ? 1 : 0,
		on_header	=> sub {
			my $response = shift;
			my $result = Net::Async::HTTP::DAV::Response->new(
				%args,
				path => $uri->path
			);
			# Seems we'll need to return the response?
			weaken $response;
			return sub {
				$result->parse_chunk($_[0]) if @_;
				$response
			};
		},
	);
}

sub getinfo {
	my $self = shift;
	my %args = @_;
	my $uri = $self->uri_from_path($args{path} // $self->{path}) or die "Invalid URL?";
	my $body = <<"EOF";
<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
 <D:allprop/>
</D:propfind>
EOF

	my $req = HTTP::Request->new(
		PROPFIND => $uri->path, [
			'Host'		=> $uri->host,
			'Depth'		=> 0,
			'Content-Type'	=> 'text/xml'
		], encode_utf8($body)
	);
	$req->protocol('HTTP/1.1');
	$req->authorization_basic($self->user, $self->pass) if $self->user;
	$self->http->do_request(
		request		=> $req,
		host		=> $uri->host,
		port		=> $uri->scheme || 80,
		SSL		=> $uri->scheme eq 'https' ? 1 : 0,
		on_header	=> sub {
			my $response = shift;
			my $result = Net::Async::HTTP::DAV::Response->new(
				%args,
				path => $uri->path,
				on_item => sub {
					my $item = shift;
					$args{on_size}->($item->{size});
				}
			);
			return sub {
				$result->parse_chunk($_[0]) if @_;
			};
		},
		on_error => sub {
			my ( $message ) = @_;
			die "Failed - $message\n";
		}
	);
	return $self;
}

=head2 head

Perform HEAD request on given path.

=cut

sub head {
	my $self = shift;
	my %args = @_;
	my $uri = $self->uri_from_path($args{path} // $self->{path}) or die "Invalid URL?";
	my $req = HTTP::Request->new(
		HEAD => $uri->path, [
			'Host'		=> $uri->host,
		]
	);
	$req->protocol('HTTP/1.1');
	$req->authorization_basic($self->user, $self->pass) if $self->user;
	$self->http->do_request(
		request		=> $req,
		host		=> $uri->host,
		port		=> $uri->scheme || 80,
		SSL		=> $uri->scheme eq 'https' ? 1 : 0,
		on_response	=> sub {
			my $response = shift;
#			$args{on_size}->($response->content_length);
		},
		on_error => sub {
			my ( $message ) = @_;
			die "Failed - $message\n";
		}
	);
	return $self;
}

=head2 get

GET the given resource

=cut

sub get {
	my $self = shift;
	my %args = @_;
	my $uri = $self->uri_from_path($args{path} // $self->{path}) or die "Invalid URL?";
	my $req = HTTP::Request->new(
		GET => $uri->path, [
			'Host'		=> $uri->host,
		]
	);
	$req->protocol('HTTP/1.1');
	$req->authorization_basic($self->user, $self->pass) if $self->user;
	$self->http->do_request(
		request		=> $req,
		host		=> $uri->host,
		port		=> $uri->scheme || 80,
		SSL		=> $uri->scheme eq 'https' ? 1 : 0,
		on_header	=> sub {
			my $response = shift;
			return $args{on_header}->($response);
		},
		on_error => sub {
			my ( $message ) = @_;
			die "Failed - $message\n";
		}
	);
	return $self;
}

=head2 put

Write data directly to the given resource.

=cut

sub put {
	my $self = shift;
	my %args = @_;
	my $handler = delete $args{response_body};
	my $uri = $self->uri_from_path($args{path} // $self->{path});

	my $req = HTTP::Request->new(
		PUT => $uri->path, [
			'Host'      => $uri->host,
			'Content-Type' => 'application/octetstream',
		], defined $args{content} ? $args{content} : ()
	);
	$req->protocol('HTTP/1.1');
	$req->authorization_basic($self->{user}, $self->{pass});
	$req->content_length($args{size}) unless defined $args{content};

	my $fh;
	$self->http->do_request(
		request		=> $req,
		host		=> $uri->host,
		port		=> $uri->scheme || 80,
		SSL		=> $uri->scheme eq 'https' ? 1 : 0,
		(defined $args{content})
		? ()
		: (request_body => $handler || sub {
			my ($stream) = @_;
			warn $stream;
			return '';
			my $read = sysread $fh, my $buffer, 32768;
			warn $! unless defined $read;
			return $buffer if $read;
			return;
		}),
		on_error => sub {
			my ( $message ) = @_;
			die "Failed - $message\n";
		},
		on_response => $args{on_response} || sub {
			my ($response) = @_;
			my $msg = $response->message;
			$msg =~ s/\s+/ /ig;
			$msg =~ s/(?:^\s+)|(?:\s+$)//g; # trim
			warn $response->code . " - $msg\n";
		}
	);
}

sub host { shift->{host} }
sub user { shift->{user} }
sub pass { shift->{pass} }

sub uri_from_path {
	my $self = shift;
	my $path = shift // '/';
	$path = "/$path" unless substr($path, 0, 1) eq '/';
	$path =~ s{/+}{/}g;
	return URI->new('http://' . $self->host . $path) || die "Invalid URL?";
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2014. Licensed under the same terms as Perl itself.
