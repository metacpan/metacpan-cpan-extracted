######################### -*- Mode: Perl -*- #########################
##
## File          : $RCSfile: reprec.t,v $
##
## Author        : Norbert Gövert
## Created On    : Mon Nov  9 16:04:27 1998
## Last Modified : Time-stamp: <2000-12-11 23:40:47 goevert>
##
## Description   : regression tests for RePrec
##
## $Id: reprec.t,v 1.29 2003/06/13 12:29:30 goevert Exp $
##
######################################################################


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;

use Test;

######################### We start with some black magic to print on failure.

# Change `plan tests => 1' below to `plan tests => last_test_to_print'.
our $loaded;
BEGIN { $| = 1; plan tests => 1; }
END   { ok(0) unless $loaded; }
require RePrec;
require RePrec;
require RePrec::PRR;
require RePrec::Average;
require RePrec::Searchresult;
require RePrec::Collection;
$loaded = 1;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

