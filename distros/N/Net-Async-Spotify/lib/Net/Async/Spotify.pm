package Net::Async::Spotify;

use strict;
use warnings;

our $VERSION = 0.001;
our $AUTHORITY = 'cpan:VNEALV'; # AUTHORITY

# ABSTRACT: Interaction with spotify.com API

=encoding utf8

=head1 NAME

    C<Net::Async::Spotify> - Interaction with spotify.com API

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Future::AsyncAwait;
    use Net::Async::Spotify;

    my $loop = IO::Async::Loop->new;
    my $spotify = Net::Async::Spotify->new(
        client_id     => '5fe01282e44241328a84e7c5cc169165',
        client_secret => '6f12e202e44241328a84e7c5dd169125',
    );
    $loop->add($spotify);

    # Generate the needed Authorize hash.
    # Requesting permission for all available scopes, and without prompting user if already approved.
    my %authorize = $spotify->authorize(scope => ['scopes'], show_dialog => 'false');
    my $auth_uri   = $authorize{uri};
    my $auth_state = $authorize{state};

    # Obtain Authorization code from callback request.
    my $auth_code = '...'; # from `code` path parameter.

    # Get the needed Access Token
    await $spotify->obtain_token(
        code         => $auth_code,
        auto_refresh => 1,
    );

    # You can now request any API call
    await $spotify->api->player->start_a_users_playback();

    # Token will be auto refreshed before it's expiry.
    $loop->run;

=head1 DESCRIPTION

C<Net::Async::Spotify> Provides an interface for interacting with L<"Spotify API"|https://developer.spotify.com/documentation/web-api>
It does so while being an L<IO::Async::Notifier> instance, with a L<Net::Async::HTTP> child to reach Spotify API, running on an L<IO::Async::Loop>.
Where all listed Spotify API calls and their response objects are auto-generated and defined here from documentation page. For easier maintainability.

=cut

use parent qw(IO::Async::Notifier);

use Future::AsyncAwait;
use Syntax::Keyword::Try;
use Log::Any qw($log);
use Net::Async::HTTP;
use IO::Async::Timer::Periodic;
use URI;
use URI::QueryParam;
use MIME::Base64 qw(encode_base64);
use Math::Random::Secure qw(irand);
use JSON::MaybeUTF8 qw(:v1);
use curry;

use Net::Async::Spotify::Scope qw(:all);
use Net::Async::Spotify::API;
use Net::Async::Spotify::Token;

=head1 CONSTRUCTOR

=cut

=head2 new

    $spotify = Net::Async::Spotify->new( %args )

Constructs a new C<Net::Async::Spotify> Object, in which is actually an L<IO::Async::Notifier> instance.
Takes a number of named arguments at construction time, which can be grouped like so:

=head3 App Params

More details about them can be found in L<"Spotify App Settings page"|https://developer.spotify.com/documentation/general/guides/app-settings/>

=over 8

=item client_id => STRING

Spotify App Client ID. L</client_id>

=item client_secret => STRING

Spotify App Client Secret. L</client_secret>

=item redirect_uri => STRING

Spotify App callback URI. L</redirect_uri>

=item base_uri => STRING

Spotify base_uri default is set to L<https://accounts.spotify.com/>. L</base_uri>

=back

=head3 Token Params

Used for L</token>.
It's parameter can be passed here too, however not needed as they can be obtained.
When not passed then they should be obtained by calling L</obtain_token>

=over 8

=item access_token => STRING

Spotify User's L<"Access Token"|https://datatracker.ietf.org/doc/html/rfc6749#section-1.4>

=item refresh_token => STRING

Spotify User's L<"Refresh Token"|https://datatracker.ietf.org/doc/html/rfc6749#section-1.5>

=item token_type => STRING

Spotify L<"Access Token type"|https://datatracker.ietf.org/doc/html/rfc6749#section-7.1>

=back

=head3 API param

used for L</API>. It is used to create only selected Spotify APIs instead of all.
When not passed it will load all available L<"Spotify APIs"|https://developer.spotify.com/documentation/web-api/reference/#reference-index>

=over 8

=item apis => ArrayRef

a List of limited APIs to be loaded. Passed to L<Net::Async::Spotify::API> when being created.

=back

=cut

sub configure_unknown {
    my ($self, %args) = @_;
    my $apis = delete $args{apis};
    $self->{api} = Net::Async::Spotify::API->new(spotify => $self, apis => $apis);

    # get Token params, as they can be passed here too
    my $token = Net::Async::Spotify::Token->new();
    for my $k (grep exists $args{$_}, qw(access_token refresh_token token_type)) {
        $token->$k($args{$k});
    }
    $self->{token} = $token;

    for my $k (grep exists $args{$_}, qw(client_id client_secret redirect_uri base_uri)) {
        $self->{$k} = $args{$k};
    }
}

sub _add_to_loop {
    my $self = shift;
    $self->add_child(
        $self->{http} = Net::Async::HTTP->new(
            fail_on_error            => 1,
            close_after_request      => 0,
            max_connections_per_host => 2,
            pipeline                 => 1,
            max_in_flight            => 4,
            decode_content           => 1,
            stall_timeout            => 15,
            user_agent               => 'Mozilla/4.0 (perl; Net::Async::Spotify; VNEALV@cpan.org)',
        ));
    $self->add_child(
        $self->{token_timer} = IO::Async::Timer::Periodic->new(
            interval => $self->token->expires_in - 46,
            on_tick  => $self->$curry::weak(sub {
                my $self = shift;
                $self->obtain_token()->retain;
            }),
        )
    );
}

=head1 METHODS

=head2 token

L<Net::Async::Spotify::Token> Object, holding Spotify Token information.

=cut

sub token { shift->{token} }

=head2 API

Returns an instance of L<Net::Async::Spotify::API> which includes all needed Spotify API Classes as methods.
To be used to access and call any loaded Spotify API

    $spotify->api->->player->transfer_a_users_playback(
        device_ids => '...',
        play => 'true'
    )->get;

Note that the response from any API call, belongs to L<Net::Async::Spotify::Object> group class.
For both, API calls and their response objects are being collected and auto generated from L<"Spotify doc page"|https://developer.spotify.com/documentation/web-api/reference>, check </"crawl-api-doc.pl">.

=cut

sub api { shift->{api} }

=head2 authorize

Returns an L<URI> object with it being the needed Spotify Authorization request along with the needed parameters set.
also return random hexadecimal number as the state attached to this request.
Pretty much the things needed for L<"Spotify Obtaining Authorization"|https://developer.spotify.com/documentation/general/guides/authorization-guide/#obtaining-authorization>
Accepts limited named parameters

=over 4

=item client_id

Spotify ClientID, set to class L</client_id> if not passed.

=item response_type

set as C<code> for default. Since Authorization Code Flow is used.

=item redirect_uri

URI string that will be used as Authorization callback URL. Set to main app L</redirect_url> if not peresnt.

=item state

Used as linking mechanism between this generated Authorize Request, and the incoming callback code response.
will be set to a random hexadecimal number. For more info see L<"Cross-Site Request Forgery"|https://datatracker.ietf.org/doc/html/rfc6749#section-10.12>
Optional and defaulted to a random 8 digit hexadecimal string, using L<Math::Random::Secure::irand>

=item scope

Sets permissions to be requested. Accepts array of scopes or scopes categories.
e.g. scope => [app_remote_control', 'user-follow-read', 'spotify_connect']
for more info L<"Spotify Scopes"|https://developer.spotify.com/documentation/general/guides/scopes/>, also L<Net::Async::Spotify::Scope>.

=item show_dialog

optional param can be passed set to either true|false
Whether or not to force the user to approve the app again if they've already done so.
C<false> (default) from Spotify API itself.

=back

    $spotify->authorize(
        scope => [
            'user-read-playback-state',
            'user-read-currently-playing',
            'playlists',
        ],
    );

Returns a C<Hash> containing C<uri> as the Authorization URL needed, and C<state> as the value that is used in it L</state>

=cut

sub authorize {
    my ($self, %args) = @_;
    my $allowed_params = join '|', qw(client_id response_type redirect_uri state scope show_dialog);

    $args{client_id} //= $self->client_id;
    $args{response_type} //= 'code';
    $args{redirect_uri} //= $self->redirect_uri->as_string;
    $args{state} //= sprintf '%08x', irand(2**32);
    $args{scope} = join ' ', map { (\&{join('::', 'Net::Async::Spotify::Scope', $_)})->() } $args{scope}->@* if exists $args{scope};

    # Don't leak any extra params
    delete $args{$_} for grep { !/$allowed_params/ } keys %args;

    my $auth_uri = URI->new($self->base_uri . 'authorize');
    $auth_uri->query_param($_, $args{$_}) for keys %args;
    return (uri => $auth_uri, state => $args{state});
    # request has to be viewed on browser and accepted.
    #
    # my $r = await $self->http->do_request(uri => $auth_uri, method => 'GET');
    # $log->warnf('rr %s', $r->content);
    # Once accepted redirect_url will be called with authorization code passed.
}

=head2 obtain_token

Method used to obtain access and refresh token from passed Authorization code.
L<https://developer.spotify.com/documentation/general/guides/authorization-guide/> especifically Step 2 & 4 in Authorization Code Flow.
Support for other methods can be easily added, however not needed at the moment.
Accepts limited parameters, and based on them will decide whether to get new token from Authorization code
or from a previously obtained refresh token.
Note that it does not check for L</state> value as this step should be handled by caller.

=over 4

=item code

representing Spotify Authorization Code, if passed, C<grant_type> parameter will be set to authorization_code.
and the request will be for a new Spotify Token pair.

=item redirect_uri

optional, must be matching the one used to obtain code. Only used when L</code> parameter is present

=item auto_refresh

if set it will start C<IO::Async::Timer::Periodic> in order to refresh access token before it expires.
Accessed from L</"Token Timer">

=back

=cut

async sub obtain_token {
    my ($self, %args) = @_;
    my $allowed_params = join '|', qw(client_id client_secret grant_type redirect_uri code refresh_token);
    my $auto_refresh = delete $args{auto_refresh} || 0;

    if ( exists $args{code}) {
        $args{grant_type} = 'authorization_code';
        $args{redirect_uri} //= $self->redirect_uri->as_string;
    } else {
        $args{grant_type} = 'refresh_token';
        $args{refresh_token} = $self->token->refresh_token;
    }

    # We can also pass client_id & client_secret in body param
    # Instead of base64 encoded Authorization header
    $args{client_id} = $self->client_id;
    $args{client_secret} = $self->client_secret;

    # Don't leak any extra params
    delete $args{$_} for grep { !/$allowed_params/ } keys %args;

    my $result;
    try {
        $result = await $self->http->do_request(
            method => 'POST',
            uri => URI->new($self->base_uri . join '/', 'api', 'token'),
            content_type => 'application/x-www-form-urlencoded',
            content => \%args,
            headers => {
                Authorization => "Basic ". encode_base64(join(':', $self->client_id, $self->client_secret), ''),
            },
        );
        $result = decode_json_utf8($result->decoded_content);
    } catch ($e) {
        use Data::Dumper;
        $log->errorf('Error obtaining Access token | %s', Dumper($e));
        return;
    }

    $self->token->renew($result);

    $log->debugf('obtaining token response: %s', $self->token);
    if ($auto_refresh) {
        $log->infof('Enabling auto token refresh...');
        $self->token_timer->start;
    }

}

=head2 http

Accessor to underlying L<Net::Async::HTTP> object, which is used to perform requests.

=cut

sub http { shift->{http} }

=head2 token_timer

An instance of L<IO::Async::Timer::Periodic> which is set to be called before C<46> seconds
of curret Token expiry time
Can be started by L</auto_refresh> option

=cut

sub token_timer { shift->{token_timer} }

=head2 client_id

Accessor for Spotify App Client ID

=cut

sub client_id { shift->{client_id} }

=head2 client_secret

Accessor for Spotify App Client Secret

=cut

sub client_secret { shift->{client_secret} }

=head2 redirect_uri

Accessor for Spotify App defined redirect URL

=cut

sub redirect_uri { shift->{redirect_uri} //= URI->new('http://localhost/callback') }

=head2 base_uri

Accessor for Spotify Base URI

=cut

sub base_uri { shift->{base_uri} //= URI->new('https://accounts.spotify.com/') }

1;

=head1 spotify-cli.pl

Located at F<bin/spotify-cli.pl>, This will be installed with the package, where it gives us a CLI for Spotify API.
Have some predefined commands, while it supports all API calls. Can run in various modes, one of them being C<interactive>.
Currently it is just a simple CLI tool with minimal functionality.
Serves as implementation example for this library.

    # For full information
    spotify-cli.pl -h

Independent CLI library will be implemented using L<Tickit>

=head1 crawl-api-doc.pl

Located at F<scripts/spotify-cli.pl>, this script is mainly used for ease of implementation and maintability.
It will parse L<"Spotify API Documentation page"|https://developer.spotify.com/documentation/web-api/reference> and utilizes a L<Template>
in order to create corresponding Classes for every Spotify API type and call, along with Responce Objects.
these 4 templates are what currently availabe and can be extended:

=over 4

=item SpotifyAPI_main_pm.tt2

Located at F<scripts/SpotifyAPI_main_pm.tt2> | Template for all L<Net::Async::Spotify::API::*>
Main base class for custom functionality. One time generation.

=item SpotifyAPI_pm.tt2

Located at F<scripts/SpotifyAPI_pm.tt2> | Template for all L<Net::Async::Spotify::API::Generated::*>
Class for all available Spotify API calls defined as methods. Updated on Spotify API new releases.

=item SpotifyObj_main_pm.tt2

Located at F<scripts/SpotifyObj_main_pm.tt2> | Template for all <Net::Async::Spotify::Object::*>
Main base class for custom functionality. One time generation.

=item SpotifyObj_pm.tt2

Located at F<scripts/SpotifyObj_pm.tt2> | Template for all <Net::Async::Spotify::Object::Generated::*>
Class for all available Spotify Response Objects, where fields are set to be methods. Updated on Spotify API new releases.

=back

It accepts a couple of options to determines what you want to do.

    # To generate all of the above.
    perl scripts/crawl-api-doc.pl -e -o -i

    # Can be also used to explore API, combined with jq
    perl scripts/crawl-api-doc.pl -j | jq .

    # For more details and optionns
    perl scripts/crawl-api-doc.pl -h

Note that when Spotify releases changes on their API, all what it takes to update this package is:

  - Spotify to update their documentation page.
  - run this script and release changes.

=cut
