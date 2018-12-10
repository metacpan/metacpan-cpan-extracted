#!/usr/bin/perl
package T2;
use Moo::Role;
use MooX::TaggedAttributes -tags => 't2';

has a2 => ( is => 'ro', t2 => 'bar' );

1;
