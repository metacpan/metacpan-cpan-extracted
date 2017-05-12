use Test::More tests => 16;
use constant EPS     => 1e-3;
use Array::Compare;

use Statistics::Data::Dichotomize;
my $ddat = Statistics::Data::Dichotomize->new();

my @raw_data = ();
my @res_data = ();
my $val;
my $data_aref;
my $debug    = 0;
my $cmp_aref = Array::Compare->new;

# cut method
@raw_data = ( 4, 3, 3, 5, 3, 4, 5, 6, 3, 5, 3, 3, 6, 4, 4, 7, 6, 4, 7, 3 );
( $data_aref, $val ) =
  $ddat->cut( data => \@raw_data, value => \&Statistics::Lite::median );
ok( equal( $val, 4 ), "median cut value  $val != 4" );

( $data_aref, $val ) = $ddat->cut( data => \@raw_data, value => 'median' );
ok( equal( $val, 4 ), "median cut value  $val != 4" );

@res_data = ( 0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0 );
( $data_aref, $val ) = $ddat->cut( data => \@raw_data, value => 5 );
diag(
    "cut() method:\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref ),
    "\n\tvalue\t=>\t", $val
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results" );

# - same but using prior load() of data:
$ddat->load( \@raw_data );
( $data_aref, $val ) = $ddat->cut( index => 0, value => 5 );
diag(
    "cut() method (with prior data load):\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t",
    join( '', @$data_aref ),
    "\n\tvalue\t=>\t",
    $val
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results" );

# - same but get set of -1 and 1, not 0 and 1:
( $data_aref, $val ) =
  $ddat->cut( data => \@raw_data, value => 5, set => [ -1, 1 ] );
@res_data =
  ( -1, -1, -1, 1, -1, -1, 1, 1, -1, 1, -1, -1, 1, -1, -1, 1, 1, -1, 1, -1 );
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results with set {-1, 1}" );

# using custom cut fn (mean = 4):
@res_data = ( 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0 );
( $data_aref, $val ) = $ddat->cut(
    index => 0,
    value => sub {
        my @ari = @_;
        my $sum = 0;
        for (@ari) { $sum += $_ }
        return int( $sum / ( scalar @ari ) );
    }
);

diag(
"cut() method (with prior data load using custom sub for value):\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t",
    join( '', @$data_aref ),
    "\n\tvalue\t=>\t",
    $val
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results" );

#-----------------------------------
# TEST control of values equalling the cut-value
# use data from Pratt et al. (1940) where run-scores are tested for joins dichotomized by cutting with repeat method:
## - rpt
$ddat->load( 7, 8, 6, 5, 6, 4, 5, 5, 0, 1, 2, 6, 4, 5, 8 );    # numerical data
$data_aref = $ddat->cut( value => 5, equal => 'rpt' );
@res_data = split //, '111110000001001';
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results" );

## - gt
$data_aref = $ddat->cut( value => 5, equal => 'gt' );
@res_data = split //, '111110110001011';
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results" );

$data_aref = $ddat->cut( value => 5, equal => 'lt' );
@res_data = split //, '111010000001001';
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results" );

$data_aref = $ddat->cut( value => 5, equal => 0 );
@res_data = split //, '11110000101';
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results" );

$data_aref = $ddat->cut( value => 5, equal => 'skip' );
@res_data = split //, '11110000101';
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results" );

$data_aref = $ddat->cut( value => 5 );    # use equal => 'gt'  by default
@res_data = split //, '111110110001011';
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results" );

$ddat->load( 5, 5, 5 );                   # numerical data
$data_aref = $ddat->cut( value => 5 );    # use equal => 'gt'  by default
@res_data = split //, '111';
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results" );

$data_aref = $ddat->cut( value => 5, equal => 'lt' );
@res_data = split //, '000';
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results" );

$data_aref = $ddat->cut( value => 5, equal => 'rpt' );
@res_data = split //, '111';
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results" );

# POD example of 'rpt'
$ddat->load( 4, 5, 6, 5 );    # numerical data
$data_aref = $ddat->cut( value => 5, equal => 'rpt' );
@res_data = split //, '0011';
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results" );

sub equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
