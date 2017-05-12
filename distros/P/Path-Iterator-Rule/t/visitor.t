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

{
    my @tree = qw(
      aaaa.txt
      bbbb.txt
      cccc/dddd.txt
      cccc/eeee/ffff.txt
      gggg.txt
    );

    my @depth_pre = qw(
      aaaa.txt
      bbbb.txt
      cccc/dddd.txt
      cccc/eeee/ffff.txt
      gggg.txt
    );

    my @breadth = qw(
      aaaa.txt
      bbbb.txt
      gggg.txt
      cccc/dddd.txt
      cccc/eeee/ffff.txt
    );

    my $td = make_tree(@tree);

    my ( $iter, @files );
    my $rule = Path::Iterator::Rule->new->file;

    $rule->all( $td,
        { visitor => sub { push @files, unixify( $_, $td ) }, depthfirst => -1 } );

    cmp_deeply( \@files, \@depth_pre, "Visitor (depth)" )
      or diag explain \@files;

    @files = ();

    $rule->all(
        $td,
        {
            visitor => sub { push @files, unixify( $_, $td ) }
        }
    );

    cmp_deeply( \@files, \@breadth, "Visitor (breadth)" )
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

