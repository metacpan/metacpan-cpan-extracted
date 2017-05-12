use 5.008003;
use strict;
use warnings;
use Test::More;
use Term::ReadLine::Simple;

my $package = 'Term::ReadLine::Simple';

ok( $package->can( 'VERSION' ), "$package can 'VERSION'" );

my $v;
ok( $v = $package->VERSION, "$package VERSION is '$v'" );

done_testing;
