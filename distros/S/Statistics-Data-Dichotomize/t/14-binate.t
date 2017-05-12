use Test::More tests => 3;
use constant EPS     => 1e-3;
use Array::Compare;

use Statistics::Data::Dichotomize;
my $ddat = Statistics::Data::Dichotomize->new();

my $data_aref;
my $cmp_aref = Array::Compare->new;
my $debug = 0;

# binate method
my @raw_data = (qw/a b c a b/);
my @res_data = ( 1, 0, 0, 1, 0 );
$ddat->load(@raw_data);
$data_aref = $ddat->binate();
diag(
    "binate() method:\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in binate results" );

## - same but specify what is "1":
@res_data = ( 0, 1, 0, 0, 1 );
$data_aref = $ddat->binate( oneis => 'b' );
diag(
    "binate() method (setting oneis):\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in binate results" );

# - same but get set of -1 and 1, not 0 and 1:
@res_data = ( -1, 1, -1, -1, 1 );
$data_aref = $ddat->binate(oneis => 'b', set => [-1, 1] ); # 
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in cut results with set {-1, 1}" );

1;
