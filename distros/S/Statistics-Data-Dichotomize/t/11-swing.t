use Test::More tests => 9;
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

# swing method - Wolfowitz example, p. 283
diag("tests with Wolfowitz (1943, p. 283) sample data:") if $debug;
@raw_data  = (qw/3 4 7 6 5 1 2 3 2/);
@res_data  = (qw/1 1 0 0 0 1 1 0/);
$data_aref = $ddat->swing( data => \@raw_data );
diag(
    "\nswing(eq => undef):\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in swing results" );

# - same but with anonymous load and retrieval of data:
eval { $ddat->load( \@raw_data ); };
ok( !$@, "Error in anonymous load" );
$data_aref = $ddat->swing();    # same as sending: index => 0
diag(
    "\nswing(eq => undef):\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok(
    $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in swing results by anonymous retrieval of data"
);

# - same but get set of -1 and 1, not 0 and 1:
@res_data = (qw/1 1 -1 -1 -1 1 1 -1/);
$data_aref = $ddat->swing( data => \@raw_data, set => [ -1, 1 ] );
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in swing results by anonymous retrieval of data with set {-1, 1}" );

@raw_data = (qw/3 3 7 6 5 2 2/);
@res_data =
  (qw/1 0 0 0/);    # First and final results (of 3 - 3, and 2 - 2) are skipped
$data_aref = $ddat->swing( data => \@raw_data, equal => 0 );
diag(
    "swing(eq => 0):\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in swing results" );

@res_data = (qw/1 0 0 0 0/)
  ;    # First result (of 3 - 3) is skipped, and final result repeats the former
$data_aref = $ddat->swing( data => \@raw_data, equal => 'rpt' );
diag(
    "swing(eq => 'rpt'):\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in swing results" );

@res_data = (qw/1 1 0 0 0 1/);    # Greater than or equal to zero is an increase
$data_aref = $ddat->swing( data => \@raw_data, equal => 'gt' );
diag(
    "swing(eq => 'gt'):\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in swing results" );

@res_data = (qw/0 1 0 0 0 0/);    # Less than or equal to zero is a decrease
$data_aref = $ddat->swing( data => \@raw_data, equal => 'lt' );
diag(
    "swing(eq => 'lt'):\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in swing results" );

@raw_data = (
    0.41, 0.68, 0.89, 0.94, 0.74, 0.91, 0.55, 0.62, 0.36, 0.27,
    0.19, 0.72, 0.75, 0.08, 0.54, 0.02, 0.01, 0.36, 0.16, 0.28,
    0.18, 0.01, 0.95, 0.69, 0.18, 0.47, 0.23, 0.32, 0.82, 0.53,
    0.31, 0.42, 0.73, 0.04, 0.83, 0.45, 0.13, 0.57, 0.63, 0.29
);
@res_data = (
    qw/1 1 1 0 1 0 1 0 0 0 1 1 0 1 0 0 1 0 1 0 0 1 0 0 1 0 1 1 0  0 1 1 0 1 0 0 1 1 0/
);    # First and final results (of 3 - 3, and 2 - 2) are skipped
$data_aref = $ddat->swing( data => \@raw_data, equal => 0 );
diag(
    "swing(eq => 0) (CSE808 sample data):\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in swing results" );

1;
