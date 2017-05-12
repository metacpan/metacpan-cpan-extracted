use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use Path::Class;
use File::Temp;
use Test::Deep qw/cmp_deeply/;
use File::pushd qw/pushd/;

use lib 't/lib';
use PCNTest;

use Path::Class::Rule;

#--------------------------------------------------------------------------#

{
  my @tree = qw(
    aaaa.txt
    bbbb.txt
    cccc/dddd.txt
    cccc/eeee/ffff.txt
    gggg.txt
  );

  my @breadth = qw(
    .
    aaaa.txt
    bbbb.txt
    cccc
    gggg.txt
    cccc/dddd.txt
    cccc/eeee
    cccc/eeee/ffff.txt
  );
  
  my @depth_pre = qw(
    .
    aaaa.txt
    bbbb.txt
    cccc
    cccc/dddd.txt
    cccc/eeee
    cccc/eeee/ffff.txt
    gggg.txt
  );

  my @depth_post = qw(
    aaaa.txt
    bbbb.txt
    cccc/dddd.txt
    cccc/eeee/ffff.txt
    cccc/eeee
    cccc
    gggg.txt
    .
  );

  my $td = make_tree(@tree);

  my ($iter, @files);
  my $rule = Path::Class::Rule->new;

  @files = map  { $_->relative($td)->as_foreign("Unix")->stringify }
                $rule->all({depthfirst => 0}, $td);
  cmp_deeply( \@files, \@breadth, "Breadth first iteration")
    or diag explain \@files;

  @files = map  { $_->relative($td)->as_foreign("Unix")->stringify }
                $rule->all({depthfirst => -1}, $td);
  cmp_deeply( \@files, \@depth_pre, "Depth first iteration (pre)")
    or diag explain \@files;

  @files = map  { $_->relative($td)->as_foreign("Unix")->stringify }
                $rule->all({depthfirst => 1}, $td);
  cmp_deeply( \@files, \@depth_post, "Depth first iteration (post)")
    or diag explain \@files;

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
