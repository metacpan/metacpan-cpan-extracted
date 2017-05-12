#!/usr/bin/perl -w
# $Revision: #3 $$Date: 2005/07/19 $$Author: jd150722 $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2003-2005 by Jeff Dutton.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Data::Dumper;
use Test;

BEGIN { plan tests => 2; }
BEGIN { require "t/test_utils.pl"; }

use Parse::RandGen;
ok(1);

# This test file contains the little standalone examples from the manual

{
    my $reObj = Parse::RandGen::Regexp->new( qr/foo(bar|baz)/ );
    print "Here is some random data that satisfies the RE:     <" . $reObj->pick() . ">\n";
    print "Here is some that (hopefully) doesn't match the RE: <" . $reObj->pick(match=>0) . ">\n";
    ok(1);
}
