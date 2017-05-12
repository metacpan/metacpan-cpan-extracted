use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use File::Temp;
use Test::Deep qw/cmp_deeply/;
use File::pushd qw/pushd/;

use lib 't/lib';
use PCNTest;

use Path::Iterator::Rule;

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
    my $rule     = Path::Iterator::Rule->new->file->min_depth(3);
    my $expected = [
        qw(
          cccc/eeee/ffff.txt
          hhhh/iiii/jjjj/kkkk/llll/mmmm.txt
          )
    ];
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "min_depth(3) test" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my @files;
    my $rule     = Path::Iterator::Rule->new->max_depth(2)->file;
    my $expected = [
        qw(
          aaaa.txt
          bbbb.txt
          gggg.txt
          cccc/dddd.txt
          )
    ];
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "max_depth(2) test" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my @files;
    my $rule     = Path::Iterator::Rule->new->file->min_depth(2)->max_depth(3);
    my $expected = [
        qw(
          cccc/dddd.txt
          cccc/eeee/ffff.txt
          )
    ];
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "min_depth(2)->max_depth(3) test" )
      or diag explain { got => \@files, expected => $expected };
}
done_testing;
#
# This file is part of Path-Iterator-Rule
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
