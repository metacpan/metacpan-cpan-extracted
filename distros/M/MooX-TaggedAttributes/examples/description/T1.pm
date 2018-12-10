#!/usr/bin/perl

package T1;
use Moo::Role;
use MooX::TaggedAttributes -tags => [ 't1' ];

has a1 => ( is => 'ro', t1 => 'foo' );

1;
