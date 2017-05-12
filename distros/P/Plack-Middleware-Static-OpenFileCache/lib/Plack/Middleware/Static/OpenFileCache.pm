package Plack::Middleware::Static::OpenFileCache;

use 5.008005;
use strict;
use warnings;
use parent qw/Plack::Middleware::Static/;
use Plack::Util::Accessor qw(max expires buf_size cache_errors);
use Cache::LRU::WithExpires;

our $VERSION = "0.02";

sub prepare_app {
    my $self = shift;
    my $max = $self->max;
    $max = 100 unless defined $max;
    $self->expires(60) unless defined $self->expires;
    $self->buf_size(8192) unless defined $self->buf_size;
    $self->{_cache_lru} = Cache::LRU::WithExpires->new(size => $max);
}

sub _handle_static {
    my($self, $env) = @_;
    my $path = $env->{PATH_INFO};
    my $cache = $self->{_cache_lru};
    my $res = $cache->get($path);
    if ( $res ) {
        if ( ref $res->[2] ne 'ARRAY' ) {
            seek($res->[2],0,0);
        }
        return $res;
    }
    $res = $self->SUPER::_handle_static($env);
    return unless defined $res;
    if ( ref $res->[2] ne 'ARRAY' ) {
        my $len = Plack::Util::header_get($res->[1], 'Content-Length');
        if ( $self->{buf_size} && $len && $len < $self->{buf_size} ) {
            local $/ = 65536;
            my $buf = $res->[2]->getline;
            $res->[2] = [$buf];
        }
        else {
            my $io_path = $res->[2]->path;
            bless $res->[2], 'Plack::Middleware::Static::OpenFileCache::IOWithPath';
            $res->[2]->path($io_path);
        }
    }
    if ( $res->[0] =~ m!^2! or $self->cache_errors ) {
        $cache->set($path, $res, $self->expires);
    }
    $res;
}

package Plack::Middleware::Static::OpenFileCache::IOWithPath;
use parent qw(IO::Handle);

sub path {
    my $self = shift;
    if (@_) {
        ${*$self}{+__PACKAGE__} = shift;
    }
    ${*$self}{+__PACKAGE__};
}

sub close {}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Static::OpenFileCache - Plack::Middleware::Static with open file cache

=head1 SYNOPSIS

    use Plack::Middleware::Static::OpenFileCache;

    builder {
        enable "Plack::Middleware::Static",
            path => qr{^/(images|js|css)/},
            root => './htdocs/',
            max  => 100,
            expires => 60,
            buf_size => 8192,
            cache_errors => 1;
        $app;
    };

=head1 DESCRIPTION

Plack::Middleware::Static::OpenFileCache enables Plack::Middleware::Static 
to cache open file like nginx. This middleware cache opened file handles and their
sizes and modification times for faster contents serving. 

=head1 CONFIGURATIONS

=over 4

=item max

Maximum number of items in cache. If cache is overflowed, items are removed by LRU.
(100 by default)

=item expires

Expires seconds. 60 by default

=item buf_size

If content size of static file is smaller than buf_size. 
Plack::Middleware::Static::OpenFileCache reads all to memory. 8192 byte by default.

=item cache_errors

If enabled, this middleware cache response if status is 40x. Disabled by default.

=back

=head1 BENCHMARK

benchmark with ApacheBench and L<Monoceros>

=over 4

=item benchmark on larger file

  Document Path:          /static/jquery-1.10.2.min.js
  Document Length:        93107 bytes
  
  Static                Requests per second:    1219.47 [#/sec] (mean)
  Static::OpenFileCache Requests per second:    1483.52 [#/sec] (mean)

=item benchmark on small file

  Document Path:          /static/cpanfile
  Document Length:        160 bytes
  
  Static                 Requests per second:    2018.13 [#/sec] (mean)
  Static::OpenFileCache  Requests per second:    2813.08 [#/sec] (mean)

=back

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

