use Test2::V0;

use String::Interpolate::RE qw( strinterp );

my %vars = ( a => '1' );

my $str = '${a:%02d} $a ${a}';

is( strinterp( $str, \%vars, { UseENV => 0, Format => 0 } ), '${a:%02d} 1 1', "format = off" );

is( strinterp( $str, \%vars, { UseENV => 0, Format => 1 } ), '01 1 1', "format = on" );

is( strinterp( '${a:%02d-}/$a/${a}', {}, { UseENV => 0, Format => 1, EmptyUndef => 1 } ),
    '//', "format = on, emptyundef = on" );

done_testing;
