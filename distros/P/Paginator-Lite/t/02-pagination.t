#!perl

use strict;
use warnings;

use Test::More tests => 5;

use Paginator::Lite;

my ( $args, $pag, $got, $expected );


$args = {
    base_url    => '/foo/bar',
    curr        => 3,
    frame_size  => 5,
    items       => 65,
    page_size   => 10,
};

$expected = {
    first       => 1,
    last        => 7,
    begin       => 1,
    end         => 5,
    base_url    => '/foo/bar',
    curr        => 3,
    frame_size  => 5,
    page_size   => 10,
    items       => 65,
    calc_frame  => 5,
};

$pag = Paginator::Lite->new( $args );

$got = {
    first       => $pag->first,
    last        => $pag->last,
    begin       => $pag->begin,
    end         => $pag->end,
    base_url    => $pag->base_url,
    curr        => $pag->curr,
    frame_size  => $pag->frame_size,
    page_size   => $pag->page_size,
    items       => $pag->items,
    calc_frame  => $pag->end - $pag->begin + 1,
};

is_deeply( $got, $expected, 'Testing normal input' );

##############################################################################

$args = {
    base_url    => '/foo/bar',
    curr        => 1,
    frame_size  => 5,
    items       => 65,
    page_size   => 10,
};

$expected = {
    first       => 1,
    last        => 7,
    begin       => 1,
    end         => 3,
    base_url    => '/foo/bar',
    curr        => 1,
    frame_size  => 5,
    page_size   => 10,
    items       => 65,
    calc_frame  => 3,
};

$pag = Paginator::Lite->new( $args );

$got = {
    first       => $pag->first,
    last        => $pag->last,
    begin       => $pag->begin,
    end         => $pag->end,
    base_url    => $pag->base_url,
    curr        => $pag->curr,
    frame_size  => $pag->frame_size,
    page_size   => $pag->page_size,
    items       => $pag->items,
    calc_frame  => $pag->end - $pag->begin + 1,
};

is_deeply( $got, $expected, 'Testing curr as first page' );

##############################################################################

$args = {
    base_url    => '/foo/bar',
    curr        => 7,
    frame_size  => 5,
    items       => 65,
    page_size   => 10,
};

$expected = {
    first       => 1,
    last        => 7,
    begin       => 5,
    end         => 7,
    base_url    => '/foo/bar',
    curr        => 7,
    frame_size  => 5,
    page_size   => 10,
    items       => 65,
    calc_frame  => 3,
};

$pag = Paginator::Lite->new( $args );

$got = {
    first       => $pag->first,
    last        => $pag->last,
    begin       => $pag->begin,
    end         => $pag->end,
    base_url    => $pag->base_url,
    curr        => $pag->curr,
    frame_size  => $pag->frame_size,
    page_size   => $pag->page_size,
    items       => $pag->items,
    calc_frame  => $pag->end - $pag->begin + 1,
};

is_deeply( $got, $expected, 'Testing curr as last page' );

##############################################################################

$args = {
    base_url    => '/foo/bar',
    curr        => 7,
    frame_size  => 5,
    items       => 1,
    page_size   => 10,
};

$expected = {
    first       => 1,
    last        => 1,
    begin       => 1,
    end         => 1,
    base_url    => '/foo/bar',
    curr        => 1,
    frame_size  => 5,
    page_size   => 10,
    items       => 1,
    calc_frame  => 1,
};

$pag = Paginator::Lite->new( $args );

$got = {
    first       => $pag->first,
    last        => $pag->last,
    begin       => $pag->begin,
    end         => $pag->end,
    base_url    => $pag->base_url,
    curr        => $pag->curr,
    frame_size  => $pag->frame_size,
    page_size   => $pag->page_size,
    items       => $pag->items,
    calc_frame  => $pag->end - $pag->begin + 1,
};

is_deeply( $got, $expected, 'Testing few items' );

##############################################################################

$args = {
    base_url    => '/foo/bar',
    curr        => 3,
    frame_size  => 0,
    items       => 65,
    page_size   => 10,
};

$expected = {
    first       => 1,
    last        => 7,
    begin       => 0,
    end         => -1,
    base_url    => '/foo/bar',
    curr        => 3,
    frame_size  => 0,
    page_size   => 10,
    items       => 65,
    calc_frame  => 0,
};

$pag = Paginator::Lite->new( $args );

$got = {
    first       => $pag->first,
    last        => $pag->last,
    begin       => $pag->begin,
    end         => $pag->end,
    base_url    => $pag->base_url,
    curr        => $pag->curr,
    frame_size  => $pag->frame_size,
    page_size   => $pag->page_size,
    items       => $pag->items,
    calc_frame  => $pag->end - $pag->begin + 1,
};

is_deeply( $got, $expected, 'Testing frame_size = 0' );

##############################################################################