use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;

catch_run('[parse-special-codes]');

done_testing();