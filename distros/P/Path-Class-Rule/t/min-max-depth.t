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
  hhhh/iiii/jjjj/kkkk/llll/mmmm.txt
);

my $td = make_tree(@tree);

{
  my @files;
  my $rule = Path::Class::Rule->new->file->min_depth(3);
  my $expected = [ qw(
    cccc/eeee/ffff.txt
    hhhh/iiii/jjjj/kkkk/llll/mmmm.txt
  )];
  @files = map { $_->relative($td)->as_foreign("Unix")->stringify } $rule->all($td);
  cmp_deeply( \@files, $expected, "min_depth(3) test")
    or diag explain { got => \@files, expected => $expected };
}

{
  my @files;
  my $rule = Path::Class::Rule->new->file->max_depth(2);
  my $expected = [ qw(
    aaaa.txt
    bbbb.txt
    gggg.txt
    cccc/dddd.txt
  )];
  @files = map { $_->relative($td)->as_foreign("Unix")->stringify } $rule->all($td);
  cmp_deeply( \@files, $expected, "max_depth(2) test")
    or diag explain { got => \@files, expected => $expected };
}

{
  my @files;
  my $rule = Path::Class::Rule->new->file->min_depth(2)->max_depth(3);
  my $expected = [ qw(
    cccc/dddd.txt
    cccc/eeee/ffff.txt
  )];
  @files = map { $_->relative($td)->as_foreign("Unix")->stringify } $rule->all($td);
  cmp_deeply( \@files, $expected, "min_depth(2)->max_depth(3) test")
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
