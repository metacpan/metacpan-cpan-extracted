use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;
use Test::Catch;

plan skip_all => "set TEST_FULL" unless $ENV{TEST_FULL};

catch_run("[bugs]");

done_testing;
