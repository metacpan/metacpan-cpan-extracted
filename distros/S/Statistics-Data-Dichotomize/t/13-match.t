use Test::More tests => 11;
use constant EPS     => 1e-3;
use Array::Compare;

use Statistics::Data::Dichotomize;
my $ddat = Statistics::Data::Dichotomize->new();

my $data_aref;
my $debug = 0;
my $cmp_aref = Array::Compare->new;
my @res_data = ();

# match method
my @a = (qw/1 3 3 2 1 5 1 2 4/);
my @b = (qw/4 3 1 2 1 4 2 2 4/);
@res_data = (qw/0 1 0 1 1 0 0 1 1/);

$data_aref = $ddat->match( data => [ \@a, \@b ] );
diag(
    "match() method (no lag):\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in match results" );

## - same but with load/read:
$ddat->load( a => \@a, b => \@b );
$data_aref = $ddat->match(
    data => [ $ddat->access( label => 'a' ), $ddat->access( label => 'b' ) ] );
diag("match() method (no lag, retrieved data)") if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in match results" );

## - same but lag => 0
@a         = (qw/c b b b d a c d b d/);
@b         = (qw/d a a d b a d c c e/);
@res_data  = (qw/0 0 0 0 0 1 0 0 0 0/);
$data_aref = $ddat->match( data => [ \@a, \@b ], lag => 0 );
diag(
    "match() method, lag => 0:\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in match results" );

## - same but lag => +1
@res_data = (qw/0 0 0 1 0 0 1 0 0/);
$data_aref = $ddat->match( data => [ \@a, \@b ], lag => 1 );
diag(
    "match() method, lag => +1:\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in match results" );

## - same but lag => -2
@res_data = (qw/0 0 1 0 1 0 1 0/);
$data_aref = $ddat->match( data => [ \@a, \@b ], lag => -2 );
diag(
    "match() method, lag => -2:\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in match results" );

## - same but lag => 1, loop => 1
@res_data = (qw/1 0 0 0 1 0 0 1 0 0/);
$data_aref = $ddat->match( data => [ \@a, \@b ], lag => 1, loop => 1 );
diag(
    "match() method, lag => 1 (with loop):\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in match results" );

# - same but with set {a, b} not {0, 1}:
@res_data = (qw/b a a a b a a b a a/);
$data_aref = $ddat->match( data => [ \@a, \@b ], lag => 1, loop => 1, set => [qw/a b/] );
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in pool results with set {a, b}" );


# lag method:
@a = (qw/c b b b d a c d b d/);
@b = (qw/d a a d b a d c c e/);
my $aref = $ddat->crosslag( data => [ \@a, \@b ], lag => 1, loop => 1 );
ok( $cmp_aref->simple_compare( [qw/d c b b b d a c d b/], $aref->[0] ),
    "Error in lag" );
ok( $cmp_aref->simple_compare( \@b, $aref->[1] ), "Error in lag" );
$aref = $ddat->crosslag( data => [ \@a, \@b ], lag => 1, loop => 0 );
ok( $cmp_aref->simple_compare( [qw/b b b d a c d b d/], $aref->[0] ),
    "Error in lag" );
ok( $cmp_aref->simple_compare( [qw/d a a d b a d c c/], $aref->[1] ),
    "Error in lag" );

1;
