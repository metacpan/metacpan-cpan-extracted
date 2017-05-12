package Scaffold::Uaf::Rule;

our $VERSION = '0.01';

use 5.8.8;
use Scaffold::Class
  version => $VERSION,
  base    => 'Scaffold::Base'
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub grants {
   my ($self, $user, $action, $resource) = @_;

   return 0;

}

sub denies {
   my ($self, $user, $action, $resource) = @_;

   # Abstract rule denies everything. Do not use.

   return 1;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Uaf::Rule - A base class for rules.

=head1 DESCRIPTION

Each rule is a custom-written class that implements some aspect of your site's
authorization logic. Rules can choose to grant or deny a request. 

 package Sample::Test;

 use strict;
 use warnings;

 use Scaffold::Class
     version => '0.01',
     base    => 'Scaffold::Uaf::Rule
 ;

 sub grants {
     my ($self, $user, $action, $resource) @_;

     if ($action eq "edit" && $resource->isa("sample::Record")) {

        return 1 if ($user->username eq "root");

     }

     return 0;

 }

 sub denies {
     my ($self, $user, $action, $resource) @_;

     return 0;
 
 }

 1;

The Authorize object will only give permission if I<at least> one rule grants
permission, I<and no> rule denies it. 

It is important that your rules never grant or deny a request they do not
understand, so it is a good idea to use type checking to prevent strangeness.
B<Assertions should not be used> if you expect different rules to accept
different resource types or user types, since each rule is used on every access
request.

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
 Scaffole::Routes
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

Kevin L. Esteb E<lt>kevin@kesteb.usE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
