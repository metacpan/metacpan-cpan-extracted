package Scaffold::Session::Store::Cache;

our $VERSION = '0.01';

use 5.8.8;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_ro_accessors(qw/cache expires/);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub new {
    my $class = shift;
    my %args = ref($_[0]) ? %{$_[0]} : @_;

    # check required parameters

    for (qw/cache/) {

        Carp::croak "missing parameter $_" unless $args{$_};

    }

    unless (ref $args{cache} && index(ref($args{cache}), 'Cache') >= 0) {

        Carp::croak "cache requires instance of Scaffold::Cache::Memcached or Scaffold::Cache::FastMmap";

    }

    bless {%args}, $class;

}

sub select {
    my ($self, $session_id) = @_;

    my $data;

    $data = $self->cache->get($session_id);

    return $data;

}

sub insert {
    my ($self, $session_id, $data) = @_;

    $self->cache->set($session_id, $data);

}

sub update {
    my ($self, $session_id, $data) = @_;

    $self->cache->update($session_id, $data);

}

sub delete {
    my ($self, $session_id) = @_;

    $self->cache->delete($session_id);

}

sub cleanup { Carp::croak "This storage doesn't support cleanup" }

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Session::Store::Cache - Use Scaffold's internal caching 

=head1 DESCRIPTION

The module provides an interface from HTTP::Session to Scaffolds internal 
caching system.

=head1 SEE ALSO

 HTTP::Session

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
