use strict;
use warnings FATAL   => 'all';
use Test::More tests => 22;
use constant EPS     => 1e-3;
use Statistics::Data;
use Array::Compare;

BEGIN {
    use_ok('Statistics::Data') || print "Bail out!\n";
}

my $dat = Statistics::Data->new();
isa_ok( $dat, 'Statistics::Data' );

my $cmp_aref = Array::Compare->new;

my ( $ret, @data1, @data2, @data3, @data4 ) = ();

@data1 = ( 1, 2, 3, 3, 3, 1, 4, 2, 'x', 2 );
@data2 = ( 2, 4, 4, 1, 3, 3, 5, 2, '',  5 );
@data3 = ( 2, -3, 4 );
@data4 = ( 2, 3,  4 );

# using anonymous, unloaded data:
$ret = $dat->all_full( \@data1 );
ok( $ret == 1, "Error in testing all_full(): Should be 1, is $ret" );

$ret = $dat->all_full( \@data2 );
ok( $ret == 0, "Error in testing all_full(): Should be 0, is $ret" );

$ret = $dat->all_numeric( \@data1 );
ok( $ret == 0, "Error in testing all_numeric(): Should be 0, is $ret" );

# using loaded data:
$dat->load( dist1 => [ @data1[ 0 .. 7 ] ] );
$ret = $dat->all_numeric( label => 'dist1' );
ok( $ret == 1, "Error in testing all_numeric(): Should be 1, is $ret" );

$dat->add( dist1 => [ '', 1 ] );
$ret = $dat->all_numeric( label => 'dist1' );
ok( $ret == 0, "Error in testing all_numeric(): Should be 0, is $ret" );

$dat->add( dist1 => [ undef, 1 ] );
$ret = $dat->all_numeric( label => 'dist1' );
ok( $ret == 0, "Error in testing all_numeric(): Should be 0, is $ret" );

$dat->add( dist1 => [ 'x', 1 ] );
$ret = $dat->all_numeric( label => 'dist1' );
ok( $ret == 0, "Error in testing all_numeric(): Should be 0, is $ret" );

$ret = $dat->all_numeric( \@data2 );
ok( $ret == 0, "Error in testing all_numeric(): Should be 0, is $ret" );

$ret = $dat->all_proportions( label => 'dist1' );
ok( $ret == 0, "Error in testing all_proportions(): Should be 0, is $ret" );

$dat->load( [ 0, 1 ] );
$ret = $dat->all_proportions();
ok( $ret == 1, "Error in testing all_proportions(): Should be 1, is $ret" );

$dat->load( [ .8, .3, '', .4 ] );
$ret = $dat->all_proportions();
ok( $ret == 0, "Error in testing all_proportions(): Should be 0, is $ret" );

$dat->load( dist => [ .3, .25, .8 ] );
$ret = $dat->all_proportions( label => 'dist' );
ok( $ret == 1, "Error in testing all_proportions(): Should be 1, is $ret" );

$dat->load( \@data3 );
$ret = $dat->all_pos();
ok( $ret == 0, "Error in testing all_pos(): Should be 0, is $ret" );

$dat->load( dist => \@data4 );
$ret = $dat->all_pos( label => 'dist' );
ok( $ret == 1, "Error in testing all_pos(): Should be 1, is $ret" );

$dat->load( [ 2.2, 2, 3 ] );
$ret = $dat->all_counts();
ok( $ret == 0, "Error in testing all_counts(): Should be 0, is $ret" );

$dat->load( [ -1, 2, 3 ] );
$ret = $dat->all_counts();
ok( $ret == 0, "Error in testing all_counts(): Should be 0, is $ret" );

$dat->load( [ 1, 2, 3 ] );
$ret = $dat->all_counts();
ok( $ret == 1, "Error in testing all_counts(): Should be 1, is $ret" );

# check return of "valid" values:

my $vals;

( $vals, $ret ) = $dat->all_full( [ 3, '', 0.7, undef, 'b' ] );
ok(
    $cmp_aref->simple_compare( [ 3, 0.7, 'b' ], $vals ),
    'Error in testing all_full(): got ' . join( '', @{$vals} )
);

( $vals, $ret ) = $dat->all_numeric( [ 3, '', 0.7, undef, 'b' ] );
ok( $cmp_aref->simple_compare( [ 3, 0.7 ], $vals ),
    'Error in testing all_numeric(): got ' . join( '', @{$vals} ) );

( $vals, $ret ) = $dat->all_proportions( [ 3, '', 0.7, undef, 'b' ] );
ok( $cmp_aref->simple_compare( [0.7], $vals ),
    'Error in testing all_proportions(): got ' . join( '', @{$vals} ) );

sub equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}

1;
