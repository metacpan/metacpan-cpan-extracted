use 5.012;
use warnings;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;

catch_run("[deflate]");

done_testing();
