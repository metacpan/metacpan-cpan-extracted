package Net::Facebook::Oauth2;

use strict;
use warnings;
use LWP::UserAgent;
use URI;
use URI::Escape;
use JSON::MaybeXS;
use Carp;

BEGIN {
    my @time = localtime;
    if ($time[5] >= 118 && $time[4] > 8) {
        warn "\n****************************************************************************\n"
           . "[WARNING] This version of Net::Facebook::Oauth2 uses Facebook Graph API v2.8\n"
           . "which is SCHEDULED FOR DEPRECATION on 5 October 2018. If this module\n"
           . "(together with any associated code) is not updated, it may stop working!\n"
           . "****************************************************************************\n"
           ;
    }
};

use constant ACCESS_TOKEN_URL => 'https://graph.facebook.com/v2.8/oauth/access_token';
use constant AUTHORIZE_URL    => 'https://www.facebook.com/v2.8/dialog/oauth';

our $VERSION = '0.10';

sub new {
    my ($class,%options) = @_;
    my $self = {};
    $self->{options} = \%options;

    if (!$options{access_token}){
        croak "You must provide your application id in new()\nNet::Facebook::Oauth2->new( application_id => '...' )" unless defined $self->{options}->{application_id};
        croak "You must provide your application secret in new()\nNet::Facebook::Oauth2->new( application_secret => '...' )" unless defined $self->{options}->{application_secret};
    }

    $self->{browser}          = $options{browser}          || LWP::UserAgent->new;
    $self->{access_token_url} = $options{access_token_url} || ACCESS_TOKEN_URL;
    $self->{authorize_url}    = $options{authorize_url}    || AUTHORIZE_URL;
    $self->{display}          = $options{display}          || 'page'; ## other values popup and wab
    $self->{access_token}     = $options{access_token};

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
    $url .= '&state=' . $params{state}                 if $params{state};
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

Net::Facebook::Oauth2 - a simple Perl wrapper around Facebook OAuth v2.0 protocol

=for html
<a href="https://travis-ci.org/mamod/Net-Facebook-Oauth2"><img src="https://travis-ci.org/mamod/Net-Facebook-Oauth2.svg?branch=master"></a>

=head1 FACEBOOK GRAPH API VERSION

This module complies to Facebook Graph API version 2.8, the latest
at the time of publication, B<< scheduled for deprecation on October 5th, 2018 >>.

One month prior to that, using this version of Net::Facebook::Oauth2 will
trigger a warning message.

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
        scope   => [ 'public_profile', 'email', 'user_about_me', 'manage_pages' ],
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

    my $access_token = $fb->get_access_token(code => $code);

If you got so far, your user is logged! Save this access token in your
database or session.

Later on you can use that access token to communicate with Facebook on behalf
of this user:

    my $fb = Net::Facebook::Oauth2->new(
        access_token => $access_token
    );

    my $info = $fb->get(
        'https://graph.facebook.com/v2.8/me'   # Facebook API URL
    );

    print $info->as_json;

=head1 DESCRIPTION

Net::Facebook::Oauth2 gives you a way to simply access FaceBook Oauth 2.0 protocol

For more information please see example folder shipped with this Module

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

=item * C<authorize_url>

Overrides the default (2.8) API endpoint for Facebook's oauth.
Used mostly for testing new versions.

=item * C<access_token_url>

Overrides the default (2.8) API endpoint for Facebook's access token.
Used mostly for testing new versions.

=item * C<auth_type>

When a user declines a given permission, you must reauthorize them. But when
you do so, any previously declined permissions will not be asked again by
Facebook. Set this argument to C<'rerequest'> to explicitly tell the dialog
you're re-asking for a declined permission.

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

    scope => ['user_events','manage_pages', ...]

Array of Extended permissions as described by facebook Oauth API.
You can get more information about scope/Extended Permission from

L<https://developers.facebook.com/docs/facebook-login/permissions/>

Please note that requesting information other than C<public_profile>,
C<email> and C<user_friends> B<will require your app to be reviewed by Facebook!>

=item * C<state>

    state => '123456abcde'

An arbitrary unique string provided by you to guard against Cross-site Request Forgery.

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

From the name, for wab and mobile applications this option is the best
facebook authorization page will fit there :)

=back

=item * C<response_type>

    response_type => 'code'

When the redirect back to the app occurs, determines whether the response
data is in URL parameters or fragments. Defaults to C<code>, which is
Facebook's default and useful for cases where the server handles the token
(which is most likely why you are using this module), but can be also be
C<token>, C<code%20token>, or C<granted_scopes>. Please see
L<< Facebook's login documentation|https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow >>
for more information.

=back

=head2 C<$fb-E<gt>get_access_token( %args )>

This method issues a GET request to Facebook's API to retrieve the
access token string for the specified code (passed as an argument).

Returns the access token string or raises an exception in case of errors.

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
user, and then associate your own user's unique id to Facebook's. This is
usually done by making a GET request to the C<me> API endpoint, as shown
in the SYNOPSIS.

B<IMPORTANT:> Expect that the length of all access token types will change
over time as Facebook makes changes to what is stored in them and how they
are encoded. You can expect that they will grow and shrink over time.
Please use a variable length data type without a specific maximum size to
store access tokens.

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
