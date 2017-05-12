use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use Path::Tiny;
use File::Temp;
use Test::Deep qw/cmp_deeply/;
use File::pushd qw/pushd/;
use Config;

use lib 't/lib';
use PCNTest;

use Path::Iterator::Rule;

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

    my @not_loop_safe = qw(
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
      cccc/eeee/ffff.txt
    );

    my @nofollow_report = qw(
      .
      aaaa.txt
      bbbb.txt
      cccc
      gggg.txt
      pppp
      qqqq.txt
      cccc/dddd.txt
      cccc/eeee
      cccc/eeee/ffff.txt
    );

    my @nofollow_noreport = qw(
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

    symlink path( $td, 'cccc', 'eeee' ), path( $td, 'pppp' );
    symlink path( $td, 'aaaa.txt' ), path( $td, 'qqqq.txt' );

    my ( $iter, @files );
    my $rule = Path::Iterator::Rule->new;

    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, \@follow, "Follow symlinks" )
      or diag explain { got => \@files, expected => \@follow };

    @files = map { unixify( $_, $td ) } $rule->all( $td, { loop_safe => 0 } );
    cmp_deeply( \@files, \@not_loop_safe, "Follow symlinks, but loop_safe = 0" )
      or diag explain { got => \@files, expected => \@not_loop_safe };

    @files = map { unixify( $_, $td ) }
      $rule->all( { follow_symlinks => 0, report_symlinks => 1 }, $td );
    cmp_deeply( \@files, \@nofollow_report, "Don't follow symlinks, but report them" )
      or diag explain { got => \@files, expected => \@nofollow_report };

    @files = map { unixify( $_, $td ) }
      $rule->all( { follow_symlinks => 0, report_symlinks => 0 }, $td );
    cmp_deeply( \@files, \@nofollow_noreport, "Don't follow or report symlinks" )
      or diag explain { got => \@files, expected => \@nofollow_noreport };

}

{
    my @tree = qw(
      aaaa.txt
      bbbb.txt
      cccc/dddd.txt
    );

    my $td = make_tree(@tree);

    symlink path( $td, 'zzzz' ), path( $td, 'pppp' ); # dangling symlink
    symlink path( $td, 'cccc', 'dddd.txt' ), path( $td, 'qqqq.txt' ); # regular symlink

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

    my ( $rule, @files );

    $rule = Path::Iterator::Rule->new->dangling;
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, \@dangling, "Dangling symlinks" )
      or diag explain { got => \@files, expected => \@dangling };

    $rule = Path::Iterator::Rule->new->not_dangling;
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, \@not_dangling, "No dangling symlinks" )
      or diag explain { got => \@files, expected => \@not_dangling };

    $rule = Path::Iterator::Rule->new->symlink->not_dangling;
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, \@valid_symlinks, "Only non-dangling symlinks" )
      or diag explain { got => \@files, expected => \@valid_symlinks };

}

{
    my @tree = qw(
      aaaa.txt
      bbbb.txt
      cccc/dddd.txt
    );

    my $td = make_tree(@tree);

    symlink path( $td, 'cccc' ), path( $td, 'cccc', 'eeee' ); # symlink loop

    my @expected = qw(
      .
      aaaa.txt
      bbbb.txt
      cccc
      cccc/dddd.txt
      cccc/eeee
    );

    my ( $rule, @files );

    $rule = Path::Iterator::Rule->new;
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, \@expected, "Symlink loop" )
      or diag explain { got => \@files, expected => \@expected };
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
