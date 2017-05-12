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
      gggg.txt
      cccc.txt
      dddd.txt
      bbbb.txt
      eeee.txt
    );

    my $td = make_tree(@tree);

    opendir( my $dh, "$td" );
    my @expected = ( grep { $_ ne "." && $_ ne ".." } readdir $dh );
    closedir $dh;

    my ( $iter, @files );
    my $rule = Path::Iterator::Rule->new->file;

    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, [ sort @expected ], "all() gives sorted order" )
      or diag explain \@files;

    @files = map { unixify( $_, $td ) } $rule->all_fast($td);
    cmp_deeply( \@files, \@expected, "all_fast() gives disk order" )
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
