package Net::Facebook::Oauth2;

use strict;
use warnings;
use LWP::UserAgent;
use URI;
use URI::Escape;
use JSON::MaybeXS;
use Carp;

our $VERSION = '0.11';

sub new {
    my ($class,%options) = @_;
    my $self = {};
    $self->{options} = \%options;

    my $api_version = defined $options{api_version} ? $options{api_version} : 'v3.1';

    if (!defined $options{access_token}){
        croak "You must provide your application id in new()\nNet::Facebook::Oauth2->new( application_id => '...' )" unless defined $self->{options}->{application_id};
        croak "You must provide your application secret in new()\nNet::Facebook::Oauth2->new( application_secret => '...' )" unless defined $self->{options}->{application_secret};
    }

    if (defined $options{access_token_url}) {
        croak "cannot pass access_token_url AND api_version" if defined $options{api_version};
        $self->{access_token_url} = $options{access_token_url};
    }
    else {
        $self->{access_token_url} = "https://graph.facebook.com/$api_version/oauth/access_token";
    }

    if (defined $options{authorize_url}) {
        croak "cannot pass authorize_url AND api_version" if defined $options{api_version};
        $self->{authorize_url} = $options{authorize_url};
    }
    else {
        $self->{authorize_url} = "https://www.facebook.com/$api_version/dialog/oauth";
    }

    if (defined $options{debug_token_url}) {
        croak "cannot pass debug_token_url AND api_version" if defined $options{api_version};
        $self->{debug_token_url} = $options{debug_token_url};
    }
    else {
        $self->{debug_token_url} = "https://graph.facebook.com/$api_version/debug_token";
    }

    $self->{browser}      = $options{browser} || LWP::UserAgent->new;
    $self->{display}      = $options{display} || 'page'; ## other values popup and wab
    $self->{access_token} = $options{access_token};

    return bless($self, $class);
}

sub get_authorization_url {
    my ($self,%params) = @_;

    $params{callback} ||= $self->{options}->{callback};
    croak "You must pass a callback parameter with Oauth v2.0" unless defined $params{callback};

    $params{display} = $self->{display} unless defined $params{display};
    $self->{options}->{callback} = $params{callback};

    my $url = $self->{authorize_url}
    ."?client_id="
    .uri_escape($self->{options}->{application_id})
    ."&redirect_uri="
    .uri_escape($params{callback});

    if ($params{scope}) {
        my $scope = join(',', @{$params{scope}});
        $url .= '&scope=' . $scope if $scope;
    }
    # state is now required:
    $url .= '&state=' . (defined $params{state} ? $params{state} : time);

    $url .= '&response_type=' . $params{response_type} if $params{response_type};
    $url .= '&auth_type=' . $params{auth_type}         if $params{auth_type};
    $url .= "&display=".$params{display};

    return $url;
}


sub get_access_token {
    my ($self,%params) = @_;
    $params{callback} ||= $self->{options}->{callback};
    $params{code} ||= $self->{options}->{code};

    croak "You must pass a code parameter with Oauth v2.0" unless defined $params{code};
    croak "You must pass callback URL" unless defined $params{callback};
    $self->{options}->{code} = $params{code};

    ###generating access token URL
    my $getURL = $self->{access_token_url}
    ."?client_id="
    .uri_escape($self->{options}->{application_id})
    ."&redirect_uri="
    .uri_escape($params{callback})
    ."&client_secret="
    .uri_escape($self->{options}->{application_secret})
    ."&code=$params{code}";

    my $response = $self->{browser}->get($getURL);
    my $json     = decode_json($response->content());

    if (!$response->is_success || exists $json->{error}){
        ##got an error response from facebook. die and display error message
        croak "'" . $json->{error}->{type}. "'" . " " .$json->{error}->{message};
    }
    elsif ($json->{access_token}) {
        ##everything is ok proccess response and extract access token
        return $self->{access_token} = $json->{access_token};
    }
    else {
        croak "can't get access token from " . $response->content();
    }
}

sub get_long_lived_token {
    my ($self,%params) = @_;

    if (!$self->{access_token}) {
        croak "You must pass the access_token" unless defined $params{access_token};
    }

    my $getURL = $self->{access_token_url}
        . '?grant_type=fb_exchange_token'
        . '&client_id=' . uri_escape($self->{options}->{application_id})
        . '&client_secret=' . uri_escape($self->{options}->{application_secret})
        . '&fb_exchange_token=' . uri_escape($self->{access_token} || $params{access_token})
        ;
    my $response = $self->{browser}->get($getURL);
    my $json     = decode_json($response->content());
    if (!$response->is_success || exists $json->{error}) {
        croak "'" . $json->{error}->{type}. "'" . " " .$json->{error}->{message};
    }
    elsif ($json->{access_token}) {
        return $self->{access_token} = $json->{access_token};
    }
    else {
        croak "can't get long lived access token from " . $response->content();
    }
}

sub debug_token {
    my ($self,%params) = @_;
    croak "You must pass the 'input' access token to inspect"
        unless defined $params{input};

    # NOTE: according to FB's documentation, instead of passing an
    # app token we can simply pass access_token=app_id|app_secret:
    # https://developers.facebook.com/docs/facebook-login/access-tokens/#apptokens
    my $getURL = $self->{debug_token_url}
        . "?input_token=" . uri_escape($params{input})
        . "&access_token="
        . join('|',
            uri_escape($self->{options}->{application_id}),
            uri_escape($self->{options}->{application_secret})
        );

    my $response = $self->{browser}->get($getURL);
    my $json     = decode_json($response->content());
    if (!$response->is_success || exists $json->{error}){
        ##got an error response from facebook. die and display error message
        croak "'" . $json->{error}->{type}. "'" . " " .$json->{error}->{message};
    }
    elsif (!exists $json->{data}->{app_id} || !exists $json->{data}->{user_id}) {
        return;
    }
    elsif (!$params{skip_check} && (''.$json->{data}->{app_id}) ne (''.$self->{options}->{application_id}) ) {
        return;
    }
    return $json->{data};
}


sub get {
    my ($self,$url,$params) = @_;
    unless ($self->_has_access_token($url)) {
        croak "You must pass access_token" unless defined $self->{access_token};
        $url .= $self->{_has_query} ? '&' : '?';
        $url .= "access_token=" . $self->{access_token};
    }

    ##construct the new url
    my @array;

    while ( my ($key, $value) = each(%{$params})){
        $value = uri_escape($value);
        push(@array, "$key=$value");
    }

    my $string = join('&', @array);
    $url .= "&".$string if $string;

    my $response = $self->{browser}->get($url);
    my $content = $response->content();
    return $self->_content($content);
}

sub post {
    my ($self,$url,$params) = @_;
    unless ($self->_has_access_token($url)) {
        croak "You must pass access_token" unless defined $self->{access_token};
        $params->{access_token} = $self->{access_token};
    }
    my $response = $self->{browser}->post($url,$params);
    my $content = $response->content();
    return $self->_content($content);
}

sub delete {
    my ($self,$url,$params) = @_;
    unless ($self->_has_access_token($url)) {
        croak "You must pass access_token" unless defined $self->{access_token};
        $params->{access_token} = $self->{access_token};
    }
    my $response = $self->{browser}->delete($url,$params);
    my $content = $response->content();
    return $self->_content($content);
}

sub as_hash {
    my ($self) = @_;
    return decode_json($self->{content});
}

sub as_json {
    my ($self) = @_;
    return $self->{content};
}

sub _content {
    my ($self,$content) = @_;
    $self->{content} = $content;
    return $self;
}

sub _has_access_token {
    my ($self, $url) = @_;
    my $uri = URI->new($url);
    my %q = $uri->query_form;
    #also check if we have a query and save result
    $self->{_has_query} = $uri->query();
    if (grep { $_ eq 'access_token' } keys %q) {
        return 1;
    }
    return;
}

1;
__END__
=head1 NAME

Net::Facebook::Oauth2 - a simple Perl wrapper around Facebook OAuth 2.0 protocol

=for html
<a href="https://travis-ci.org/mamod/Net-Facebook-Oauth2"><img src="https://travis-ci.org/mamod/Net-Facebook-Oauth2.svg?branch=master"></a>

=head1 FACEBOOK GRAPH API VERSION

This module complies to Facebook Graph API version 3.1, the latest
at the time of publication, B<< scheduled for deprecation not sooner than July 26th, 2020 >>.

=head1 SYNOPSIS

Somewhere in your application's login process:

    use Net::Facebook::Oauth2;

    my $fb = Net::Facebook::Oauth2->new(
        application_id     => 'your_application_id', 
        application_secret => 'your_application_secret',
        callback           => 'http://yourdomain.com/facebook/callback'
    );

    # get the authorization URL for your application
    my $url = $fb->get_authorization_url(
        scope   => [ 'email' ],
        display => 'page'
    );

Now redirect the user to this C<$url>.

Once the user authorizes your application, Facebook will send him/her back
to your application, on the C<callback> link provided above. PLEASE NOTE
THAT YOU MUST PRE-AUTHORIZE YOUR CALLBACK URI ON FACEBOOK'S APP DASHBOARD.

Inside that callback route, use the verifier code parameter that Facebook
sends to get the access token:

    # param() below is a bogus function. Use whatever your web framework
    # provides (e.g. $c->req->param('code'), $cgi->param('code'), etc)
    my $code = param('code');

    use Try::Tiny;  # or eval {}, or whatever

    my ($unique_id, $access_token);
    try {
        $access_token = $fb->get_access_token(code => $code); # <-- could die!

        # Facebook tokens last ~2h, but you may upgrade them to ~60d if you want:
        $access_token = $fb->get_long_lived_token( access_token => $access_token );

        my $access_data = $fb->debug_token( input => $access_token );
        if ($access_data && $access_data->{is_valid}) {
            $unique_id = $access_data->{user_id};
            # you could also check here for what scopes were granted to you
            # by inspecting $access_data->{scopes}->@*
        }
    } catch {
        # handle errors here!
    };

If you got so far, your user is logged! Save the access token in your
database or session. As shown in the example above, Facebook also provides
a unique I<user_id> for this token so you can associate it with a particular
user of your app.

Later on you can use that access token to communicate with Facebook on behalf
of this user:

    my $fb = Net::Facebook::Oauth2->new(
        access_token => $access_token
    );

    my $info = $fb->get(
        'https://graph.facebook.com/v3.1/me'   # Facebook API URL
    );

    print $info->as_json;

NOTE: if you skipped the call to C<debug_token()> you can still find the
unique user id value with a call to the 'me' endpoint shown above, under
C<< $info->{id} >>

=head1 DESCRIPTION

Net::Facebook::Oauth2 gives you a way to simply access FaceBook Oauth 2.0
protocol.

The example folder contains some snippets you can look at, or for more
information just keep reading :)

=head1 SEE ALSO

For more information about Facebook Oauth 2.0 API

Please Check
L<http://developers.facebook.com/docs/>

get/post Facebook Graph API
L<http://developers.facebook.com/docs/api>

=head1 USAGE

=head2 C<Net::Facebook::Oauth-E<gt>new( %args )>

Returns a new object to handle user authentication.
Pass arguments as a hash. The following arguments are I<REQUIRED>
unless you're passing an access_token (see optional arguments below):

=over 4

=item * C<application_id>

Your application id as you get from facebook developers platform
when you register your application

=item * C<application_secret>

Your application secret id as you get from facebook developers platform
when you register your application

=back

The following arguments are I<OPTIONAL>:

=over 4

=item * C<access_token>

If you want to instantiate an object to an existing access token, you may
do so by passing it to this argument.

=item * C<browser>

The user agent that will handle requests to Facebook's API. Defaults to
LWP::UserAgent, but can be any method that implements the methods C<get>,
C<post> and C<delete> and whose response to such methods implements
C<is_success> and C<content>.

=item * C<display>

See C<display> under the C<get_authorization_url> method below.

=item * C<api_version>

Use this to replace the API version on all endpoints. The default
value is 'v3.1'. Note that defining an api_version parameter together with
C<authorize_url>, C<access_token_url> or C<debug_token_url> is a fatal error.

=item * C<authorize_url>

Overrides the default (3.1) API endpoint for Facebook's oauth.
Used mostly for testing new versions.

=item * C<access_token_url>

Overrides the default (3.1) API endpoint for Facebook's access token.
Used mostly for testing new versions.

=item * C<debug_token_url>

Overrides the default (3.1) API endpoint for Facebook's token information.
Used mostly for testing new versions.

=back

=head2 C<$fb-E<gt>get_authorization_url( %args )>

Returns an authorization URL for your application. Once you receive this
URL, redirect your user there in order to authorize your application.

The following argument is I<REQUIRED>:

=over 4

=item * C<callback>

    callback => 'http://example.com/login/facebook/success'

The callback URL, where Facebook will send users after they authorize
your application. YOU MUST CONFIRM THIS URL ON FACEBOOK'S APP DASHBOARD.

To do that, go to the App Dashboard, click Facebook Login in the right-hand
menu, and check the B<Valid OAuth redirect URIs> in the Client OAuth Settings
section.

=back

This method also accepts the following I<OPTIONAL> arguments:

=over 4

=item * C<scope>

    scope => ['user_birthday','user_friends', ...]

Array of Extended permissions as described by the Facebook Oauth API.
You can get more information about scope/Extended Permission from

L<https://developers.facebook.com/docs/facebook-login/permissions/>

Please note that requesting information other than C<name>, C<email> and
C<profile_picture> B<will require your app to be reviewed by Facebook!>

=item * C<state>

    state => '123456abcde'

An arbitrary unique string provided by you to guard against Cross-site Request
Forgery. This value will be returned to you by Facebook, unchanged. Note that,
as of Facebook API v3.0, this argument is I<mandatory>, so if you don't
provide a 'state' argument, we will default to C<time()>.

=item * C<auth_type>

When a user declines a given permission, you must reauthorize them. But when
you do so, any previously declined permissions will not be asked again by
Facebook. Set this argument to C<'rerequest'> to explicitly tell the dialog
you're re-asking for a declined permission.

=item * C<display>

    display => 'page'

How to display Facebook Authorization page. Defaults to C<page>.
Can be any of the following:

=over 4

=item * C<page>

This will display facebook authorization page as full page

=item * C<popup>

This option is useful if you want to popup authorization page
as this option tell facebook to reduce the size of the authorization page

=item * C<wab>

From the name, for wab and mobile applications this option is the best, as
the facebook authorization page will fit there :)

=back

=item * C<response_type>

    response_type => 'code'

When the redirect back to the app occurs, determines whether the response
data is in URL parameters or fragments. Defaults to C<code>, which is
Facebook's default and useful for cases where the server handles the token
(which is most likely why you are using this module), but can be also be
C<token>, C<code%20token>, or C<granted_scopes>. Note that changing this to
anything other than 'code' might change the login flow described in this
documentation, rendering calls to C<get_access_token()> pointless.
Please see
L<< Facebook's login documentation|https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow >>
for more information.

=back

=head2 C<$fb-E<gt>get_access_token( %args )>

This method issues a GET request to Facebook's API to retrieve the
access token string for the specified code (passed as an argument).

Returns the access token string or raises an exception in case of errors
(B<make sure to trap calls with eval blocks or a try/catch module>). Note
that Facebook's access tokens are short-lived, around 2h of idle time
before expiring. If you want to "upgrade" the token to a long lived one
(with around 60 days of idle time), use this token to feed the
C<get_long_lived_token()> method.

You should call this method inside the route for the callback URI defined
in the C<get_authorization_url> method. It receives the following arguments:

=over 4

=item * C<code>

This is the verifier code that Facebook sends back to your
callback URL once user authorize your app, you need to capture
this code and pass to this method in order to get the access token.

Verifier code will be presented with your callback URL as code
parameter as the following:

http://your-call-back-url.com?code=234er7y6fdgjdssgfsd...

Note that if you have fiddled with the C<response_type> argument,
you might not get this parameter properly.

=back

When the access token is returned you need to save it in a secure
place in order to use it later in your application. The token indicates
that a user has authorized your site/app, meaning you can associate that
token to that user and issue API requests to Facebook on their behalf.

To know I<WHICH> user has granted you the authorization (e.g. when building
a login system to associate that token with a unique user on your database),
you must make a request to fetch Facebook's own unique identifier for that
user, and then associate your own user's unique id to Facebook's.

This was usually done by making a GET request to the C<me> API endpoint and
looking for the 'id' field. However, Facebook has introduced a new endpoint
for that flow that returns the id (this time as 'user_id') and some extra
validation data, like whether the token is valid, to which app it refers to,
what scopes the user agreed to, etc, so now you are encouraged to call the
C<debug_token()> method as shown in the SYNOPSIS.

B<IMPORTANT:> Expect that the length of all access token types will change
over time as Facebook makes changes to what is stored in them and how they
are encoded. You can expect that they will grow and shrink over time.
Please use a variable length data type without a specific maximum size to
store access tokens.

=head2 C<$fb-E<gt>get_long_lived_token( access_token =E<gt> $access_token )

Asks facebook to retrieve the long-lived (~60d) version of the provided
short-lived (~2h) access token retrieved from C<get_access_token()>. If
successful, this method will return the long-lived token, which you can
use to replace the short-lived one. Otherwise, it croaks with an error
message, in which case you can continue to use the short-lived version.

L<See here|https://developers.facebook.com/docs/facebook-login/access-tokens/refreshing>
for the gory details.

=head2 C<$fb-E<gt>debug_token( input =E<gt> $access_token )>

This method should be called right after C<get_access_token()>. It will
query Facebook for details about the given access token and validate that
it was indeed granted to your app (and not someone else's).

It requires a single argument, C<input>, containing the access code obtained
from calling C<get_access_token>.

It croaks on HTTP/connection/Facebook errors, returns nothing if for whatever
reason the response is invalid without errors (e.g. no app_id and no user_id),
and also if the returned app_id is not the same as your own application_id
(pass a true value to C<skip_check> to skip this validation).

If all goes well, it returns a hashref with the JSON structure returned by
Facebook.


=head2 C<$fb-E<gt>get( $url, $args )>

Sends a GET request to Facebook and stores the response in the given object.

=over 4

=item * C<url>

Facebook Graph API URL as string. You must provide the full URL.

=item * C<$args>

hashref of parameters to be sent with graph API URL if required.

=back

You can access the response using the following methods:

=over 4

=item * C<$responseE<gt>as_json>

Returns response as json object

=item * C<$responseE<gt>as_hash>

Returns response as perl hashref

=back

For more information about facebook graph API, please check
http://developers.facebook.com/docs/api

=head2 C<$fb-E<gt>post( $url, $args )>

Send a POST request to Facebook and stores the response in the given object.
See the C<as_hash> and C<as_json> methods above for how to retrieve the
response.

=over 4

=item * C<url>

Facebook Graph API URL as string

=item * C<$args>

hashref of parameters to be sent with graph API URL

=back

For more information about facebook graph API, please check
L<http://developers.facebook.com/docs/api>

=head2 C<$fb-E<gt>delete( $url, $args )>

Send a DELETE request to Facebook and stores the response in the given object.
See the C<as_hash> and C<as_json> methods above for how to retrieve the
response.

=over 4

=item * C<url>

Facebook Graph API URL as string

=item * C<$args>

hashref of parameters to be sent with graph API URL

=back

=head1 AUTHOR

Mahmoud A. Mehyar, E<lt>mamod.mehyar@gmail.comE<gt>

=head1 CONTRIBUTORS

Big Thanks To

=over 4

=item * Takatsugu Shigeta L<@comewalk|https://github.com/comewalk>

=item * Breno G. de Oliveira L<@garu|https://github.com/garu>

=item * squinker L<@squinker|https://github.com/squinker>

=item * Valcho Nedelchev L<@valchonedelchev|https://github.com/valchonedelchev>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2016 by Mahmoud A. Mehyar

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
