#!/usr/bin/perl
# define a Tag Role
package T1;
use Moo::Role;

use MooX::TaggedAttributes -tags => [qw( t1 t2 )], -propagate;
1;
