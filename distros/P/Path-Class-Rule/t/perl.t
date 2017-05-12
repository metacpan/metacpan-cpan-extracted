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
  lib/Foo.pm
  lib/Foo.pod
  t/test.t
);

my @bin = qw(
  bin/foo.pl
  bin/foo
  bin/bar
);

my $td = make_tree(@tree, @bin);

for my $f ( map { file($td, $_) } @bin ) {
  next if $f =~ /foo\.pl/;
  my $fh = $f->openw;
  print {$fh} ( $f =~ 'bin/bar' ? "#!/usr/bin/env perl\n" : "#!/usr/bin/perl\n");
  $fh->close;
}

{
  my @files;
  my $rule = Path::Class::Rule->new->perl_file;
  my $expected = [ qw(
    bin/bar
    bin/foo
    bin/foo.pl
    lib/Foo.pm
    lib/Foo.pod
    t/test.t
  )];
  @files = map { $_->relative($td)->as_foreign("Unix")->stringify } $rule->all($td);
  cmp_deeply( \@files, $expected, "all perl files")
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
