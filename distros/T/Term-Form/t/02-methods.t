use 5.10.0;
use strict;
use warnings;
use Test::More;
use Term::Form;

my $package = 'Term::Form';

ok( $package->ReadLine() eq 'Term::Form', "$package->ReadLine() eq 'Term::Form'" );

my $new;
ok( $new = $package->new(), "$package->new()" );

done_testing;
