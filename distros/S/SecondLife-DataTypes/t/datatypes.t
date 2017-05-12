use Test::More tests => 3;
use SecondLife::DataTypes qw( slrot slvec slregion );

my $rot = slrot '<1,2,3,0>';
is( "$rot", "<1, 2, 3, 0>", "rotation" );
my $vec = slvec '<30,10,50>';
is( "$vec", "<30, 10, 50>", "vector" );
my $region = slregion 'Foo (1,300)';
is( "$region", "Foo (1, 300)", "region" );
