#!/usr/bin/perl
package C1;
use Moo;
use T1;

has c1 => ( is => 'ro', t1 => 'foo' );
1;
