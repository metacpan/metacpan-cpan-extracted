# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Statistics-KernelEstimation.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 17;
use Statistics::KernelEstimation;

#########################

$s = Statistics::KernelEstimation->new();

ok( scalar @{ $s->histogram( 10 ) } == 0, "Empty histogram" );
ok( scalar @{ $s->distribution_function()}==0, "Empty Distribution Function");

$s->add_data( 0 );
$s->add_data( 1 );
$s->add_data( 1 );
$s->add_data( -1, 2 );

# "on-the-edge" values go to the lower bin
$s->add_data( 0.125, 10 );          # Magic values
$s->add_data( 0.125 - 1e-14, 20 );

$h = $s->histogram( 9 ); # Binwidth: 2/(9-1) = 0.25

ok( $h->[0]{pos} == -1, "First Bin Location" );
ok( $h->[0]{cnt} == 2, "First Bin Count" );
ok( $h->[1]{pos} > -1, "Second Bin Location" );
ok( $h->[1]{cnt} == 0, "Second Bin Count" );
ok( $h->[8]{pos} == 1, "Last Bin Location" );

ok( $h->[4]{pos} == 0, "Middle Bin Location" );
ok( $h->[4]{cnt} == 21, "Middle Bin Count" );
ok( $h->[5]{cnt} == 10, "Next-to-middle Bin Count" );

$y = 0;
for( @$h ) { $y += $_->{cnt} }
ok( $y == $s->count(), "Histogram Normalized" );


$d = $s->distribution_function();
ok( scalar @$d == 6, "scalar( \@distrib_fct ) == calls to add_data()" );
ok( $d->[0]{pos} == -1, "Distrib Fct First Element Location" );
ok( $d->[0]{cnt} == 2, "Distrib Fct First Element Count" );
ok( $d->[-2]{pos} == $d->[-1]{pos},"Distrib Fct Elements With Equal Location");
ok( $d->[-1]{pos} == 1, "Distrib Fct Last Element Location" );
ok( $d->[-1]{cnt} == 35, "Distrib Fct Last Element Count" );
