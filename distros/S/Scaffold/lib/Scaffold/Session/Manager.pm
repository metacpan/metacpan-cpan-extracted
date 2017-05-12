package Scaffold::Session::Manager;

our $VERSION = '0.01';

use 5.8.8;
use HTTP::Session;
use HTTP::Session::State::Cookie;
use Scaffold::Session::Store::Cache;

use Scaffold::Class
  version   => $VERSION,
  base      => 'Scaffold::Plugins',
  constants => 'SESSION_ID :plugins',
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub pre_action {
    my ($self, $hobj) = @_;

    my $user;
    my $address;
    my $create;
    my $access;

    my $session = HTTP::Session->new(
        store => Scaffold::Session::Store::Cache->new(
            cache => $hobj->scaffold->cache,
        ),
        state => HTTP::Session::State::Cookie->new(
            name => SESSION_ID
        ),
        request => $hobj->scaffold->request
    );

    $user    = $session->get('user');
    $address = $session->get('address');
    $create  = $session->get('create');
    $access  = $session->get('access');

    if (not $user) {

        $user = defined($hobj->scaffold->request->user) ? 
          $hobj->scaffold->request->user : 'guest';

    }

    $session->set('user', $user);
    $session->set('address', $hobj->scaffold->request->address) if (not $address);
    $session->set('create', time()) if (not $create);
    $session->set('access', time()) if (not $access);

    $hobj->scaffold->session($session);
    $hobj->scaffold->lockmgr->allocate($session->session_id);

    return PLUGIN_NEXT;

}

sub pre_exit {
    my ($self, $hobj) = @_;

    my $session  = $hobj->scaffold->session;
    my $lockmgr  = $hobj->scaffold->lockmgr;
    my $response = $hobj->scaffold->response;

    $session->set('access', time());

    if (defined($session->session_id)) {

        $lockmgr->deallocate($session->session_id);

    }

    $session->response_filter($response);
    $session->finalize();          # must be the last thing done!!

    return PLUGIN_NEXT;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Session::Manager - The class for Sessions in Scaffold

=head1 SYNOPSIS

The module initializes a "session". It automatically stores the username 
from the browser, the browsers address, the time the session was initially 
created and the last access time.

=head1 DESCRIPTION

All access to Scaffold applications have an associated session. The session 
uses the caching mechanism to store the session context. There is no
default locking to control access to this context, but it does allocate
a lock within the Lock Manager in case this is neccessary. Any resource 
locking must be done using the Lock Manager. Session meta data is stored in 
temporary cookies.

=head1 ACCESSORS

=over 4

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

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
