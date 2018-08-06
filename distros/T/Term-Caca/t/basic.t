use strict;
use warnings;

# env CACA_DRIVER=x11 TERMCACAPAUSE=1 perl -Ilib t/basic.t for manual
# testing

use Test::More;
use Test::Approx;

use Term::Caca::Constants qw/ :colors /;
use Term::Caca;

diag "available drivers: ", explain [ Term::Caca->drivers ];

my $driver = $ENV{CACA_DRIVER} || join '', grep { /^null$/ } Term::Caca->drivers;

plan skip_all => 'no driver available to run the tests' unless $driver;

my $t = Term::Caca->new( driver => $driver );

$t->title( __FILE__ )->refresh_delay( 1 );

$t->set_color( RED, BLACK );

$t->mouse_position;

$t->triangle( [10, 10], [20, 20], [5, 17], char => 't' )
  ->triangle( [12, 10], [22, 10], [17, 17] )
  ->triangle( [14, 10], [24, 20], [9, 17], fill => 'T' );
pause_and_clear($t);

$t->box( [10, 10], [7, 5], 'c' );
$t->box( [15, 15], [7, 5], fill => '+' );
$t->box( [20, 20], [7, 5] );
$t->box( [5, 5], [7, 5], char => '-', fill => '*' );
pause_and_clear($t);

$t->ellipse( [10, 10], 5, 7, 'c' );
$t->ellipse( [15, 15], 5, 7, fill => '+' );
$t->ellipse( [20, 20], 5, 7 );
pause_and_clear($t);

$t->circle( [10, 10], 5, 'c' );
$t->circle( [15, 15], 5, fill => '+' );
$t->circle( [20, 20], 5 );
pause_and_clear($t);

$t->text( [ 5, 5 ], "Hi there!" );
$t->char( [ 5, 6 ], "X" );
$t->char( [ 5, 7 ], "X marks the spot" );
$t->char( [ 5, 8 ], "Y" );
pause_and_clear($t);

$t->polyline( [ [ 1,1], [10,15], [15, 10] ], char => 'x' );
$t->polyline( [ [ 1,5], [10,20], [15, 15] ], close => 1 );
pause_and_clear($t);

$t->char([5, 5], 'hello world');

$t->line( [0,0], [25,20], 't' );
$t->line( [5,0], [30,20] );
pause_and_clear($t);


cmp_ok $t->canvas_width, '>=', 0, "get_width()";
cmp_ok $t->canvas_height, '>=', 0, "get_height()";

my $render_time = $t->rendering_time;

# render time should be ~ 1 second

is_approx $render_time, 1, 'render time around 1s', '0.5';

pass 'reached the end';

done_testing;

sub pause_and_clear {
    my $t = shift;
    $t = $t->refresh;
    <> if $ENV{TERMCACAPAUSE};
    $t->clear;
}
