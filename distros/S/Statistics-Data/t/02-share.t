use strict;
use warnings FATAL   => 'all';
use Test::More tests => 3;
use constant EPS     => 1e-3;
use Statistics::Data;
use Array::Compare;

BEGIN {
    use_ok('Statistics::Data') || print "Bail out!\n";
}

my $dat = Statistics::Data->new();

my $cmp_aref = Array::Compare->new;

my @data1 = ( 1, 2, 3, 3, 3, 1, 4, 2, 1, 2 );    # 10 elements
my @data2 = ( 2, 4, 4, 1, 3, 3, 5, 2, 3, 5 );

$dat->load( { dist1 => \@data1, dist2 => \@data2 } );

my $dat_new = Statistics::Data->new();
$dat_new->share($dat);

ok( $dat_new->ndata() == 2,
    "Error after share(): Number of loaded sequences does not equal 2" );

my $ret_data = $dat_new->access( label => 'dist2' );
ok(
    $cmp_aref->simple_compare( \@data2, $ret_data ),
    'Error after share(): got ' . join( '', @$ret_data )
);

1;
