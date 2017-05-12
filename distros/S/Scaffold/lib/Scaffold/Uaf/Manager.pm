package Scaffold::Uaf::Manager;

our $VERSION = '0.02';

use 5.8.8;
use Try::Tiny;

use Scaffold::Class
  version   => $VERSION,
  base      => 'Scaffold::Plugins',
  constants => ':plugins',
  mixin     => 'Scaffold::Uaf::Authenticate',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub pre_action {
    my ($self, $hobj) = @_;

    $hobj->uaf_init();

    my $user;
    my $attempts;
    my $regex = $hobj->uaf_filter;
    my $uri = $hobj->scaffold->request->uri;
    my $login_rootp = $hobj->uaf_login_rootp;
    my $denied_rootp = $hobj->uaf_denied_rootp;
    my $lock = $hobj->scaffold->session->session_id;

    # authenticate the session, this happens with each access

    if ($uri->path !~ /^$regex/) {

        try {

            if ($hobj->scaffold->lockmgr->lock($lock)) {

                $attempts = $hobj->scaffold->session->get('uaf_login_attempts') || 0;

                if ($attempts < $hobj->uaf_limit) {

                    if ($user = $hobj->uaf_is_valid()) {

                        $hobj->scaffold->user($user);
                        $hobj->scaffold->lockmgr->unlock($lock);

                    } else { 

                        $hobj->scaffold->lockmgr->unlock($lock);
                        $hobj->redirect($login_rootp); 

                    }

                } else {

                    $hobj->scaffold->lockmgr->unlock($lock);
                    $hobj->redirect($denied_rootp); 

                }

            }

        } catch {

            my $ex = $_;

            # capture any exceptions and release any held locks,
            # then punt to the outside exception handler.

            if ($hobj->scaffold->lockmgr->try_lock($lock)) {

                $hobj->scaffold->lockmgr->unlock($lock);

            }

            die $ex;

        };

    }

    return PLUGIN_NEXT;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Uaf::Manager - A plugin to do authentication within the Scaffold framework

=head1 DESCRIPTION

This plugin is automatically loaded when authentication is desired. It 
checks the current session to see if it is authenticatied. If not it will 
redirect back to a "login" url to force authentication or it will redirect to
a "denied" url when login attempts are exceeded.

This plugin understands the following config settings:

 uaf_limit        - The number of login attempts
 uaf_filter       - A reqex of non authenticated urls
 uaf_login_rootp  - The url to redirect to for login processing
 uaf_denied_rootp - The url to redirect to for login denial

=head1 METHODS

=over 4

=item pre_action

Checks to see if the current session is authenticated, redirects as needed.

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

Kevin L. Esteb E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
