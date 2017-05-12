package PEF::Front::Oauth::LinkedIn;

use strict;
use warnings;
use base 'PEF::Front::Oauth';
use HTTP::Request::Common;
use feature 'state';
use PEF::Front::Config;

sub _authorization_server {
	'https://www.linkedin.com/uas/oauth2/authorization';
}

sub _required_redirect_uri { 1 }

sub _token_request {
	my ($self, $code) = @_;
	POST 'https://www.linkedin.com/uas/oauth2/accessToken',
	  [ redirect_uri  => $self->{session}->data->{oauth_redirect_uri}{$self->{service}},
		grant_type    => 'authorization_code',
		code          => $code,
		client_id     => cfg_oauth_client_id($self->{service}),
		client_secret => cfg_oauth_client_secret($self->{service})
	  ];

}

sub _get_user_info_request {
	my ($self) = @_;
	my $req = GET
	  'https://api.linkedin.com/v1/people/~:(id,email-address,first-name,last-name,formatted-name,picture-url)';
	$req->uri->query_form(format => 'json');
	$req->header(Authorization => 'Bearer ' . $self->{session}->data->{oauth_access_token}{$self->{service}});
	$req;
}

sub _parse_user_info {
	my ($self) = @_;
	my $info = $self->{session}->data->{oauth_info_raw}{$self->{service}};
	return {
		name  => $info->{firstName} . ' ' . $info->{lastName},
		email => $info->{emailAddress},
		login => $info->{formattedName},
		id    => $info->{id},
	};
}

sub new {
	my ($class, $self) = @_;
	bless $self, $class;
}

1;
