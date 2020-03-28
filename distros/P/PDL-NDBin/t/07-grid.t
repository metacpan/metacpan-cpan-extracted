#! perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;
use PDL::Lite qw[ pdl ];
use PDL::Basic qw[ sequence ];
use PDL::NDBin;
use PDL::NDBin::Utils_PP;

# test grid validation

*_validate_grid = \&PDL::NDBin::Utils_PP::_validate_grid;


lives_ok { _validate_grid( pdl( 1, 5, 9 ) ) } "monotonically increasing grid";

lives_ok { _validate_grid( pdl( 9, 8, 3, 2 ) ) }
"monotonically decreasing grid";

throws_ok { _validate_grid( pdl( 0, 0 ) ) } qr/not monotonic/, "[0] == [-1]";

throws_ok { _validate_grid( pdl( 1, 3, 2, 8, 9 ) ) } qr/not monotonic/,
  "[0] < [-1], not monotonic";

throws_ok { _validate_grid( pdl( 9, 6, 7, 2, 1 ) ) } qr/not monotonic/,
  "[0] > [-1], not monotonic";

# make sure that grid is validated in top level code

lives_ok {
    PDL::NDBin->new( axes => [ [ x => ( grid => pdl( 1, 2, 3 ) ) ] ] )
      ->process( x => PDL->sequence( 20 ) );
}
'bin on monotonic increasing grid';

lives_ok {
    PDL::NDBin->new( axes => [ [ x => ( grid => pdl( 3, 2, 1 ) ) ] ] )
      ->process( x => PDL->sequence( 20 ) );
}
'bin on monotonic decreasing grid';

throws_ok {
    PDL::NDBin->new( axes => [ [ x => ( grid => pdl( 1, 2, 1 ) ) ] ] )
      ->process( x => PDL->sequence( 20 ) );
}
qr/not monotonic/, 'bin on grid [0] == [-1]';

throws_ok {
    PDL::NDBin->new( axes => [ [ x => ( grid => pdl( 1, 2, 5, 4, 10 ) ) ] ] )
      ->process( x => PDL->sequence( 20 ) );
}
qr/not monotonic/, 'bin on grid [0] < [-1], not monotonic';

throws_ok {
    PDL::NDBin->new( axes => [ [ x => ( grid => pdl( 10, 4, 5, 2, 1 ) ) ] ] )
      ->process( x => PDL->sequence( 20 ) );
}
qr/not monotonic/, 'bin on grid [0] > [-1], not monotonic';


# test grid

my $data = pdl( 2, 2, 5, 7, 7, 7, 7, 8.5, 9, 9, 9, 9 );
my $grid = pdl( 0, 3, 6, 8, 10 );

my $h;

lives_ok { $h = PDL::NDBin->new( axes => [ [ x => ( grid => $grid ) ] ] )
	   ->process( x => $data )->output->{histogram}; } 'bin w/ grid';

is_deeply( [ $h->list ], [ 2, 1, 4, 5 ], 'grid bin histogram' );

