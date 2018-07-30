use lib 't/lib';

package My::Envoy::Models;

use Moose;
with 'Model::Envoy::Set' => { namespace => 'My::Envoy' };

1;

package main;

use Test::More;
use Test::Exception;

My::Envoy::Models->load_types( qw( Widget Part ) );

my %tries = (
    'Widget'   => 1,
    'Part'     => 1,
    'Missing'  => 0,
    '0invalid' => 0,
    ' '        => 0,
    0          => 0,
    ''         => 0,
    ' invalid' => 0,
);

while( my ( $name, $lives ) = each %tries ) {

    if ( $lives ) {
        lives_ok( sub { My::Envoy::Models->load_types( $name ) }, "'$name' lives" );
    }
    else {
        dies_ok(  sub { My::Envoy::Models->load_types( $name ) }, "'$name' dies" );
    }
}

dies_ok(  sub { My::Envoy::Models->load_types( keys %tries )                     }, "mixed bag dies" );
lives_ok( sub { My::Envoy::Models->load_types( grep { $tries{$_} } keys %tries ) }, "known good lives" );

done_testing;