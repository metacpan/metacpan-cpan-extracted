package Scaffold::Cache::FastMmap;

our $VERSION = '0.01';

use 5.8.8;
use Try::Tiny;
use Cache::FastMmap;

use Scaffold::Class
  version => $VERSION,
  base    => 'Scaffold::Cache',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub set {
    my ($self, $key, $value) = @_;

    my $namespace = $self->namespace;
    my $skey = $namespace . ':' . $key;

    return $self->handle->set($skey, $value);

}

sub update {
    my ($self, $key, $value) = @_;

    my $namespace = $self->namespace;
    my $skey = $namespace . ':' . $key;

    return $self->handle->get_and_set($skey, sub { return $value});

}

sub purge {
    my ($self) = @_;

    return $self->handle->purge();

}

sub clear {
    my ($self) = @_;

    return $self->handle->clear();

}

sub incr {
    my ($self, $key) = @_;

    my $namespace = $self->namespace;
    my $skey = $namespace . ':' . $key;

    $self->handle->get_and_set($skey, sub { return ++$_[1] });

}

sub decr {
    my ($self, $key) = @_;

    my $namespace = $self->namespace;
    my $skey = $namespace . ':' . $key;

    $self->handle->get_and_set(
        $skey, 
        sub {
            if ($_[1] > 0) {
                return --$_[1] ;
            } else {
                return 0;
            }
        }
    );

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->{config}    = $config;
    $self->{namespace} = $self->config('namespace');
    $self->{expires}   = $self->config('expires') || '1h';

    my $num_pages  = $self->config('pages') || '256';
    my $page_size  = $self->config('pagesize') || '256k';
    my $share_file = $self->config('filename') || '/tmp/scaffold.cache';

    try {

        $self->{handle} = Cache::FastMmap->new(
            num_pages      => $num_pages,
            page_size      => $page_size,
            expire_time    => $self->expires,
            share_file     => $share_file,
            compress       => 1,
            unlink_on_exit => 0,
        );

    } catch {

        my $ex = $_;

        $self->throw_msg('scaffold.cache.fastmmap', 'noload', $ex);

    };

    return $self;

}

1;

__END__

=head1 NAME

Scaffold::Cache::FastMmap - Caching is based on fastmmap.

=head1 SYNOPSIS

 my $server = Scaffold::Server->new(
     cache => Scaffold::Cache::FastMmap->new(
        namespace => 'scaffold',
        expires   => '1h',
        pages     => 256,
        pagesize  => 256k,
        filename  => '/tmp/scaffold.cache'
    ),
 );

=head1 DESCRIPTION

This module initializes the Cache::FastMmap module and uses it for the caching
engine within Scaffold. The synopsis shows the defaults that are used in 
initialization.

=head1 SEE ALSO

 Cache::FastMmap

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
