#! perl

use Test2::V0;

use String::Interpolate::RE qw( strinterp );

my %vars = ( 'a.2' => '1', 'b.3' => '2' );

is( strinterp( '${a.2}-${b.3}', \%vars ), '${a.2}-${b.3}', 'default variable regex', );

is(
    strinterp( '${a.2}-${b.3}', \%vars, { variable_re => qr/[\w\.]+/ } ),
    '1-2', 'custom variable regex',
);

done_testing;

