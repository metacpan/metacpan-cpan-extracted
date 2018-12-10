#!/usr/bin/perl
package R2;
use Moo::Role;
use T1;

has r2 => ( is => 'ro', t1 => 'foo' );
1;
