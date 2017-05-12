use 5.006;
use strict;
use warnings;
use autodie;
use Test::More 0.92;
use Path::Class;
use File::Temp;
use Test::Deep qw/cmp_deeply/;
use File::pushd qw/pushd/;
use Config;

use lib 't/lib';
use PCNTest;

use Path::Class::Rule;

#--------------------------------------------------------------------------#

plan skip_all => "No symlink support"
  unless $Config{d_symlink};

#--------------------------------------------------------------------------#

{
  my @tree = qw(
    aaaa.txt
    bbbb.txt
    cccc/dddd.txt
    cccc/eeee/ffff.txt
    gggg.txt
  );

  my @follow = qw(
    .
    aaaa.txt
    bbbb.txt
    cccc
    gggg.txt
    pppp
    qqqq.txt
    cccc/dddd.txt
    cccc/eeee
    pppp/ffff.txt
  );

  my @nofollow = qw(
    .
    aaaa.txt
    bbbb.txt
    cccc
    gggg.txt
    cccc/dddd.txt
    cccc/eeee
    cccc/eeee/ffff.txt
  );

  my $td = make_tree(@tree);

  symlink dir($td,'cccc','eeee'), dir($td,'pppp');
  symlink file($td,'aaaa.txt'), file($td,'qqqq.txt');

  my ($iter, @files);
  my $rule = Path::Class::Rule->new;

  @files = map  { $_->relative($td)->as_foreign("Unix")->stringify }
                $rule->all($td);
  cmp_deeply( \@files, \@follow, "Follow symlinks")
    or diag explain { got => \@files, expected => \@follow };

  @files = map  { $_->relative($td)->as_foreign("Unix")->stringify }
                $rule->all({follow_symlinks => 0}, $td);
  cmp_deeply( \@files, \@nofollow, "Don't follow symlinks")
    or diag explain { got => \@files, expected => \@nofollow };

}

{
  my @tree = qw(
    aaaa.txt
    bbbb.txt
    cccc/dddd.txt
  );

  my $td = make_tree(@tree);

  symlink dir($td,'zzzz'), dir($td,'pppp'); # dangling symlink
  symlink dir($td,'cccc', 'dddd.txt'), dir($td,'qqqq.txt'); # regular symlink

  my @dangling = qw(
    pppp
  );

  my @not_dangling = qw(
    .
    aaaa.txt
    bbbb.txt
    cccc
    qqqq.txt
    cccc/dddd.txt
  );

  my @valid_symlinks = qw(
    qqqq.txt
  );

  my ($rule, @files);

  $rule = Path::Class::Rule->new->dangling;
  @files = map  { $_->relative($td)->as_foreign("Unix")->stringify }
                $rule->all($td);
  cmp_deeply( \@files, \@dangling, "Dangling symlinks")
    or diag explain { got => \@files, expected => \@dangling };

  $rule = Path::Class::Rule->new->not_dangling;
  @files = map  { $_->relative($td)->as_foreign("Unix")->stringify }
                $rule->all($td);
  cmp_deeply( \@files, \@not_dangling, "No dangling symlinks")
    or diag explain { got => \@files, expected => \@not_dangling };

  $rule = Path::Class::Rule->new->symlink->not_dangling;
  @files = map  { $_->relative($td)->as_foreign("Unix")->stringify }
                $rule->all($td);
  cmp_deeply( \@files, \@valid_symlinks, "Only non-dangling symlinks")
    or diag explain { got => \@files, expected => \@valid_symlinks };

}

{
  my @tree = qw(
    aaaa.txt
    bbbb.txt
    cccc/dddd.txt
  );

  my $td = make_tree(@tree);

  symlink dir($td,'cccc'), dir($td,'cccc','eeee'); # symlink loop

  my @expected = qw(
    .
    aaaa.txt
    bbbb.txt
    cccc
    cccc/dddd.txt
    cccc/eeee
  );

  my ($rule, @files);

  $rule = Path::Class::Rule->new;
  @files = map  { $_->relative($td)->as_foreign("Unix")->stringify } $rule->all($td);
  cmp_deeply( \@files, \@expected, "Symlink loop")
    or diag explain { got => \@files, expected => \@expected };
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
