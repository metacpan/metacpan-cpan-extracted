use Test::More tests => 3;
use constant EPS     => 1e-3;
use Array::Compare;

use Statistics::Data::Dichotomize;
my $ddat = Statistics::Data::Dichotomize->new();

my $data_aref;
my $debug    = 0;
my $cmp_aref = Array::Compare->new;

# pool method
## - example from Swed & Eisenhart p. 69
my @a        = (qw/1.95 2.17 2.06 2.11 2.24 2.52 2.04 1.95/);
my @b        = (qw/1.82 1.85 1.87 1.74 2.04 1.78 1.76 1.86/);
my @res_data = ( 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0 );

$data_aref = $ddat->pool( data => [ \@a, \@b ] );
diag(
    "pool() method:\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in pool results" );

## - same but with load/read:
$ddat->load( a => \@a, b => \@b );
$data_aref =
  $ddat->pool( data => scalar $ddat->get_aoa_by_lab( lab => [qw/a b/] ) );
diag(
    "pool() method (retrieved data):\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in pool results" );

# - same but with set {a, b} not {0, 1}:
@res_data = (qw/b b b b b b b a a b a a a a a a/);
$data_aref =
  $ddat->pool( data => scalar $ddat->get_aoa_by_lab( lab => [qw/a b/] ), set => [qw/a b/] );
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in pool results with set {a, b}" );

1;
