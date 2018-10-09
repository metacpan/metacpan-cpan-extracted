#!/usr/bin/perl

# Load testing for Object::Signature

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

use_ok('Object::Signature'      );
use_ok('Object::Signature::File');
