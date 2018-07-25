package MockRedis;

use strict;
use warnings;

our %storage;

sub new {
    my $self = bless {}, shift;

    @MockRedis::ISA = ( 'Redis::Fast' );

    return $self;
}

sub get{
    my ( $self, $key ) = @_;
    return exists $storage{$key} ? $storage{$key} : undef;
}

sub set {
    my ( $self, $key, $value ) = @_;

    $storage{$key} = $value;

    return 'OK';
}

sub del {
    my ( $self, $key ) = @_;

    my $found = delete $storage{$key};

    return $found ? 1 : 0;
}

sub exists {
    my ( $self, $key ) = @_;

    return exists $storage{$key} ? 1 : 0;
}

1;