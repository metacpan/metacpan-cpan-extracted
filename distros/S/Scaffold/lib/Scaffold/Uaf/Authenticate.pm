package Scaffold::Uaf::Authenticate;

our $VERSION = '0.03';

use 5.8.8;
use Try::Tiny;
use Scaffold::Uaf::User;

use Scaffold::Class
  version   => $VERSION,
  base      => 'Badger::Mixin',
  utils     => 'encrypt',
  constants => 'TRUE FALSE TOKEN_ID SESSION_ID',
  accessors => 'uaf_filter uaf_limit uaf_timeout uaf_secret uaf_login_rootp 
                uaf_denied_rootp uaf_expired_rootp uaf_validate_rootp 
                uaf_logout_rootp uaf_login_title uaf_login_wrapper 
                uaf_login_template uaf_denied_title uaf_denied_wrapper 
                uaf_denied_template uaf_logout_title uaf_logout_template 
                uaf_logout_wrapper uaf_cookie_path uaf_cookie_domain 
                uaf_cookie_secure uaf_handle',
  mixins    => 'uaf_filter uaf_limit uaf_timeout uaf_secret uaf_login_rootp 
                uaf_denied_rootp uaf_expired_rootp uaf_validate_rootp 
                uaf_logout_rootp uaf_login_title uaf_login_wrapper 
                uaf_login_template uaf_denied_title uaf_denied_wrapper 
                uaf_denied_template uaf_logout_title uaf_logout_template 
                uaf_logout_wrapper uaf_cookie_path uaf_cookie_domain 
                uaf_cookie_secure uaf_is_valid uaf_validate uaf_invalidate 
                uaf_set_token uaf_avoid uaf_init uaf_check_credentials
                uaf_handle'
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub uaf_is_valid {
    my ($self) = @_;

    my $ip;
    my $token;
    my $access;
    my $old_ip;
    my $old_token;
    my $new_token;
    my $user = undef;

    $ip = $self->scaffold->request->address;

    if ($token = $self->stash->cookies->get(TOKEN_ID)) {

        $new_token = $token->value;
        $old_ip = $self->scaffold->session->get('uaf_remote_ip') || '';
        $old_token = $self->scaffold->session->get('uaf_token') || '';

        # This should work for just about everything except a load
        # balancing, natted firewall. And yeah, they do exist.

        if (($new_token eq $old_token) and ($ip eq $old_ip)) {

            $user = $self->scaffold->session->get('uaf_user');
            $access = $user->attribute('last_access');
            $user->attribute('last_access', time());
            $self->scaffold->session->set('uaf_user', $user);
            $user = undef if ($access  <  (time() - $self->uaf_timeout));

        }

    }

    return $user;

}

sub uaf_validate {
    my ($self, $username, $password) = @_;

    my $attempts;
    my $ip = "";
    my $user = undef;

    $ip = $self->scaffold->request->address;

    if ($self->uaf_check_credentials($username, $password)) {

        $user = Scaffold::Uaf::User->new(username => $username);
        $attempts = $self->scaffold->session->get('uaf_login_attempts');

        $user->attribute('last_access', time());
        $user->attribute('login_attempts', $attempts);

        $self->scaffold->session->set('uaf_user', $user);
        $self->scaffold->session->set('uaf_remote_ip', $ip);

    }

    return $user;

}

sub uaf_invalidate {
    my ($self) = @_;

    $self->scaffold->session->expire();
    $self->stash->cookies->delete(TOKEN_ID);

}

sub uaf_set_token {
    my ($self, $user) = @_;

    my $salt = $user->attribute('salt') || '';
    my $token = encrypt($user->username, ':', time(), ':', $salt, $$);

    $self->stash->cookies->set(
        name  => TOKEN_ID,
        value => $token,
        path  => $self->uaf_cookie_path
    );

    $self->scaffold->session->set('uaf_token', $token);

}

sub uaf_avoid {
    my ($self) = @_;

    return 1;

}

sub uaf_check_credentials {
    my ($self, $username, $password) = @_;

    return TRUE if ((($username eq 'admin') and ($password eq 'admin')) or 
                    (($username eq 'demo')  and ($password eq 'demo')));

}

sub uaf_init {
    my ($self) = @_;

    my $config = $self->scaffold->config('configs');
    my $app_rootp = $config->{app_rootp};

    $app_rootp = '' if ($app_rootp eq '/');

    $self->{uaf_cookie_path}    = $config->{uaf_cookie_path} || '/';
    $self->{uaf_cookie_domain}  = $config->{uaf_cookie_domain} || "";
    $self->{uaf_cookie_secure}  = $config->{uaf_cookie_secure};
    $self->{uaf_limit}          = $config->{uaf_limit} || 3;
    $self->{uaf_timeout}        = $config->{uaf_timeout} || 3600;
    $self->{uaf_secret}         = $config->{uaf_secret} || 'w3s3cR7';
    $self->{uaf_filter}         = $config->{uaf_filter} || 
      qr/^${app_rootp}\/(login|static|favicon.ico|robots.txt).*/;

    $self->{uaf_handle}         = $config->{uaf_handle} || 'uaf';
    $self->{uaf_login_rootp}    = $app_rootp . '/login';
    $self->{uaf_logout_rootp}   = $app_rootp . '/logout';
    $self->{uaf_denied_rootp}   = $self->{uaf_login_rootp} . '/denied';
    $self->{uaf_expired_rootp}  = $self->{uaf_login_rootp} . '/expired';
    $self->{uaf_validate_rootp} = $self->{uaf_login_rootp} . '/validate';

    # set default login template values

    $self->{uaf_login_title}    = $config->{uaf_login_title} || 'Please Login';
    $self->{uaf_login_wrapper}  = $config->{uaf_login_wrapper} || 'wrapper.tt';
    $self->{uaf_login_template} = $config->{uaf_login_template} || 'uaf_login.tt';

    # set default denied template values

    $self->{uaf_denied_title}    = $config->{uaf_denied_title} || 'Login Denied';
    $self->{uaf_denied_wrapper}  = $config->{uaf_denied_wrapper} || 'wrapper.tt';
    $self->{uaf_denied_template} = $config->{uaf_denied_template} || 'uaf_denied.tt';

    # set default logout template values

    $self->{uaf_logout_title}    = $config->{uaf_logout_title} || 'Logout';
    $self->{uaf_logout_wrapper}  = $config->{uaf_logout_wrapper} || 'wrapper.tt';
    $self->{uaf_logout_template} = $config->{uaf_logout_template} || 'uaf_logout.tt';

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Uaf::Authenticate - An Basic Authentication Framework

=head1 DESCRIPTION

This mixin is responsible for authenicating, and creating the User object. 
This module should be overridden and extended as needed by your application.

This module understands the following config settings:

 uaf_cookie_path     - The path for the security token, defaults to "/"
 uaf_cookie_domain   - The cookie domain, not currently used
 uaf_cookie_secure   - Wither the cookie should only be used with SSL

 uaf_limit           - the limit on login attempts, defaults to 3
 uaf_timeout         - the timeout for the session, defaults to 3600
 uaf_secret          - the value to use as a "salt" when encrypting
 uaf_filter          - the url filter to use, defaults to /^{app_rootp}\/(login|static).*/

 uaf_login_title     - title for the login page, defaults to 'Please Login"
 uaf_login_wrapper   - the wrapper for the login page, defaults to "wrapper.tt"
 uaf_login_template  - the template for the login page, defaults to "uaf_login.tt"

 uaf_denied_title    - title for the denied page, defaults to "Login Denied"
 uaf_denied_wrapper  - the wrapper for the denied page, defaults to "wrapper.tt"
 uaf_denied_template - the template for the denied page, defaults to "uaf_denied.tt"

 uaf_logout_title    - title for the logout page, default to "Logout"
 uaf_logout_wrapper  - the wrapper for the logout page, defaults to "wrapper.tt"
 uaf_logout_template - the template for the logout page, defaults to "uaf_logout.tt"

=head1 METHODS

=over 4

=item uaf_is_valid

This method is used to authenticate the current session. The
default authentication behaviour is based on security tokens. A token is 
stored within the session store and a token is retireved from a cookie. If 
the two match, the session is condsidered autheticate. When the session is 
authenticated an User object is returned.

=item uaf_validate

This method handles the validation of the current session. It accepts two 
parameters. They are a username and password. When the session is validated, 
an User object is created and returned. The default validate() method only 
knows about "admin" and "demo" users, with default passwords of "admin" and 
"demo". This method should be overridden to refelect your applications Users 
datastore and validation policy.

=item uaf_invalidate

This method will invalidate the current session. You may wish to override this
method. By default it removes the User object form the session store, removes 
the secuity token from the session store and removes the security cookie.

=item uaf_set_token

This method creates the security token. It is passed the User object. The 
default action is to create a token using parts of the User object and
random data. This token is then stored in the session store and sent to the
browser as a cookie.

=item uaf_avoid

Some application may wish to implement an avoidence scheme for certain
situations. This is a hook to allow that to happen. The default action is
to do nothing.

=item uaf_check_credentials

Check the username and password for validity.

=back

=head1 ACCESSORS

These accessors return the corresponding config items.

=over 4

=item uaf_filter

=item uaf_cookie_path

=item uaf_cookie_domain

=item uaf_cookie_secure

=item uaf_limit

=item uaf_timeout

=item uaf_secret

=item uaf_filter

=item uaf_login_rootp

=item uaf_denied_rootp

=item uaf_login_title

=item uaf_login_wrapper

=item uaf_login_template

=item uaf_denied_title

=item uaf_denied_wrapper

=item uaf_denied_template

=item uaf_logout_title

=item uaf_logout_wrapper

=item uaf_logout_template

=back

=head1 SEE ALSO

 Scaffold
 Scaffold::Base
 Scaffold::Cache
 Scaffold::Cache::FastMmap
 Scaffold::Cache::Manager
 Scaffold::Cache::Memcached
 Scaffold::Class
 Scaffold::Constants
 Scaffold::Engine
 Scaffold::Handler
 Scaffold::Handler::Default
 Scaffold::Handler::Favicon
 Scaffold::Handler::Robots
 Scaffold::Handler::Static
 Scaffold::Lockmgr
 Scaffold::Lockmgr::KeyedMutex
 Scaffold::Lockmgr::UnixMutex
 Scaffold::Plugins
 Scaffold::Render
 Scaffold::Render::Default
 Scaffold::Render::TT
 Scaffold::Routes
 Scaffold::Server
 Scaffold::Session::Manager
 Scaffold::Stash
 Scaffold::Stash::Controller
 Scaffold::Stash::Cookie
 Scaffold::Stash::Manager
 Scaffold::Stash::View
 Scaffold::Uaf::Authenticate
 Scaffold::Uaf::AuthorizeFactory
 Scaffold::Uaf::Authorize
 Scaffold::Uaf::GrantAllRule
 Scaffold::Uaf::Login
 Scaffold::Uaf::Logout
 Scaffold::Uaf::Manager
 Scaffold::Uaf::Rule
 Scaffold::Uaf::User
 Scaffold::Utils

=head1 AUTHOR

Kevin L. Esteb E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
