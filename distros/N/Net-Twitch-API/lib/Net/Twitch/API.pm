package Net::Twitch::API;

use warnings;
use strict;

use WebService::Simple;
use base 'WebService::Simple';

use JSON ();

our $VERSION   = '0.11';

# overide our base modules WebService::Simple _agent() method with our own:
sub _agent { "libwww-perl/$LWP::VERSION+WebService::Simple/". $WebService::Simple::VERSION ."+". __PACKAGE__ .'/'.$VERSION }

# similarly for the WebService::Simple built-in config(), which we overwrite like this:
__PACKAGE__->config(
	base_url        => 'https://api.twitch.tv/helix/', # needs a trailing slash
	response_parser => 'JSON',
);

# we wrap the underlying base's new() method to attach credentials (which are normally discarded)
sub new {
	my $class = shift;
	my %args  = @_;

	die "Net::Twitch::API: new: no access_token provided!" unless $args{access_token};
	die "Net::Twitch::API: new: no client_id provided!" unless $args{client_id};

	$args{croak} = 0; # WebService::Simple by default croaks() - which we do not want

	my $self  = $class->SUPER::new(%args);

	$self->{access_token} = $args{access_token};
	$self->{client_id}    = $args{client_id};

	return $self;
}

sub getUsers {
	my $self = shift;
	my $params = shift || {};

	my $response = $self->get('/users', $params,
		'Authorization'	=> 'Bearer '. $self->{access_token},
		'Client-Id'		=> $self->{client_id},
	);

	return $self->_responseParser($response,'getUsers');
}

sub _responseParser {
	my $self = shift;
	my $response = shift;
	my $methodName = shift || '<empty methodName>';

	## WebService::Simple doesn't wrap error responses, so handle this case here
	unless($response->is_success){
		unless($response->content_length() ){
			return { error => $methodName ." request failed!", status => $response->code, message => $response->message, response => $response };
		}

		$response = WebService::Simple::Response->new_from_response(
			response => $response,
			parser   => $self->response_parser
		);
	}

	my $result = {};

	$result = $response->parse_response() if $response->content_length();

	return $result;
}

=pod

=head1 NAME

Net::Twitch::API - Helper methods for Twitch's "new" helix API

=head1 SYNOPSIS

	use Net::Twitch::API;

	my $api = Net::Twitch::API->new(
		access_token => 'your-token',
		client_id    => 'your-id',
		debug        => 1,
	);

	my $response = $api->getUsers({ login => 'twitchdev' });

=head1 DESCRIPTION

This module provides methods and helper wrappers to work with what Twitch "new" helix API. The I<new> API is
prefixed with the I<helix> codename/namespace and the successor of the old I<kraken> API which was decommissioned
on February 28, 2022. A little more about that on dev.twitch.tv L<"legacy v5 integrations" migration guide|https://dev.twitch.tv/docs/api/migration>.

Using this module to issue requests against Twitch's API requires you to register your "application" with Twitch
first. Authentication then is either faciliated via L<OAuth 2.0|https://dev.twitch.tv/docs/authentication/getting-tokens-oauth>
or L<OpenID Connect|https://dev.twitch.tv/docs/authentication/getting-tokens-oidc>. We here use the OAuth2 scheme.

Twitch uses several types of auth tokens. Use the twitch CLI client to obtain an "app access token". This type of
token enables your app to make secure API requests that are not on behalf of a specific user. App access tokens are
meant only for server-to-server API requests and should never be included in client code. Normally, such tokens
would be programmatically refreshed at arbitrary intervals according to OAuth2 RFC but on Twitch app access tokens
are valid for 60 days and cannot be refreshed.

This module uses Yosukebe's excellent L<WebService::Simple> as base calss. So look there for addditonal documentation.
You might also note that Yosukebe himself recently switched over to the newer L<WebService::Client>, but that's a
Moo based module.

=head1 FUNCTIONS

=head2 new()

Calls underlying WebService::Simple's new(), with additional checks and defaults for Twitch.

You must provide your I<access_token> and I<client_id>.

If I<debug> is set, the request URL will be dumped via warn() on get or post method calls.

WebService::Simple by default croaks (dies) on a failed request. This module returns on error and success with a
reference to a hash containing received data. The hash key I<error> is defined on unsuccessful requests.

If you supply a Cache object to new(), each request is prepended by a cache look-up. Refer to L<WebService::Simple>
for an example.

=head2 getUsers()

Expects a hashref. Users can be looked up either via their I<login> name (username / nickname) or via their numeric
user I<id>. Twitch allows to ask for multiple names in one request. Current limit is 100. Use an arrayref of values
instead of a scalar then.

Returns a hashref with hash-key I<data> holding a reference to an array of users.

=head1 EXPORT

Nothing by default.

=head1 CAVEATS

Note that Net::Twitch::API is a WIP module. Things are incomplete or may change without notice.

=head1 SEE ALSO

Official Twitch documents:

=over

=item *

L<Getting Started|https://dev.twitch.tv/docs/api> walks you through basic setup of your app and helps with
a first request.

=item *

L<Reference|https://dev.twitch.tv/docs/api/guide> gives an overview of core principles like pagination and rate
limits.

=item *

L<Reference|https://dev.twitch.tv/docs/api/reference> si the canonical Twitch API endpoints reference. A little
more an be found in the L<api docs|https://github.com/twitchdev/twitch-cli/blob/main/docs/api.md> for the twitch-cli command-line client.

=back

Within the Perl universe, Twitch related code can be found in outdated modules L<App::Twitch> and L<Net::Twitch::Oauth2>
and Corion's non-API helper module L<WWW::Twitch|https://github.com/Corion/WWW-Twitch>.

=head1 AUTHOR

Clipland GmbH L<https://www.clipland.com/>

This module was developed for L<"Sendung verpasst?"|https://mediatheksuche.de/> I<video> search engine L<MediathekSuche.de|https://mediatheksuche.de/>.

=head1 COPYRIGHT & LICENSE

Copyright 2022 Clipland GmbH. All rights reserved.

This library is free software, dual-licensed under L<GPLv3|http://www.gnu.org/licenses/gpl>/L<AL2|http://opensource.org/licenses/Artistic-2.0>.
You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
