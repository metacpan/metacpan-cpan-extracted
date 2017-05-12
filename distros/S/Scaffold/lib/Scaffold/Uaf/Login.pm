package Scaffold::Uaf::Login;

our $VERSION = '0.01';

use 5.8.8;
use DateTime;
use Try::Tiny;
use Digest::MD5;
use Digest::HMAC;

use Scaffold::Class
  version => $VERSION,
  base    => 'Scaffold::Handler',
  mixin   => 'Scaffold::Uaf::Authenticate',
;

use Data::Dumper;

# -----------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------

sub do_main {
    my ($self) = @_;

    my $title;
    my $wrapper;
    my $template;
    my $attempts;
    my $lock = $self->scaffold->session->session_id;

    $self->uaf_init();

    $title = $self->uaf_login_title;
    $wrapper = $self->uaf_login_wrapper;
    $template = $self->uaf_login_template;

    if ($self->scaffold->lockmgr->lock($lock)) {

        $attempts = $self->scaffold->session->get('uaf_login_attempts') || 0;

        if ($attempts > $self->uaf_limit) {

            $title = $self->uaf_denied_title;
            $wrapper = $self->uaf_denied_wrapper;
            $template = $self->uaf_denied_template;

        }

        $self->scaffold->lockmgr->unlock($lock);

    }

    $self->stash->view->title($title);
    $self->stash->view->template($template);
    $self->stash->view->template_wrapper($wrapper);

}

sub do_denied {
    my ($self) = @_;

    $self->uaf_init();

    my $title = $self->uaf_denied_title;
    my $wrapper = $self->uaf_denied_wrapper;
    my $template = $self->uaf_denied_template;

    $self->stash->view->title($title);
    $self->stash->view->template($template);
    $self->stash->view->template_wrapper($wrapper);

}

sub do_validate {
    my ($self) = @_;

    $self->uaf_init();

    my $url;
    my $count;
    my $user = undef;
    my $login_rootp = $self->uaf_login_rootp;
    my $denied_rootp = $self->uaf_denied_rootp;
    my $lock = $self->scaffold->session->session_id;
    my $params = $self->scaffold->request->parameters->as_hashref();
    my $app_rootp = $self->scaffold->config('configs')->{app_rootp};

    $url = $login_rootp;

    try {

        if ($self->scaffold->lockmgr->lock($lock)) {

            $count = $self->scaffold->session->get('uaf_login_attempts');
            $count++;

            $self->scaffold->session->set('uaf_login_attempts', $count);

            $user = $self->uaf_validate($params->{username}, $params->{password});

            if (defined($user)) {

                $self->scaffold->session->set('uaf_user', $user);

                if ($count < $self->uaf_limit) {

                    $self->scaffold->session->set('uaf_login_attempts', 0);
                    $self->uaf_set_token($user);
                    $url = $app_rootp;

                } else {

                    $url = $denied_rootp;

                }

            } else {

                $url = ($count < $self->uaf_limit) ? $login_rootp : $denied_rootp;

            }

            $self->scaffold->lockmgr->unlock($lock);

        }

        $self->redirect($url);

    } catch {

        my $ex = $_;

        # capture any exceptions and release any held locks,
        # then punt to the outside exception handler.

        if ($self->scaffold->lockmgr->try_lock($lock)) {

            $self->scaffold->lockmgr->unlock($lock);

        }

        die $ex;

    };

}

# -----------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------

1;

=head1 NAME

Scaffold::Uaf::Login - A handler for the /login url.

=head1 DESCRIPTION

This handler handles the url "/login" and any actions on that url. By default
this method display a simple login page which contains a login form. That form 
is submitted back to the "/login/validate" url, where the username and 
password are processed. This processing is done by the uaf_validate() method. 
If validation is succesful an User object is created. This object is then 
stored within the session store so uaf_is_valid() can access it when doing  
authentication. Also an initial security token is created. 

This method also implements a simple three tries at login attempts. If after 
three tries, all attempts are redirected to "/login/denied", which displays 
a simple "denied" page. After a succesful login, a redirect is sent for root 
of the application.

=head1 METHODS

=over 4

=item do_main

Displays a login page based on the following config items:

 uaf_login_title
 uaf_login_template
 uaf_login_wrapper

=item do_denied

Displays a denied page based on the following config items:

 uaf_denied_title
 uaf_login_template
 uaf_login_wrapper

=item do_validate

Performs the authentication depending on the username and password
parameters. If the authentication is valid, it will create a User object that
is stored in $self->scaffold->user and creates a security token that is passed
with the session cookies.

=back

=head1 DEPENDENICES

 Scaffold::Uaf::Authenticate

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

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
