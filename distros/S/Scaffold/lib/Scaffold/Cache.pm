package Scaffold::Cache;

our $VERSION = '0.01';

use 5.8.8;
use Scaffold::Class
  version  => $VERSION,
  base     => 'Scaffold::Base',
  mutators => 'handle namespace expires',
  constant => 'TRUE FALSE',
  messages => {
      'noload' => 'unable to load module; reason: %s',
  },
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub get {
    my ($self, $key) = @_;

    my $namespace = $self->namespace;
    my $skey = $namespace . ':' . $key;

    return $self->handle->get($skey);

}

sub delete {
    my ($self, $key) = @_;

    my $namespace = $self->namespace;
    my $skey = $namespace . ':' . $key;

    return $self->handle->remove($skey);

}

sub update {
    my ($self, $key, $value) = @_;

}

sub clear {
    my ($self) = @_;

}

sub purge {
    my ($self) = @_;

}

sub incr {
    my ($self, $key) = @_;

}

sub decr {
    my ($self, $key) = @_;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Cache - The base class for Caching in Scaffold

=head1 SYNOPSIS

 my $server = Scaffold::Server->new(
     cache => Scaffold::Cache::FastMmap->new(
        namespace => 'scaffold',
    ),
 );

=head1 DESCRIPTION

Scaffold provides two caching engines, they are L<Scaffold::Cache::FastMmap|Scaffold::Cache::FastMmap>
and L<Scaffold::Cache::Memcached|Scaffold::Cache::Memcached>. This module
defines the stanadard api that the engines need to implement. 

L<Scaffold::Cache::Manager|Scaffold::Cache::Manager> is used to maintain the
caching subsystem. It is implemented as a plugin. 

Since the cache can be shared between multiple processes, a "name space" 
is defined to help differate between those processes cache usage. By default 
this is "scaffold". It can be changed at any time with the namespace() 
method or upon initialization of the engine.

When Scaffold initializes itself, it looks for the "cache" config stanzia. 
If one is defined than that is used for the caching engine, otherwise it
will use Scaffold::Cache::FastMmap.

=head1 METHODS

=over 4

=item get(key)

This method will retrieve the "value" associated with "key".

 $value = $self->scaffold->cache->get('junk');

=item set(key, value)

This method will store the "value" associated with "key".

 $self->scaffold->cache->set('junk', $value);

=item delete(key)

This method will delete the "key" from the caching system.

 $self->scaffold->cache->delete('junk');

=item update(key, value)

This method will update the "value" associated with "key". Most of the 
caching systems do this in a "atomic" fashion.

 $self->scaffold->cache->update('junk', $newvalue);

=item clear()

This method will clear all items from the cache. Use with care.

 $self->scaffold->cache->clear();

=item purge()

This method will purge expired items out of the cache. 

 $self->scaffold->cache->purge();

=item namespace(name)

This method will get/set the current namespace for cache operations.

 $namespace = $self->scaffold->cache->namespace;
 $self->scaffold->cache->namespace($namespace);

=back

=head1 SEE ALSO

 Cache::FastMmap
 Cache::Memcached

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
