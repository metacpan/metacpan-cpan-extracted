package PEF::Front::Oauth::Paypal;

use strict;
use warnings;
use base 'PEF::Front::Oauth';
use HTTP::Request::Common;
use feature 'state';
use PEF::Front::Config;

sub _authorization_server {
	'https://www.paypal.com/webapps/auth/protocol/openidconnect/v1/authorize';
}

sub _required_redirect_uri { 1 }

sub _token_request {
	my ($self, $code) = @_;
	my $req = POST 'https://api.paypal.com/v1/identity/openidconnect/tokenservice',
	  [ redirect_uri => $self->{session}->data->{oauth_redirect_uri}{$self->{service}},
		grant_type   => 'authorization_code',
		code         => $code,
	  ];
	$req->authorization_basic(cfg_oauth_client_id($self->{service}), cfg_oauth_client_secret($self->{service}));
	$req;
}

sub _get_user_info_request {
	my ($self) = @_;
	my $req = GET 'https://api.paypal.com/v1/identity/openidconnect/userinfo/?schema=openid';
	$req->content_type('application/json');
	$req->header(Authorization => 'Bearer ' . $self->{session}->data->{oauth_access_token}{$self->{service}});
	$req->header(Accept        => 'application/json');
	$req;
}

sub _parse_user_info {
	my ($self) = @_;
	my $info = $self->{session}->data->{oauth_info_raw}{$self->{service}};
	return {
		name  => $info->{name}  || '',
		email => $info->{email} || '',
		login => $info->{email} || '',
		avatar => [],
	};
}

sub new {
	my ($class, $self) = @_;
	bless $self, $class;
}

1;
