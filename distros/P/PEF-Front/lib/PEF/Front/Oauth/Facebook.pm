package PEF::Front::Oauth::Facebook;

use strict;
use warnings;
use base 'PEF::Front::Oauth';
use HTTP::Request::Common;
use feature 'state';
use PEF::Front::Config;

sub _authorization_server {
	'https://www.facebook.com/dialog/oauth';
}

sub _token_request {
	my ($self, $code) = @_;
	my $req = GET 'https://graph.facebook.com/oauth/access_token';
	$req->uri->query_form(
		redirect_uri  => $self->{session}->data->{oauth_redirect_uri}{$self->{service}},
		client_id     => cfg_oauth_client_id($self->{service}),
		client_secret => cfg_oauth_client_secret($self->{service}),
		grant_type    => 'authorization_code',
		code          => $code
	);
	$req;
}

sub _decode_token {
	my ($self, $content) = @_;
	return {map { split ('=', $_) } split ('&', $content)};
}

sub _get_user_info_request {
	my ($self) = @_;
	my $req = GET 'https://graph.facebook.com/me';
	$req->uri->query_form(access_token => $self->{session}->data->{oauth_access_token}{$self->{service}});
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
