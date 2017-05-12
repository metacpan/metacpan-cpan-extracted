package Net::Zemanta::Method;

use warnings;
use strict;

use LWP::UserAgent;
use HTTP::Request::Common;
use Encode;
use JSON;

our $VERSION = '0.7';

my $SERVICE_TYPE = "rest";
my $API_VERSION = "0.0";

my $UA_SUFFIX = "Perl-Net-Zemanta/$VERSION";

sub new {
	my $class = shift;
	my %params = @_;

	my $self = \%params;

	$self->{ua} = LWP::UserAgent->new() or return undef;

	$self->{APIKEY} or return undef;
	$self->{METHOD} or return undef;

	# NOTE: trailing space leaves LWP::UserAgent agent string in place
	my $agent = "$UA_SUFFIX ";
	$agent = "$params{USER_AGENT} $agent" if $params{USER_AGENT};
	$self->{ua}->agent($agent);

	$self->{service_url} = "http://api.zemanta.com/services/$SERVICE_TYPE/$API_VERSION";

	bless $self, $class;

	return $self;
}

sub execute {
	my $self = shift;
	my %params = @_;

	my %merged_params = ( 	'method'  => $self->{METHOD},
				'format'  => 'json',
				'api_key' => $self->{APIKEY},
				%params );

	my $response = $self->{ua}->request(POST $self->{service_url},
						\%merged_params );
	
	unless ($response->is_success) {
		$self->{error} = $response->status_line;
		return undef;
	}

	my $result = from_json($response->content);

	if ($result->{status} ne 'ok') {
		$self->{error} = "method returned " . $result->{status};
		return undef;
	}

	$self->{error} = undef;

	return $result;
}

sub error {
	my $self = shift;

	return $self->{error};
}

1;
