package Scaffold::Cache::Memcached;

our $VERSION = '0.01';

use 5.8.8;
use Try::Tiny;
use Cache::Memcached;

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
    my $expires = $self->expires;
    my $skey = $namespace . ':' . $key;

    return $self->handle->set($skey, $value, $expires);

}

sub update {
    my ($self, $key, $value) = @_;

    my $namespace = $self->namespace;
    my $skey = $namespace . ':' . $key;

    return $self->handle->replace($skey, $value);

}

sub clear {
    my ($self) = @_;

    return $self->handle->flush_all();

}

sub incr {
    my ($self, $key) = @_;

    my $namespace = $self->namespace;
    my $skey = $namespace . ':' . $key;

    return $self->handle->incr($skey);

}

sub decr {
    my ($self, $key) = @_;

    my $namespace = $self->namespace;
    my $skey = $namespace . ':' . $key;

    return $self->handle->decr($skey);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->{config}    = $config;
    $self->{namespace} = $self->config('namespace');
    $self->{expires}   = $self->config('expires') || '3600';

    my $rehash   = $self->config('rehash') || 'no';
    my $servers  = $self->config('servers') || '127.0.0.1:11211';
    my $compress = $self->config('compress_threshold') || '1000';

    try {

        $self->{handle} = Cache::Memcached->new({servers => [$servers]});
        $self->{handle}->set_compress_threshold($compress);
        $self->{handle}->enable_compress(1);
        $self->{handle}->set_norehash() if ($rehash =~ m/no/i);

    } catch {

        my $ex = $_;

        $self->throw_msg('scaffold.cache.memcached', 'noload', $ex);

    };
    
    return $self;

}

1;

__END__

=head1 NAME

Scaffold::Cache::Memcached - Caching is based on memcached.

=head1 SYNOPSIS

 my $server = Scaffold::Server->new(
     cache => Scaffold::Cache::Memcached->new(
        namespace => 'scaffold',
        expires   => '1h',
        rehash    => 'no',
        servers   => '127.0.0.1:11211',
        compress_threshold => '1000',
    ),
 );

=head1 DESCRIPTION

This module initializes the Cache::Memcached module and uses it for the caching
subsystem within Scaffold. The synopsis shows the defaults that are used in 
initialization. The "servers" configuration item can be a comma seperated list.

=head1 SEE ALSO

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
