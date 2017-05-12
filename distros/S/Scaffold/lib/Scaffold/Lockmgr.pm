package Scaffold::Lockmgr;

our $VERSION = '0.01';

use 5.8.8;
use Scaffold::Class
  version   => $VERSION,
  base      => 'Scaffold::Base',
  accessors => 'engine timeout limit',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub lock {
    my ($self, $key) = @_;

}

sub unlock {
    my ($self, $key) = @_;

}

sub try_lock {
    my ($self, $key) = @_;

}

sub allocate {
    my ($self, $key) = @_;
    
}

sub deallocate {
    my ($self, $key) = @_;
      

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Lockmgr - The base class for locking within Scaffold

=head1 SYNOPSIS

 if ($self->scaffold->lockmgr->try_lock($lock)) {

    if ($self->scaffold->lockmgr->lock($lock)) {

        ....

        $self->scaffold->lockmgr->unlock($lock);

    }

 }

=head1 DESCRIPTION

This module provides a general purpose locking mechanism to protect shared 
resources. It is rather interesting to ask a developer how they protect 
session data and/or global shared data. They usually answer, "I use 
such-and-such session module, and what do you mean by "global shared data" ?". 
Well, for those who understand the need for resource locking, this module 
provides it for Scaffold.

=head1 METHODS

=over 4

=item allocate

 $self->scaffold->lockmgr->allocate($lock);

Reserve a lock by this name. This needs to be done before a lock is used.
This name can be used when trying to lock and unlock resources.

=item deallocate

 $self->scaffold->lockmgr->deallocate($lock);

Removes the reservation for the name. This frees up a lock that can be 
subseqently reused.

=item lock

Aquires a lock on a resource, return true if successful.

 $self->scaffold->lockmgr->lock($lock);

=item unlock

Releases the lock on a resource.

 $self->scaffold->lockmgr->unlock($lock);

=item try_lock

Tests to see if the lock on a resource is available, returns true if the lock
is available.

 $self->scaffold->lockmgr->try_lock($lock);

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
