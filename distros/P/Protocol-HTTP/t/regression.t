use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;

chdir 'clib';
catch_run('[regression]');
chdir '..';

done_testing();
