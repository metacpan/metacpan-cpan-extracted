#!perl

use strict;
use warnings;

use Test::More tests => 4;

use Paginator::Lite;

my ( $args, $pag, $params );


$params = 'foobar';

$args = {
    base_url    => '/foo/bar',
    curr        => 3,
    frame_size  => 5,
    items       => 65,
    page_size   => 10,
    params      => $params
};

$pag = Paginator::Lite->new( $args );

is_deeply( $pag->params, $params, 'Testing params as scalar' );

##############################################################################

$params = {
    foo => 1,
    bar => 2,
    baz => 42,
};

$args = {
    base_url    => '/foo/bar',
    curr        => 3,
    frame_size  => 5,
    items       => 65,
    page_size   => 10,
    params      => $params
};

$pag = Paginator::Lite->new( $args );

is_deeply( $pag->params, $params, 'Testing params as hashref' );

##############################################################################

$params = [ 1, 2, 3 ];

$args = {
    base_url    => '/foo/bar',
    curr        => 3,
    frame_size  => 5,
    items       => 65,
    page_size   => 10,
    params      => $params
};

$pag = Paginator::Lite->new( $args );

is_deeply( $pag->params, $params, 'Testing params as arrayref' );

##############################################################################

$params = undef;

$args = {
    base_url    => '/foo/bar',
    curr        => 3,
    frame_size  => 5,
    items       => 65,
    page_size   => 10,
    params      => $params
};

$pag = Paginator::Lite->new( $args );

is_deeply( $pag->params, $params, 'Testing params as undef' );

##############################################################################