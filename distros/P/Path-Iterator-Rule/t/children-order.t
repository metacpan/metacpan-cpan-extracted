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

{

    package CheckOrder;

    use parent 'Path::Iterator::Rule';
    use PCNTest;

    our $order;
    our $td;

    sub new {
        ( my $class, $td, $order ) = @_;
        $class->SUPER::new();
    }

    sub _children {
        my $self = shift;
        my $path = "" . shift;

        push @$order, 'children:' . unixify( $path, $td );

        opendir( my $dh, $path );
        return map { [ $_, "$path/$_" ] }
          grep { $_ ne "." && $_ ne ".." } readdir $dh;
    }

}

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
      visit:.
      children:.
      visit:aaaa.txt
      visit:bbbb.txt
      visit:cccc
      visit:gggg.txt
      children:cccc
      visit:cccc/dddd.txt
      visit:cccc/eeee
      children:cccc/eeee
      visit:cccc/eeee/ffff.txt
    );

    my @depth_pre = qw(
      visit:.
      children:.
      visit:aaaa.txt
      visit:bbbb.txt
      visit:cccc
      children:cccc
      visit:cccc/dddd.txt
      visit:cccc/eeee
      children:cccc/eeee
      visit:cccc/eeee/ffff.txt
      visit:gggg.txt
    );

    my $td = make_tree(@tree);

    my ( $iter, @order );
    my $rule = CheckOrder->new( $td, \@order );

    @order = ();
    my $visitor = sub {
        push @order, 'visit:' . unixify( $_, $td );
    };

    $rule->all( { depthfirst => 0, visitor => $visitor }, $td );
    cmp_deeply( \@order, \@breadth, "Breadth first iteration" )
      or diag explain \@order;

    @order = ();
    $rule->all( { depthfirst => -1, visitor => $visitor }, $td );
    cmp_deeply( \@order, \@depth_pre, "Depth first iteration (pre)" )
      or diag explain \@order;

    @order = ();
    $rule->all( { depthfirst => 1, visitor => $visitor }, $td );

    # post and pre have same visit/children pattern
    cmp_deeply( \@order, \@depth_pre, "Depth first iteration (post)" )
      or diag explain \@order;
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
