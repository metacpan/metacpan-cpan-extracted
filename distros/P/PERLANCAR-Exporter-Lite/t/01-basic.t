#!perl

#use 5.010;
#use strict 'subs', 'vars';
#use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::Exception;
use Test::More 0.98;

require Local::MyLib;

lives_ok { Local::MyLib->import() } "importing default";
lives_ok { __PACKAGE__->sub1 } "sub1 (default export) imported";
dies_ok  { __PACKAGE__->sub2 } "sub2 not yet imported";

lives_ok { Local::MyLib->import("sub2") } "importing sub2";
lives_ok { __PACKAGE__->sub2 } "sub2 now imported";

dies_ok { Local::MyLib->import("sub3") } "importing non-exports";

lives_ok { Local::MyLib->import('$SCALAR1') } "importing scalar";
is(${__PACKAGE__.'::SCALAR1'}, 42, 'scalar imported');

lives_ok { Local::MyLib->import('@ARRAY1') } "importing array";
is_deeply(\@{__PACKAGE__.'::ARRAY1'}, [1,2], 'array imported');

lives_ok { Local::MyLib->import('%HASH1') } "importing hash";
is_deeply(\%{__PACKAGE__.'::HASH1'}, {a=>3, b=>4}, 'hash imported');

lives_ok { Local::MyLib->import('*GLOB1') } "importing glob";
lives_ok { __PACKAGE__->GLOB1 } 'glob imported';

done_testing;
