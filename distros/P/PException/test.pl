# -*- cperl -*-
#
# Copyright (c) 1997-2003 Samuel    MOUNIEE
#
#    This file is part of PException.
#
#    PException is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    PException is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with PException; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use PException;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$|	= 1;

package Ex1;
@ISA	= qw( PException );

package Ex2;
@ISA	= qw( PException );

package Ex3;
@ISA	= qw( PException );

sub	handleException	{ print "ok ${$_[0]}\n" }

package Ex4;
@ISA	= qw( PException );

sub	handleException	{ print "ok ${$_[0]}\n" }

package main;


try {
  throw( new Ex1( 2 ) );
  print "ko 2\n";
}
catch	Ex1( sub { print "ok ${$_[0]}\n" } );


try {
  throw( new Ex1( 3 ), new Ex2( 4 ) );
  print "ko 3\n";
  print "ko 4\n";
}
catch	Ex1( sub { print "ok ${$_[0]}\n" } ),
catch	Ex2( sub { print "ok ${$_[0]}\n" } );


try {
  try {
	throw( new Ex1( 5 ) );
	print "ko 5\n";
  };
  throw( new Ex2( 6 ) );
  print "ko 6\n";
}
onfly	Ex1( sub { print "ok ${$_[0]}\n" } ),
catch	Ex2( sub { print "ok ${$_[0]}\n" } );


try {
  throw( new Ex3( 7 ) );
  print "ko 7\n";
}
catch	Ex3();

addFlyingHandler Ex4();

try {
  try {
	throw( new Ex4( 8 ) );
  };
  throw( new Ex3( 9 ) );
  print "ko 8\n";
  print "ko 9\n";
}
catch	Ex3();
