use strict;
use warnings;
use Test::More tests => 6;
BEGIN { use_ok('Test::DeepFile') };
use Test::Exception;

cmp_deeply_file([ 'one' ], "one more");

dies_ok { cmp_deeply_file([]); } "bad arguments";
dies_ok { cmp_deeply_file([], "one more"); } "duplicate name argument";

delete $Test::DeepFile::seen{'one more'};

cmp_deeply_file([ 'one' ], "one more");

unlink "t/deepfile/one more.data" or die;

cmp_deeply_file([ 'two' ], "two more");

unlink "t/deepfile/two more.data" or die;
