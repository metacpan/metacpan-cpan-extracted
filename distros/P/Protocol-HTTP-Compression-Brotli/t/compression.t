use 5.012;
use Test::More;
use Test::Catch;
use lib 't'; use MyTest;

catch_run('[brotli-compression]');

done_testing;
