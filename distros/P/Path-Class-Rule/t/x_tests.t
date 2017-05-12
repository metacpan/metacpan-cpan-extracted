use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use Path::Class;
use File::Temp;
use File::pushd qw/pushd/;

use lib 't/lib';
use PCNTest;

use Path::Class::Rule;

#--------------------------------------------------------------------------#

{
  my ($rule, @files);

  my $td = make_tree(qw(
    data/file1.txt
  ));

  my $file = file($td, 'data', 'file1.txt');
  
  # chmod a-rwx
  chmod 0777, $file;

  $rule = Path::Class::Rule->new->file;
  @files = ();
  @files = $rule->all($td);
  is( scalar @files, 1, "Any file") or diag explain \@files;

  $rule = Path::Class::Rule->new->file->readable;
  @files = ();
  @files = $rule->all($td);
  is( scalar @files, 1, "readable") or diag explain \@files;

  $rule = Path::Class::Rule->new->file->not_readable;
  @files = ();
  @files = $rule->all($td);
  is( scalar @files, 0, "not_readable") or diag explain \@files;

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
