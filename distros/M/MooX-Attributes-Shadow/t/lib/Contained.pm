package Contained;

use Moo;

has a => ( is => 'ro', default => sub { 'a' } );
has b => ( is => 'ro', default => sub { 'b' } );

1;

