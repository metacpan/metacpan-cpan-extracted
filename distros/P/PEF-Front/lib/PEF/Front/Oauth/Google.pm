package PEF::Front::Oauth::Google;

use strict;
use warnings;
use base 'PEF::Front::Oauth';
use HTTP::Request::Common;
use feature 'state';
use PEF::Front::Config;

sub _authorization_server {
	'https://accounts.google.com/o/oauth2/auth';
}

sub _required_redirect_uri { 1 }

sub _token_request {
	my ($self, $code) = @_;
	POST 'https://accounts.google.com/o/oauth2/token',
	  [ redirect_uri  => $self->{session}->data->{oauth_redirect_uri}{$self->{service}},
		grant_type    => 'authorization_code',
		code          => $code,
		client_id     => cfg_oauth_client_id($self->{service}),
		client_secret => cfg_oauth_client_secret($self->{service})
	  ];

}

sub _get_user_info_request {
	my ($self) = @_;
	my $req = GET 'https://www.googleapis.com/oauth2/v2/userinfo',
	  Authorization => 'Bearer ' . $self->{session}->data->{oauth_access_token}{$self->{service}};
	$req;
}

sub _parse_user_info {
	my ($self) = @_;
	my $info   = $self->{session}->data->{oauth_info_raw}{$self->{service}};
	my @avatar = ();
	@avatar = ({url => $info->{picture}}) if $info->{picture};
	return {
		name  => $info->{name}  || '',
		email => $info->{email} || '',
		login => $info->{email} || '',
		avatar => \@avatar,
	};
}

sub new {
	my ($class, $self) = @_;
	bless $self, $class;
}

1;
