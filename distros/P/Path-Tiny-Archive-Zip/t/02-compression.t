#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Path::Tiny qw( tempdir );
use Path::Tiny::Archive::Zip qw( :const );


my $t = tempdir();

$t->child('foo.txt')->spew('Foo' x 1000);

ok $t->child('foo.txt')->zip($t->child('foo0.zip'), COMPRESSION_NONE);
ok $t->child('foo.txt')->zip($t->child('foo9.zip'), COMPRESSION_BEST);

ok $t->child('foo0.zip')->is_file;
ok $t->child('foo0.zip')->stat->size;
ok $t->child('foo9.zip')->is_file;
ok $t->child('foo9.zip')->stat->size;

ok $t->child('foo0.zip')->stat->size > $t->child('foo9.zip')->stat->size;


done_testing;
