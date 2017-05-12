package Scaffold::Uaf::AuthorizeFactory;

use 5.8.8;
use Scaffold::Uaf::GrantAllRule;

use Scaffold::Class
  version => '0.01',
  base    => 'Scaffold::Uaf::Authorize'
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub rules {
    my $self = shift;

    $self->add_rule(Scaffold::Uaf::GrantAllRule->new());

}

1;

__END__
  
=head1 NAME

Scaffold::Uaf::AuthorizeFactory - A default authorization module.

=head1 DESCRIPTION

Scaffold::Uaf::AuthorizeFactory is a pre-built module that uses 
Scaffold::Uaf::GrantAllRule to implement an authorization scheme. It
is a good idea to replace this module with something better.

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
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
