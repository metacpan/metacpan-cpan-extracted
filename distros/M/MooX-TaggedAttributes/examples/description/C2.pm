#!/usr/bin/perl
package C2;
use Moo;
use T12;

has c2 => ( is => 'ro', t1 => 'foo', t2 => 'bar' );
1;
