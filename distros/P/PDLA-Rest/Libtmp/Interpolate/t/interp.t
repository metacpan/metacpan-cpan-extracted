# NOTE: 
#  currently not in use anymore
#  - see PDLA::Func (in Lib/) and t/func.t
use Test::More skip_all => 'See PDLA::Func';

use PDLA::LiteF;

use strict;
use warnings;

plan tests => 5;

##########################################################

eval "use PDLA::Interpolate;";

my $x = float( 1, 2, 3, 4, 5, 6, 8, 10 );
my $y = ($x * 3) * ($x - 2);

my $obj = new PDLA::Interpolate( x => $x, y => $y );
isa_ok $obj, 'PDLA::Interpolate';
is $obj->library, "PDLA";

my $xi = $x - 0.5;
my $yi = $obj->interpolate( $xi );
is $obj->status, -1;

# compare to direct version
my ( $ans, $err ) = PDLA::Primitive::interpolate( $xi, $x, $y );
ok(all approx($ans, $yi));
#my $d = abs( $ans - $yi );
#ok( all $d < 1.0e-5 );

my $oerr = $obj->get( 'err' );
ok( all ($oerr-$err) == 0 );

#print "x:  ", $x, "\n";
#print "xi: ", $xi, "\n";
#print "$oerr\n";
