use warnings;
use autodie;

use Statistics::RserveClient::REXP::GenericVector;

use Test::More tests => 3;

my $gvec = new Statistics::RserveClient::REXP::GenericVector;

isa_ok( $gvec, 'Statistics::RserveClient::REXP::GenericVector', 'new returns an object that' );
ok( $gvec->isList(),   'GenericVector is a list' );
ok( $gvec->isVector(), 'GenericVector is a vector' );

done_testing();
