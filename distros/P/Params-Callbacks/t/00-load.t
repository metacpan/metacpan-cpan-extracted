# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Params-Callbacks.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 33;

BEGIN { use_ok( 'Params::Callbacks', ':all' ) }

sub group1a
{
    my ( $callbacks, @params ) = Params::Callbacks->new( @_ );
    is( ref $callbacks, 'Params::Callbacks' );
    is( @$callbacks,    1 );
    is( @params,        0 );
}

group1a( callback {'in callback'} );

sub group3a
{
    my ( $callbacks, @params ) = Params::Callbacks->new( @_ );
    is( ref $callbacks, 'Params::Callbacks' );
    is( @$callbacks,    2 );
    is( @params,        0 );
}

group3a( callback {'in callback'} callback {'in another callback'} );

sub group5a
{
    my ( $callbacks, @params ) = Params::Callbacks->new( @_ );
    is( ref $callbacks, 'Params::Callbacks' );
    is( @$callbacks,    1 );
    is( @params,        3 );
}

group5a( 1, 2, 3, callback {'in callback'} );

sub group7a
{
    my ( $callbacks, @params ) = Params::Callbacks->new( @_ );
    is( ref $callbacks, 'Params::Callbacks' );
    is( @$callbacks,    2 );
    is( @params,        3 );
}

group7a( 1, 2, 3, callback {'in callback'} callback {'in callback'} );

sub group1b
{
    my ( $callbacks, @params ) = &callbacks;
    is( ref $callbacks, 'Params::Callbacks' );
    is( @$callbacks,    1 );
    is( @params,        0 );
}

group1b( callback {'in callback'} );

sub group3b
{
    my ( $callbacks, @params ) = &callbacks;
    is( ref $callbacks, 'Params::Callbacks' );
    is( @$callbacks,    2 );
    is( @params,        0 );
}

group3b( callback {'in callback'} callback {'in another callback'} );

sub group5b
{
    my ( $callbacks, @params ) = &callbacks;
    is( ref $callbacks, 'Params::Callbacks' );
    is( @$callbacks,    1 );
    is( @params,        3 );
}

group5b( 1, 2, 3, callback {'in callback'} );

sub group7b
{
    my ( $callbacks, @params ) = &callbacks;
    is( ref $callbacks, 'Params::Callbacks' );
    is( @$callbacks,    2 );
    is( @params,        3 );
}

group7b( 1, 2, 3, callback {'in callback'} callback {'in callback'} );

sub group8c
{
    my ( $callbacks, @params ) = &callbacks;
    return $callbacks->transform( @params );
}

my @list_out = group8c( 1, 2, 3, callback { $_ * 2 } );
is_deeply( \@list_out, [ 2, 4, 6 ] );

sub group8d
{
    my ( $callbacks, @params ) = &callbacks;
    return $callbacks->transform( @params );
}

my ( $out_1 ) = group8d( 10, callback { $_ * 2 } );
is( $out_1, 20 );

my ( $out_2 ) = group8d( 10 );
is( $out_2, 10 );

my $cb;

sub group8e
{
    my ( $callbacks, @params ) = &callbacks;
    $cb = $callbacks;
    return $callbacks->smart_transform( @params );
}

my $out_3 = group8e( 10 );
is( $out_3, 10 );

$out_3 = group8e( 10, $cb );
is( $out_3, 10 );

$out_3 = group8e( $cb );
is( $out_3, 0); # Zero elements back

######################################
#More tests to increase coverage a tad
######################################

eval { Params::Callbacks::transform( 'NotParamsCallbacks' ) };
like( $@, qr/CRIT_BAD_CALLBACK_LIST/ );
eval { Params::Callbacks::transform( bless( \my $s, 'NotParamsCallbacks' ) ) };
like( $@, qr/CRIT_BAD_CALLBACK_LIST/ );
