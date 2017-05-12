package PEF::Front::Oauth::VKontakte;

use strict;
use warnings;
use base 'PEF::Front::Oauth';
use HTTP::Request::Common;
use feature 'state';
use PEF::Front::Config;

sub _authorization_server {
	'http://oauth.vk.com/authorize';
}

sub _required_redirect_uri { 1 }
sub _required_state        { 0 }
sub _returns_state         { 0 }

sub _token_request {
	my ($self, $code) = @_;
	my $req = GET 'https://oauth.vk.com/access_token';
	$req->uri->query_form(
		client_id     => cfg_oauth_client_id($self->{service}),
		client_secret => cfg_oauth_client_secret($self->{service}),
		code          => $code,
		redirect_uri  => $self->{session}->data->{oauth_redirect_uri}{$self->{service}}
	);
}

sub _get_user_info_request {
	my ($self) = @_;
	my $req = GET 'https://api.vk.com/method/users.get';
	$req->uri->query_form(
		access_token => $self->{session}->data->{oauth_access_token}{$self->{service}},
		uids         => $self->{session}->data->{oauth_info_raw}{$self->{service}}{user_id},
		fields       => 'photo_50,first_name,last_name,nickname,screen_name'
	);
	$req;
}

sub _parse_user_info {
	my ($self) = @_;
	my $info   = $self->{session}->data->{oauth_info_raw}{$self->{service}};
	my @avatar = ();
	@avatar = ({url => $info->{photo_50}}) if $info->{photo_50};
	return {
		name   => $info->{first_name} . ' ' . $info->{last_name},
		email  => '',
		login  => $info->{screen_name} || '',
		avatar => \@avatar,
	};
}

sub new {
	my ($class, $self) = @_;
	bless $self, $class;
}

1;
