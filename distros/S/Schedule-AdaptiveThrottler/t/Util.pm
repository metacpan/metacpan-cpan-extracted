use strict;
use warnings;

sub get_test_memcached_client {
    my ( $msg, $memcached_class, $memcached_client );

    if ( $ENV{MEMCACHED_SERVERS} ) {
        $msg
            = !( $memcached_class
            = eval  { require Cache::Memcached::Fast; 'Cache::Memcached::Fast'; }
            || eval { require 'Cache::Memcached';     "Cache::Memcached"; } )
            && "Could not load a Memcached class";

        $msg ||= !defined $ENV{MEMCACHED_SERVERS}
            && "\$MEMCACHED_SERVERS environment variable needed";

        $msg
            ||= !( $memcached_client
            = $memcached_class->new( { 'servers' => [ split q(,), $ENV{MEMCACHED_SERVERS} ] } )
            ) && "Could not create memcached client";
        return ( $memcached_client, $msg );
    }

    # handier
    return Cache::MockMemcached->new();
}

package Cache::MockMemcached;

sub new {
    my $class = shift;
    my $self = bless { db => {} }, $class;
    return $self;
}

sub get {
    my $self = shift;
    my ($key) = @_;
    die "Undef key" if !defined $key;
    my $value = $self->{db}{$key} or return;
    $value = $value;
    if ( $value->[1] < time ) {
        delete $self->{db}{$key};
        return;
    }
    return $value->[0];
}

sub set {
    my $self = shift;
    my ( $key, $value, $ttl ) = @_;
    $ttl ||= 0;
    die "Undef key or value\n" if !defined $key || !defined $value;
    $self->{db}{$key} = [ $value, $ttl > 0 ? time + $ttl : time + 999_999_999 ];
    return 1;
}

1;
