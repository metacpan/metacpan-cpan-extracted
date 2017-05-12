package PEF::Front::Oauth::GitHub;

use strict;
use warnings;
use base 'PEF::Front::Oauth';
use HTTP::Request::Common;
use feature 'state';
use PEF::Front::Config;

sub _authorization_server {
	'https://github.com/login/oauth/authorize';
}

sub _token_request {
	my ($self, $code) = @_;
	POST 'https://github.com/login/oauth/access_token',
	  [ code          => $code,
		client_id     => cfg_oauth_client_id($self->{service}),
		client_secret => cfg_oauth_client_secret($self->{service})
	  ],
	  Accept => 'application/json';
}

sub _get_user_info_request {
	my ($self) = @_;
	my $req = GET 'https://api.github.com/user',
	  Authorization => 'token ' . $self->{session}->data->{oauth_access_token}{$self->{service}};
	$req;
}

sub _parse_user_info {
	my ($self) = @_;
	my $info   = $self->{session}->data->{oauth_info_raw}{$self->{service}};
	my @avatar = ();
	@avatar = ({url => $info->{avatar_url}}) if $info->{avatar_url};
	return {
		name => $info->{name} || $info->{login} || '',
		email => $info->{email} || '',
		login => $info->{login} || '',
		avatar => \@avatar,
	};
}

sub new {
	my ($class, $self) = @_;
	bless $self, $class;
}

1;
