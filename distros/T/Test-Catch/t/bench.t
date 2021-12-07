use 5.012;
use warnings;
use Test::More;
use Test::Catch;
use Test::Simple;

plan skip_all => 'set TEST_FULL=1 to enable real test coverage' unless $ENV{TEST_FULL};

XS::Loader::load('MyTest');

catch_run("bench");

done_testing(1);
