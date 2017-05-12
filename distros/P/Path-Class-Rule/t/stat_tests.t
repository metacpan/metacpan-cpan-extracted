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

sub copy {
  my ($src, $dst) = @_;
  open my $fh, ">", $dst;
  print {$fh} do { local (@ARGV, $/) = $src; <> };
}

#--------------------------------------------------------------------------#

{
  my ($rule, @files);

  my $td = make_tree(qw(
    data/file1.txt
  ));

  my $changes = file($td, 'data', 'Changes');

  copy( file('Changes'), $changes );
  
  $rule = Path::Class::Rule->new->file;

  @files = ();
  @files = $rule->all($td);
  is( scalar @files, 2, "Any file") or diag explain \@files;

  $rule = Path::Class::Rule->new->file->size(">0k");
  @files = ();
  @files = $rule->all($td);
  is( $files[0], $changes, "size > 0") or diag explain \@files;

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
