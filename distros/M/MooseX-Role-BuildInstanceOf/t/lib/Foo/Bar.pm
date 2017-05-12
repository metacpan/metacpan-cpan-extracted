package Foo::Bar;

use strict;
use warnings;

use Moose;

has [ qw/ thingy that parent / ] => ( is => 'ro' );

1;

