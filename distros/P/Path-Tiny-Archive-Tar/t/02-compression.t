#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Path::Tiny qw( tempdir );
use Path::Tiny::Archive::Tar qw( :const );


my $t = tempdir();

$t->child('foo.txt')->spew('Foo' x 1000);

ok $t->child('foo.txt')->tar($t->child('foo.tar'));
ok $t->child('foo.txt')->tar($t->child('foo.tgz'), COMPRESSION_GZIP);

ok $t->child('foo.tar')->is_file;
ok $t->child('foo.tar')->stat->size;
ok $t->child('foo.tgz')->is_file;
ok $t->child('foo.tgz')->stat->size;

ok $t->child('foo.tar')->stat->size > $t->child('foo.tgz')->stat->size;


done_testing;
