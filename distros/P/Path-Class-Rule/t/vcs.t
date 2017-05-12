use 5.006;
use strict;
use warnings;
use autodie;
use Test::More 0.92;
use Path::Class;
use File::Temp;
use Test::Deep qw/cmp_deeply/;

use lib 't/lib';
use PCNTest;

use Path::Class::Rule;

#--------------------------------------------------------------------------#

my @tree = qw(
  aaaa.txt
  bbbb.txt
  cccc/.svn/foo
  cccc/.bzr/foo
  cccc/.git/foo
  cccc/.hg/foo
  cccc/CVS/foo
  cccc/RCS/foo
);

push @tree, 'eeee/foo,v', 'dddd/foo.#'; # avoids warning about stuff in qw

  
my $td = make_tree(@tree);

{
  my @files;
  my $rule = Path::Class::Rule->new->skip_vcs->file;
  my $expected = [ qw(
    aaaa.txt
    bbbb.txt
  )];
  @files = map { $_->relative($td)->as_foreign("Unix")->stringify } $rule->all($td);
  cmp_deeply( \@files, $expected, "not_vcs test")
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
