package Squid::Guard::Request;

use 5.008;
use strict;
use warnings;
use Carp;

our @ISA = qw();

our $VERSION = '0.15';


=head1 NAME

Squid::Guard::Request - A request to Squid::Guard

=head1 SYNOPSYS

    use Squid::Guard::Request;

    my $req = Squid::Guard->new($str);

=head1 DESCRIPTION

Initializes a new Request object based on the string coming
from Squid to the redirector.


=head2 Squid::Guard::Request->new( $str )

API call to create a new object. The $str parameter should be in the format used by Squid to pass a request to the redirection program: C<url addr/fqdn user method kvpairs>.

=cut

# TODO: maybe resolve protocols via getservent()?
my %defaultports = (
	'http' => 80,
	'https' => 443,
	'http-mgmt' => 280,
	'gss-http' => 488,
	'multiling-http' => 777,
	'ftp' => 21,
	'gopher' => 70,
	'wais' => 210,
	'filemaker' => 591,
);

my %defaultschemes = reverse %defaultports;

sub new {
        my $class = shift;
        my $str = shift;

        my $self  = {};

        $self->{str}            = $str;
        $self->{verbose}        = 0;
        $self->{debug}          = 0;

        $self->{debug}          = 0;

	{
		no strict qw(vars refs);
		local ($url, $foo, $ident, $method, $_kvpairs, $addr, $fqdn, $_scheme, $authority, $path, $query, $fragment, $host, $_port);
		($url, $foo, $ident, $method, $_kvpairs) = split(/\s+/, $str, 5);

		$ident =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/eg;

		($addr, $fqdn) = split(/\//, $foo);

		foreach ( qw( ident _kvpairs fqdn ) ) {
			${$_} = undef if ${$_} eq '-';
		}

	#	($_scheme, $authority, $path, $query, $fragment) = $url =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|; # taken from URI man page
		($_scheme, $authority, $path, $query, $fragment) = $url =~ m|(?:([^:/?#]+)://)?([^/?#]*)([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;	# Slightly modified for our usage: authority is needed, // isn't
		($host, $_port) = split( /:/, $authority );

		foreach ( qw( url ident method _kvpairs addr fqdn _scheme authority path query fragment host _port ) ) {
			$self->{$_} = ${$_};
		}
	}

        bless($self, $class);
        return $self;
}


=head2 $req->url()

Get request url

=cut


=head2 $req->addr()

Get request address

=cut


=head2 $req->fqdn()

Get request fqdn

=cut


=head2 $req->ident()

Get request ident

=cut


=head2 $req->method()

Get request method

=cut


=head2 $req->kvpairs()

When called without arguments, returns a hash consisting of the extra key/value pairs found in the request. If an argument is supplied, it is taken as a key and the corresponding value (or undef) is returned. You can access the string of key/value pairs exactly as passed in the request by using _kvpairs instead

=cut


=head2 $req->_scheme() $req->scheme() $req->authority() $req->host() $req->_port() $req->port() $req->path() $req->query() $req->path_query() $req->authority_path_query() $req->fragment()

Get url components. These methods are inspired form the URI module.

If a port is not specified explicitly in the request, then $req->port returns the scheme's default port.
If you don't want the default port substituted, then you can use the $uri->_port method instead. (behaviour consistent with URI module)
Similarly, $req->_scheme reports the scheme explicitly specified in the requested url, or undef if not present (this is cthe case of CONNECT requests).
When $req->_scheme is undef and $uri->_port is defined, $req->scheme is set to the port's default scheme.

=cut


sub AUTOLOAD {
	my ($self) = @_;	# don't use shift, otherwise the call to goto &$AUTOLOAD will suffer :(
	croak "$self not an object" unless ref($self);
	our $AUTOLOAD;
	no strict 'refs';
	if ($AUTOLOAD =~ /.*::(.*)/) {
		my $element = $1;
		return if $element eq "DESTROY";
		if( grep { $element eq $_ } qw( url ident method _kvpairs addr fqdn _scheme authority host _port path query fragment ) ) {
			*$AUTOLOAD = sub { 
				my $self = shift;
				$self->{$element};
			};
		} elsif( $element eq 'path_query' ) {
			*$AUTOLOAD = sub {
				my $self = shift;
				( $self->path || '' ) . ( $self->query ? ( "?" . $self->query ) : '' );
			};
		} elsif( $element eq 'authority_path_query' ) {
			*$AUTOLOAD = sub {
				my $self = shift;
				$self->authority . $self->path_query;
			};
		} elsif( $element eq 'port' ) {
			*$AUTOLOAD = sub {
				my $self = shift;
				if( $self->_port ) {
					return $self->_port;
				} elsif( $self->_scheme && defined( $defaultports{$self->_scheme} ) ) {
					return $defaultports{$self->_scheme};
				} else {
					return undef;
				}
			};
		} elsif( $element eq 'scheme' ) {
			*$AUTOLOAD = sub {
				my $self = shift;
				if( $self->_scheme ) {
					return $self->_scheme;
				} elsif( $self->_port && defined( $defaultschemes{$self->_port} ) ) {
					return $defaultschemes{$self->_port};
				} else {
					return undef;
				}
			 }
		} elsif( $element eq 'kvpairs' ) {
			*$AUTOLOAD = sub {
				my $self = shift;
				return undef unless $self->{'_kvpairs'};
				$self->{_kvh} ||= { map { split(/=/, $_) } split(/\s+/, $self->{'_kvpairs'}) };

				@_ ? $self->{_kvh}->{$_[0]} : %{$self->{_kvh}};
			};
		} else {
			croak "invalid method $element";
		}
		goto &$AUTOLOAD;
	}
}


1;
