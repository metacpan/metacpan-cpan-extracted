use 5.10.0;
use strict;
use warnings;
use Test::More;
use Term::Form;

my $package = 'Term::Form';

ok( $package->can( 'VERSION' ), "$package can 'VERSION'" );

my $v;
ok( $v = $package->VERSION, "$package VERSION is '$v'" );

done_testing;
