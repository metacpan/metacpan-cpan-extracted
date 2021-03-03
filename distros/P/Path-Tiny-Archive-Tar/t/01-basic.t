#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Path::Tiny qw( tempdir );
use Path::Tiny::Archive::Tar ();


my $s = tempdir();
my $d = tempdir();

$s->child('foo.txt')->spew('Foo');
$s->child('bar')->mkpath();


ok $s->child('foo.txt')->tar($d->child('foo1.tar'));
ok $s->tar($d->child('foo2.tar'));

is_deeply [ sort map { $_->basename } $d->children ], [ qw( foo1.tar foo2.tar ) ];
for ($d->children) {
    ok $_->is_file;
    ok $_->stat->size;
}

cleanup_dir($s);

ok $d->child('foo1.tar')->untar($s);

is_deeply [ sort map { $_->basename } $s->children ], [ qw( foo.txt ) ];
ok $s->child('foo.txt')->is_file;
is $s->child('foo.txt')->slurp(), 'Foo';

cleanup_dir($s);

ok $d->child('foo2.tar')->untar($s);

is_deeply [ sort map { $_->basename } $s->children ], [ qw( bar foo.txt ) ];
ok $s->child('foo.txt')->is_file;
is $s->child('foo.txt')->slurp(), 'Foo';
ok $s->child('bar')->is_dir;


done_testing;


sub cleanup_dir {
    for ($_[0]->children) {
        if ($_->is_file) {
            $_->remove();
        }
        elsif ($_->is_dir) {
            $_->remove_tree();
        }
    }
}
