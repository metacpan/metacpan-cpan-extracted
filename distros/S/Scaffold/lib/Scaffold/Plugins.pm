package Scaffold::Plugins;

our $VERSION = '0.01';

use 5.8.8;
use Scaffold::Class
  version   => $VERSION,
  base      => 'Scaffold::Base',
  constants => ':plugins'
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub pre_action {
    my ($self, $hobj) = @_;

    return PLUGIN_NEXT;

}

sub post_action {
    my ($self, $hobj) = @_;

    return PLUGIN_NEXT;

}

sub pre_render {
    my ($self, $hobj) = @_;

    return PLUGIN_NEXT;

}

sub post_render {
    my ($self, $hobj) = @_;

    return PLUGIN_NEXT;

}

sub pre_exit {
    my ($self, $hobj) = @_;

    return PLUGIN_NEXT;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Plugins - The base class for Scaffold plugins

=head1 SYNOPSIS

 use Scaffold::Server;

 my $server = Scaffold::Server->new(
    plugins => [
       'App::Plugin1',
       'App::Plugin2',
    ],
 );

=head1 DESCRIPTION

The base class for Plugin within Scaffold. This class should be inherited and
extended to develop your own plugins.

=head1 METHODS

=over 4

=item pre_action

=item post_action

=item pre_render

=item post_render

=item pre_exit

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
