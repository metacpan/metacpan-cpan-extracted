use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use File::Temp;
use Test::Deep qw/cmp_deeply/;
use File::pushd qw/pushd/;

use lib 't/lib';
use PCNTest;
use PIRTiny;

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

    my $td = make_tree(@tree);

    my ( $iter, @files );
    my $rule = PIRTiny->new;

    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, \@breadth, "Object-based subclass (all)" )
      or diag explain \@files;

    @files = map { unixify( $_, $td ) } $rule->all_fast($td);
    cmp_deeply( [ sort @files ], [ sort @breadth ], "Object-based subclass (all_fast)" )
      or diag explain \@files;

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
