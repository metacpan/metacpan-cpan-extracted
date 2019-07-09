use 5.008003;
use strict;
use warnings;
use Test::More;
use Term::Choose;

my $package = 'Term::Choose';

my $new;
ok( $new = $package->new(), "$package->new()" );

done_testing;
