#
# $Id: Google.pm 9 2008-04-29 21:17:12Z esobchenko $

package REST::Google;

use strict;
use warnings;

use version; our $VERSION = qv('1.0.8');

use Carp qw/carp croak/;

use JSON::Any;

use HTTP::Request;
use LWP::UserAgent;

use URI;

require Class::Data::Inheritable;
require Class::Accessor;

use base qw/Class::Data::Inheritable Class::Accessor/;

__PACKAGE__->mk_classdata("http_referer");
__PACKAGE__->mk_classdata("service");

__PACKAGE__->mk_accessors(qw/responseDetails responseStatus/);

use constant DEFAULT_ARGS => (
	'v' => '1.0',
);

use constant DEFAULT_REFERER => 'http://example.com';

# private method: used in constructor to get it's arguments
sub _get_args {
	my $proto = shift;

	my %args;
	if ( scalar(@_) > 1 ) {
		if ( @_ % 2 ) {
			croak "odd number of parameters";
		}
		%args = @_;
	} elsif ( ref $_[0] ) {
		unless ( eval { local $SIG{'__DIE__'}; %{ $_[0] } || 1 } ) {
			croak "not a hashref in args";
		}
		%args = %{ $_[0] };
	} else {
		%args = ( 'q' => shift );
	}

	return { $proto->DEFAULT_ARGS, %args };
}

sub new {
	my $class = shift;

	my $args = $class->_get_args(@_);

	croak "attempting to perform request without setting a service URL"
		unless ( defined $class->service );

	my $uri = URI->new( $class->service );
	$uri->query_form( $args );

	unless ( defined $class->http_referer ) {
		carp "attempting to search without setting a valid http referer header";
		$class->http_referer( DEFAULT_REFERER );
	}

	my $request = HTTP::Request->new( GET => $uri, [ 'Referer', $class->http_referer ] );

	my $ua = LWP::UserAgent->new();
	$ua->env_proxy;

	my $response = $ua->request( $request );

	croak sprintf qq/HTTP request failed: %s/, $response->status_line
		unless $response->is_success;

	my $content = $response->content;

	my $json = JSON::Any->new();
	my $self = $json->decode($content);

	return bless $self, $class;
}

sub responseData {
	my $self = shift;
	return $self->{responseData};
}

1;
