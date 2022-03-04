use Test2::V0 -no_srand => 1;
use NewFangle::Lib;

my @lib = NewFangle::Lib->lib;

note "lib=$_" for @lib;

is \@lib, array { item T(); etc; };

done_testing;
