package Plack::Middleware::Throttle::Lite::Backend::Memcached;

# ABSTRACT: Memcache-driven storage backend for Throttle-Lite

use strict;
use warnings;
use Carp ();
use parent 'Plack::Middleware::Throttle::Lite::Backend::Abstract';
use Cache::Memcached::Fast;

our $VERSION = '0.03'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

__PACKAGE__->mk_attrs(qw(mc));

sub init {
    my ($self, $args) = @_;

    my $_handle = Cache::Memcached::Fast->new($args);
    Carp::croak("Cannot get memcached handle") unless keys %{ $_handle->server_versions };

    $self->mc($_handle);
}

sub increment {
    my ($self) = @_;

    $self->mc->set($self->cache_key, 1 + $self->reqs_done, 1 + $self->expire_in);
}

sub reqs_done {
    my ($self) = @_;

    $self->mc->get($self->cache_key) || 0;
}

1; # End of Plack::Middleware::Throttle::Lite::Backend::Memcached

__END__

=pod

=head1 NAME

Plack::Middleware::Throttle::Lite::Backend::Memcached - Memcache-driven storage backend for Throttle-Lite

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This is implemetation of the storage backend for B<Plack::Middleware::Throttle::Lite>. It uses memcache-server
to hold throttling data, automatically sets expiration time for stored keys to save memory consumption.

=head1 SYNOPSYS

    # inside your app.psgi
    enable 'Throttle::Lite',
        backend => [
            'Memcached' => {
                servers => [
                    'mc1.example.com:11211',
                    'mc1.example.com:11212',
                    'mc2.example.net:11210',
                ],
            }
        ];

=head1 OPTIONS

There are no backend-specific options. All options directly passing to downstream interface to memcached server.
At the moment this is B<Cache::Memcached::Fast>. See L<Cache::Memcached::Fast> for available configuration options.

=head1 METHODS

=head2 mc

Returns a memcached connection handle.

=head2 init

See L<Plack::Middleware::Throttle::Lite::Backend::Abstract/"ABSTRACT METHODS">

=head2 reqs_done

See L<Plack::Middleware::Throttle::Lite::Backend::Abstract/"ABSTRACT METHODS">

=head2 increment

See L<Plack::Middleware::Throttle::Lite::Backend::Abstract/"ABSTRACT METHODS">

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Plack-Middleware-Throttle-Lite-Backend-Memcached/issues>

=head1 SEE ALSO

L<Cache::Memcached::Fast>

L<Plack::Middleware::Throttle::Lite>

L<Plack::Middleware::Throttle::Lite::Backend::Abstract>

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
