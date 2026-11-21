#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;

use Path::Tiny qw( tempdir );
use Skilletor::Catalog;

my $root = tempdir;
my @names = ( 'bar', "\x{10000}", 'Foo', '-dash', "\x{E000}", 'Baz', '_under' );
for my $name (@names) {
  my $dir = $root->child( 'skills', $name );
  $dir->mkpath;
  $dir->child('SKILL.md')->spew_utf8("---\ndescription: $name\n---\n");
}
is_deeply(
  [ map { $_->{name} } @{ Skilletor::Catalog->scan("$root")->{items} } ],
  [ '-dash', 'Baz', 'Foo', '_under', 'bar', "\x{E000}", "\x{10000}" ],
  'published-layout items use UTF-8 byte order, including non-ASCII names that differ in UTF-16 order',
);

done_testing;
