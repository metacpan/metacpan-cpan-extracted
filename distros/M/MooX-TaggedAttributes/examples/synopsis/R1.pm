#!/usr/bin/perl
# use a tag role in another Role
package R1;

use Moo::Role;
use T1;

has r1 => ( is => 'ro', t2 => 2 );
1;
