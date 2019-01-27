use 5.008003;
use strict;
use warnings;
use Test::More;
use Term::Form;

my $package = 'Term::Form';

ok( $package->ReadLine() eq 'Term::Form', "$package->ReadLine() eq 'Term::Form'" );

my $new;
ok( $new = $package->new( 'name' ), "$package->new( 'name' )" );

done_testing;
