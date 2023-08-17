package Slick::CacheExecutor;

use 5.036;

use Moo::Role;
use Types::Standard qw(Str);
use Carp            qw(croak);
use Slick::Util;

has raw => (
    is      => 'ro',
    handles => [qw(get set incr decr)]
);

1;

=encoding utf8

=head1 NAME

Slick::CacheExecutor

=head1 SYNOPSIS

A L<Moo::Role> implemented by all of the caches supported by L<Slick>.

=head1 See also

=over2

=item * L<Slick::DatabaseExecutor>

=item * L<Slick::CacheExecutor::Redis>

=item * L<Slick::CacheExecutor::Memcached>

=item * L<Slick::Context>

=item * L<Slick::Database>

=item * L<Slick::DatabaseExecutor::MySQL>

=item * L<Slick::DatabaseExecutor::Pg>

=item * L<Slick::EventHandler>

=item * L<Slick::Events>

=item * L<Slick::Methods>

=item * L<Slick::RouteMap>

=item * L<Slick::Util>

=back

=cut

