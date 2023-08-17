package Slick::CacheExecutor::Redis;

use Moo;
use Redis;
use Carp qw(croak);

with 'Slick::CacheExecutor';

sub BUILD {
    my ( $self, $args ) = @_;

    croak qq{No arguments provided for Redis.}
      unless $args;

    $self->{raw} = Redis->new( $args->%* );

    return $self;
}

1;
