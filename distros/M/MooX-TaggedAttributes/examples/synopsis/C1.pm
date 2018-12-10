#!/usr/bin/perl
# Apply a tag role directly to a class
package C1;
use Moo;
use T1;

has c1 => ( is => 'ro', t1 => 1 );
1;
