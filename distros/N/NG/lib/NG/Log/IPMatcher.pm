package Log::IPMatcher;

# Author: newestbie
# E-mail: newestbie@gmail.com
# File: IPMatcher.pm
# Date: 2012/7/14

use strict;
use warnings;
use Socket;

my @tree;
my @byte_table;
my @mask_table;
my $instance;

sub init {
    my $class = shift(@_);
    my ($ip_set) = @_;

    $instance = {};
    bless( $instance, $class );

    $instance->build_table();
    $instance->build_tree($ip_set);
}

sub get_instance {
    my $class = shift(@_);
    return $instance;
}

sub calc_network {
    my $self = shift(@_);

    #my ($ip, $mask_bit) = @_;

    return inet_ntoa(
        pack( "N", unpack( "N", inet_aton( $_[0] ) ) & $mask_table[ $_[1] ] ) );
}

sub build_table {
    my $self = shift(@_);
    @byte_table = ();
    @mask_table = ();

    my @masks = (
        0b11111111,
        0b11111110,
        0b11111100,
        0b11111000,
        0b11110000,
        0b11100000,
        0b11000000,
        0b10000000,

        #0b00000000,
    );

    foreach my $byte ( 0 .. 255 ) {
        my %hash;
        foreach my $mask (@masks) {
            my $n = $byte & $mask;
            $hash{$n} = 1 if ( not exists $hash{$n} );
        }

        $byte_table[$byte] = [ sort { $b <=> $a } keys(%hash) ];
    }

    foreach my $mask_bit ( 0 .. 32 ) {
        my $mask = 0;
        for ( my $n = 1 ; $n <= $mask_bit ; $n++ ) {
            $mask += 2**( 32 - $n );
        }

        $mask_table[$mask_bit] = $mask;
    }
}

sub build_tree {
    my $self = shift(@_);
    my ($ip_set) = @_;
    @tree = ();

    foreach my $area ( keys(%$ip_set) ) {
        foreach my $ip_mask ( @{ $ip_set->{$area} } ) {
            my ( $ip, $mask_bit ) = split( m{/}, $ip_mask );
            my $network = $self->calc_network( $ip, $mask_bit );
            my @fields = split( /\./, $network );
            $tree[ $fields[0] ][ $fields[1] ][ $fields[2] ][ $fields[3] ] =
              [ $area, $network, $mask_bit ];
        }
    }
}

sub lookup {
    my $self = shift(@_);
    my ($ip) = @_;
    my $area;

    my @fields = split( /\./, $ip );
    foreach my $n ( @{ $byte_table[ $fields[3] ] } ) {
        if ( defined $tree[ $fields[0] ][ $fields[1] ][ $fields[2] ][$n] ) {
            my ( $a, $network, $mask_bit ) =
              @{ $tree[ $fields[0] ][ $fields[1] ][ $fields[2] ][$n] };
            if ( $self->calc_network( $ip, $mask_bit ) eq $network ) {
                $area = $a;

                return $area;
            }
        }
    }

    foreach my $n ( @{ $byte_table[ $fields[2] ] } ) {
        if ( defined $tree[ $fields[0] ][ $fields[1] ][$n][0] ) {
            my ( $a, $network, $mask_bit ) =
              @{ $tree[ $fields[0] ][ $fields[1] ][$n][0] };
            if ( $self->calc_network( $ip, $mask_bit ) eq $network ) {
                $area = $a;

                return $area;
            }
        }
    }

    foreach my $n ( @{ $byte_table[ $fields[1] ] } ) {
        if ( defined $tree[ $fields[0] ][$n][0][0] ) {
            my ( $a, $network, $mask_bit ) = @{ $tree[ $fields[0] ][$n][0][0] };
            if ( $self->calc_network( $ip, $mask_bit ) eq $network ) {
                $area = $a;

                return $area;
            }
        }
    }

    foreach my $n ( @{ $byte_table[ $fields[0] ] } ) {
        if ( defined $tree[$n][0][0][0] ) {
            my ( $a, $network, $mask_bit ) = @{ $tree[$n][0][0][0] };
            if ( $self->calc_network( $ip, $mask_bit ) eq $network ) {
                $area = $a;

                return $area;
            }
        }
    }

    if ( defined $tree[0][0][0][0] ) {
        my ( $a, undef, $mask_bit ) = @{ $tree[0][0][0][0] };
        if ( $mask_bit == 0 ) {
            $area = $a;

            return $area;
        }
    }

    return $area;
}

1;
