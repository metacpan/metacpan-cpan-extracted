#!/usr/bin/perl

# Use a tag role which consumes a tag role in a class
package C2;
use Moo;
use R1;

has c2 => ( is => 'ro', t2 => sub { } );
1;
