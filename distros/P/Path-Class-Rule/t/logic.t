use 5.006;
use strict;
use warnings;
use autodie;
use Test::More 0.92;
use Path::Class;
use File::Temp;
use Test::Deep qw/cmp_deeply/;
use File::pushd qw/pushd/;

use lib 't/lib';
use PCNTest;

use Path::Class::Rule;

#--------------------------------------------------------------------------#

my @tree = qw(
  aaaa.txt
  bbbb.txt
  cccc/dddd.txt
  cccc/eeee/ffff.txt
  gggg.txt
);

my $td = make_tree(@tree);

{
  my @files;
  my $rule = Path::Class::Rule->new->file->not_name("gggg.txt");
  my $expected = [ qw(
    aaaa.txt
    bbbb.txt
    cccc/dddd.txt
    cccc/eeee/ffff.txt
  )];
  @files = map { $_->relative($td)->as_foreign("Unix")->stringify } $rule->all($td);
  cmp_deeply( \@files, $expected, "not() test")
    or diag explain { got => \@files, expected => $expected };
}

{
  my @files;
  my $rule = Path::Class::Rule->new->file;
  $rule->or(
    $rule->new->name("gggg.txt"),
    $rule->new->name("bbbb.txt"),
  );
  my $expected = [qw/bbbb.txt gggg.txt/];

  @files = map { $_->relative($td)->as_foreign("Unix")->stringify } $rule->all($td);
  cmp_deeply( \@files, $expected, "or() test")
    or diag explain { got => \@files, expected => $expected };
}

{
  my @files;
  my $rule = Path::Class::Rule->new;
  $rule->skip(
    $rule->new->name("gggg.txt"),
    $rule->new->name("cccc"),
  );
  $rule->file;
  my $expected = [qw(
    aaaa.txt
    bbbb.txt
  )];
  @files = map { $_->relative($td)->as_foreign("Unix")->stringify } $rule->all($td);
  cmp_deeply( \@files, $expected, "skip() test")
    or diag explain { got => \@files, expected => $expected };
}

done_testing;
#
# This file is part of Path-Class-Rule
#
# This software is Copyright (c) 2011 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
