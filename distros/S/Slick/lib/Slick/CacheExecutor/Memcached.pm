package Slick::CacheExecutor::Memcached;

use Moo;
use Cache::Memcached;
use Carp qw(croak);

with 'Slick::CacheExecutor';

sub BUILD {
    my ( $self, $args ) = @_;

    croak qq{No arguments provided for Memcached.}
      unless $args;

    $self->{raw} = Cache::Memcached->new($args);

    return $self;
}

1;
