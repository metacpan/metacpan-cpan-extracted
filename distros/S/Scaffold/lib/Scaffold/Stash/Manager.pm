package Scaffold::Stash::Manager;

our $VERSION = '0.01';

use 5.8.8;
use Scaffold::Class
  version   => $VERSION,
  base      => 'Scaffold::Plugins',
  constants => ':plugins SESSION_ID',
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub pre_exit {
    my ($self, $hobj) = @_;

    my @cookies = $hobj->stash->cookies->get();

    foreach my $key (@cookies) {

        next if ($key eq SESSION_ID); # handled by Session/Manager

        my $cookie = $hobj->stash->cookies->get($key);

        my $values = {
            value => $cookie->value,
            path  => $cookie->path,
        };

        if ($cookie->secure) {

            $values->{secure} = $cookie->secure;

        }

        if ($cookie->httponly) {

            $values->{httponly} = $cookie->httponly;

        }

        if ($cookie->domain) {

            $values->{domain} = $cookie->domain;

        }

        if ($cookie->expires) {

            $values->{expires} = $cookie->expires;

        }

        $hobj->scaffold->response->cookies->{$cookie->name} = $values;

    }
      
    return PLUGIN_NEXT;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Stash::Manager - A plugin to manage cookies

=head1 DESCRIPTION

This plugin places the stashed cookies into the response header.

=head1 METHODS

=over 4

=item pre_exit

Places the stashed cookies into the respone header.

=back

=head1 DEPENDENICES

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
