#!perl -w
use strict;
use Test;
BEGIN { plan tests => 9 }

my $file = 't/cat.plx';
my $seed = do { open FOO, $file; local $/; <FOO> };
ok($seed);

my $foo;

$foo = `$^X t/cat.plx < $file`;
ok($foo, $seed, "straight with pipe");

$foo = `$^X t/cat.plx $file`;
ok($foo, $seed, "straight with arg");

$foo = `./pperl t/cat.plx < $file`;
ok($foo, $seed, "pperl with pipe");

$foo = `./pperl t/cat.plx $file`;
ok($foo, $seed, "pperl with arg");

$foo = `./pperl t/cat.plx < $file`;
ok($foo, $seed, "pperl with pipe2");

$foo = `./pperl t/cat.plx $file`;
ok($foo, $seed, "pperl with arg2");

$foo = `./pperl t/cat.plx < $file`;
ok($foo, $seed, "pperl with pipe3");

$foo = `./pperl t/cat.plx $file`;
ok($foo, $seed, "pperl with arg3");

system("./pperl --kill t/cat.plx");
