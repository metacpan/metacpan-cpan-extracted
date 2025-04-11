use 5.10.1;
use strict;
use warnings;
use Test::More;
use Term::Form;
use Term::Form::ReadLine;

my $package = 'Term::Form';
my $new;
ok( $new = $package->new(), "$package->new()" );

$package = 'Term::Form::ReadLine';
ok( $new = $package->new(), "$package->new()" );

done_testing;
