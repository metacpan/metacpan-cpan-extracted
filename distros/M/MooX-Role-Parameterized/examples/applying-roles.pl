use v5.12;
use strict;
use warnings;

package KeyValue;

use Moo::Role;
use MooX::Role::Parameterized;

parameter attr   => ( is => 'ro', required => 1 );
parameter method => ( is => 'ro', required => 1 );

role {
    my ( $params, $mop ) = @_;

    $mop->has( $params->attr => ( is => 'rw' ) );
    $mop->method( $params->method => sub {1024} );
};

package Widget;

use Moo;
use MooX::Role::Parameterized::With;

with KeyValue => [
    { attr => 'width',  method => 'compute_width' },
    { attr => 'height', method => 'compute_height' },
  ],
  KeyValue => { attr => 'depth', method => 'compute_depth' };

has name => ( is => 'ro' );

package main;
use feature 'say';

my $widget = Widget->new(
    name   => 'box',
    width  => 10,
    height => 20,
    depth  => 30,
);

say 'name:   ',           $widget->name;
say 'width:  ',           $widget->width;
say 'height: ',           $widget->height;
say 'depth:  ',           $widget->depth;
say 'compute_width  => ', $widget->compute_width;
say 'compute_height => ', $widget->compute_height;
say 'compute_depth  => ', $widget->compute_depth;
