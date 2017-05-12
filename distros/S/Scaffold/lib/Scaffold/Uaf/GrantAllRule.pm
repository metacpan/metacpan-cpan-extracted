package Scaffold::Uaf::GrantAllRule;

use 5.8.8;

use Scaffold::Class
  version => '0.01',
  base    => 'Scaffold::Uaf::Rule'
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub grants {
   my ($self, $user, $action, $resource) = @_;

   # Default is to allow everything

   return 1;

}

sub denies {
   my ($self, $user, $action, $resource) = @_;

   # Default is to deny everything

   return 0;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Uaf::GrantAllRule - A rule that grants permission to do everything.

=head1 DESCRIPTION

Scaffold::Uaf::GrantAllRule is a pre-built rule that grants access for
all permission requests. This rule can be used to help implement a system that
has a default policy of allowing access, and to which you add rules that deny
access for specific cases.

Note that the loose type checking of Perl makes this inherently dangerous, 
since a typo is likely to fail to deny access. It is recommended that you
take the opposite approach with your rules, since a typo will err on the 
side of denying access. The former is a security hole, the latter is a bug
that people will complain about (so you can fix it).

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
 Scaffold::Handler::Handler
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
