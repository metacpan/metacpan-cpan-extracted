use 5.10.1;
use strict;
use warnings;
use Test::More;
use Term::Form;
use Term::Form::ReadLine;

my $package = 'Term::Form';
ok( $package->can( 'VERSION' ), "$package can 'VERSION'" );
my $v;
ok( $v = $package->VERSION, "$package VERSION is '$v'" );



$package = 'Term::Form::ReadLine';
ok( $package->can( 'VERSION' ), "$package can 'VERSION'" );
ok( $v = $package->VERSION, "$package VERSION is '$v'" );


done_testing;
