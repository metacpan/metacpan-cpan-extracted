#!/usr/bin/perl -w
use strict;
use Test::More tests => 4;
use Pod::Coverage ();

my $pc = Pod::Coverage->new();
isa_ok( $pc, 'Pod::Coverage' );

package wibble;
sub bar {};
package main;
sub foo {}
sub baz::baz {};
*bar = \&wibble::bar;
*baz = \&baz::baz;

is ( $pc->_CvGV(\&foo), '*main::foo',   'foo checks out' );
is ( $pc->_CvGV(\&bar), '*wibble::bar', 'bar looks right' );
is ( $pc->_CvGV(\&baz), '*baz::baz',    'baz too' );
