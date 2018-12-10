#!/usr/bin/perl
package C;
use Moo;
use T;

has a => ( is => 'ro', t1 => 2 );
has b => ( is => 'ro', t2 => 'foo' );
1;
