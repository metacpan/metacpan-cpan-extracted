package Net::Google::AuthSub;

use strict;
use vars qw($VERSION $APP_NAME);
use LWP::UserAgent;
use HTTP::Request::Common;
use Net::Google::AuthSub::Response;
use URI;

$VERSION  = '0.5';
$APP_NAME = __PACKAGE__."-".$VERSION;

use constant CLIENT_LOGIN => 0;
use constant AUTH_SUB     => 1;

=head1 NAME

Net::Google::AuthSub - interact with sites that implement Google style AuthSub

=head1 SYNOPSIS


    my $auth = Net::Google::AuthSub->new;
    my $response = $auth->login($user, $pass);

    if ($response->is_success) {
        print "Hurrah! Logged in\n";
    } else {
        die "Login failed: ".$response->error."\n";
    }

    my %params = $auth->auth_params;
    $params{Content_Type}             = 'application/atom+xml; charset=UTF-8';
    $params{Content}                  = $xml;
    $params{'X-HTTP-Method-Override'} = 'DELETE';        

    my $request = POST $url, %params;
    my $r = $user_agent->request( $request );


=head1 ABOUT AUTHSUB

AuthSub is Google's method of authentication for their web 
services. It is also used by other web sites.

You can read more about it here.

    http://code.google.com/apis/accounts/Authentication.html

A Google Group for AuthSub is here.

    http://groups.google.com/group/Google-Accounts-API

=head1 DEALING WITH CAPTCHAS

If a login response fails then it may set the error code to
'CaptchRequired' and the response object will allow you to 
retrieve the C<captchatoken> and C<captchaurl> fields.

The C<captchaurl> will be the url to a captcha image or you 
can show the user the web page

    https://www.google.com/accounts/DisplayUnlockCaptcha

Then retry the login attempt passing in the parameters 
C<logintoken> (which is the value of C<captchatoken>) and 
C<logincaptcha> which is the user's answer to the CAPTCHA.


    my $auth = Net::Google::AuthSub->new;
    my $res  = $auth->login($user, $pass);

    if (!$res->is_success && $res->error eq 'CaptchaRequired') {
        my $answer = display_captcha($res->captchaurl);
        $auth->login($user, $pass, logintoken => $res->captchatoken, logincaptcha => $answer);
    }


You can read more here

    http://code.google.com/apis/accounts/AuthForInstalledApps.html#Using

=head1 METHODS

=cut

=head2 new [param[s]]

Return a new authorisation object. The options are

=over 4

=item url

The base url of the web service to authenticate against.

Defaults to C<https://google.com/account>

=item service

Name of the Google service for which authorization is requested such as 'cl' for Calendar.

Defaults to 'xapi' for calendar.

=item source

Short string identifying your application, for logging purposes.

Defaults to 'Net::Google::AuthSub-<VERSION>'

=item accountType

Type of account to be authenticated.

Defaults to 'HOSTED_OR_GOOGLE'.

=back

See http://code.google.com/apis/accounts/AuthForInstalledApps.html#ClientLogin for more details.

=cut


our %BUGS = (
    'not_dopplr_any_more' => {
        'cuddled'       => 1,
        'json_response' => 1,
    },
);

sub new {
    my $class  = shift;
    my %params = @_;

    $params{_ua}           = LWP::UserAgent->new;    
    $params{_ua}->env_proxy;
    $params{url}         ||= 'https://www.google.com/accounts';
    $params{service}     ||= 'xapi';
    $params{source}      ||= $APP_NAME;
    $params{accountType} ||= 'HOSTED_OR_GOOGLE';
    $params{_compat}     ||= {};

    my $site = delete $params{_bug_compat};
    if (defined $site && exists $BUGS{$site}) {
        foreach my $key (keys %{$BUGS{$site}}) {
            $params{_compat}->{$key} = $BUGS{$site}->{$key};
        }
    }


    return bless \%params, $class;
}

=head2 login <username> <password> [opt[s]]

Login to google using your username and password.

Can optionally take a hash of options which will override the 
default login params. 

Returns a C<Net::Google::AuthSub::Response> object.

=cut

sub login {
    my ($self, $user, $pass, %opts) = @_;

    # setup auth request
    my %params = ( Email       => $user, 
                   Passwd      => $pass, 
                   service     => $self->{service}, 
                   source      => $self->{source},
                   accountType => $self->{accountType} );
    # allow overrides
    $params{$_} = $opts{$_} for (keys %opts);


    my $uri = URI->new($self->{url});
    $uri->path($uri->path.'/ClientLogin');
    my $tmp = $self->{_ua}->request(POST "$uri", [ %params ]);
    return $self->_response_failure($tmp) unless $tmp->is_success;
    my $r = Net::Google::AuthSub::Response->new($tmp, $self->{url}, _compat => $self->{_compat});


    # store auth token
    $self->{_auth}      = $r->auth;
    $self->{_auth_type} = CLIENT_LOGIN;
    $self->{user}       = $user;
    $self->{pass}       = $pass; 
    return $r;

}

sub _response_failure {
    my $self = shift;
    my $r    = shift;
    $@ = $r->content;   
    return Net::Google::AuthSub::Response->new(
        $r,
        $self->{url},
        _compat => $self->{_compat}
    ); }


=head2 authorised 

Whether or not we're authorised.

=cut

sub authorised {
    my $self = shift;
    return defined $self->{_auth};

}

=head2 authorized 

An alias for authorized.

=cut
*authorized = \&authorised;

=head2 auth <username> <token>

Use the AuthSub method for access.

See http://code.google.com/apis/accounts/AuthForWebApps.html 
for details.

=cut

sub auth {
    my ($self, $username, $token) = @_;
    $self->{_auth}      = $token;
    $self->{_auth_type} = AUTH_SUB;
    $self->{user}       = $username;
    return 1;
}

=head2 auth_token [token] 

Get or set the current auth token

=cut
sub auth_token {
    my $self = shift;
    $self->{_auth} = shift if @_;
    return $self->{_auth};
}

=head2 auth_type [type]

Get or set the current auth type

Returns either C<$Net::Google::AuthSub::CLIENT_LOGIN> or 
C<$Net::Google::AuthSub::AUTH_SUB>.

=cut
sub auth_type {
    my $self = shift;
    $self->{_auth_type} = shift if @_;
    return $self->{_auth_type};
}

=head2 request_token <next> <scope> [option[s]]

Return a URI object representing the URL which the user 
should be directed to in order to aquire a single use token.

The parameters are 

=over 4

=item next (required)

URL the user should be redirected to after a successful login. 
This value should be a page on the web application site, and 
can include query parameters.

=item scope (required)

URL identifying the service to be accessed. The resulting token 
will enable access to the specified service only. Some services 
may limit scope further, such as read-only access.

For example

    http://www.google.com/calendar/feed

=item secure

Boolean flag indicating whether the authentication transaction 
should issue a secure token (1) or a non-secure token (0). 
Secure tokens are available to registered applications only.

=item session

Boolean flag indicating whether the one-time-use token may be 
exchanged for a session token (1) or not (0).

=back

=cut

sub request_token {
    my $self = shift;
    my ($next, $scope, %opts) = @_;
    $opts{next}  = $next;
    $opts{scope} = $scope;

    my $uri = URI->new($self->{url});

    $uri->path($uri->path.'/AuthSubRequest');
    $uri->query_form(%opts);
    return $uri;
}


=head2 session_token

Exchange the temporary token for a long-lived session token.

The single-use token is acquired by visiting the url generated by
calling request_token.

Returns the token if success and undef if failure.

=cut

sub session_token {
    my $self = shift;

    my $uri = URI->new($self->{url});
    $uri->path($uri->path.'/AuthSubSessionToken');

    my %params = $self->auth_params();
    my $tmp    = $self->{_ua}->request(GET "$uri", %params);
    return $self->_response_failure($tmp) unless $tmp->is_success;    
    my $r      = Net::Google::AuthSub::Response->new($tmp, $self->{url}, _compat => $self->{_compat});

    # store auth token
    $self->{_auth}      = $r->token;
    
    return $r->token;
}

=head2 revoke_token

Revoke a valid session token. Session tokens have no expiration date and 
will remain valid unless revoked.

Returns 1 if success and undef if failure.

=cut

sub revoke_token {
    my $self = shift;

    my $uri = URI->new($self->{url});
    $uri->path($uri->path.'/AuthSubRevokeToken');

    my %params = $self->auth_params();
    my $r      = $self->{_ua}->request(GET "$uri", [ %params ]);
    return $self->_response_error($r) unless $r->is_success;
    return 1;

}

=head2 token_info

Call AuthSubTokenInfo to test whether a given session token is valid. 
This method validates the token in the same way that a Google service 
would; application developers can use this method to verify that their 
application is getting valid tokens and handling them appropriately 
without involving a call to the Google service. It can also be used to 
get information about the token, including next URL, scope, and secure 
status, as specified in the original token request.

Returns a C<Net::Google::AuthSub::Response> object on success or undef on failure.

=cut

sub token_info {
    my $self = shift;

    my $uri = URI->new($self->{url});
    $uri->path($uri->path.'/AuthSubTokenInfo');

    my %params = $self->auth_params();
    my $tmp    = $self->{_ua}->request(GET "$uri", [ %params ]);
    my $r      = Net::Google::AuthSub::Response->new($tmp, $self->{url}, _compat => $self->{_compat});    
    return $self->_response_failure($r) unless $r->is_success;
    return $r;
} 

=head2 auth_params

Return any parameters needed in an HTTP request to authorise your app.

=cut

sub auth_params {
    my $self  = shift;

    return () unless $self->authorised;
    return ( Authorization => $self->_auth_string );
}

my %AUTH_TYPES = ( CLIENT_LOGIN() => "GoogleLogin auth", AUTH_SUB() => "AuthSub token" );

sub _auth_string {
    my $self   = shift;
    return "" unless $self->authorised;
    if ($self->{_compat}->{uncuddled_auth}) {
        return sprintf '%s=%s', $AUTH_TYPES{$self->{_auth_type}}, $self->{_auth};
    } else {
        return sprintf '%s="%s"', $AUTH_TYPES{$self->{_auth_type}}, $self->{_auth};        
    }
}


=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright, 2007 - Simon Wistow

Released under the same terms as Perl itself

=cut


1;
