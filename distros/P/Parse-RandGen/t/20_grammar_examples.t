#!/usr/bin/perl -w
# $Revision: #3 $$Date: 2005/08/12 $$Author: jd150722 $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2003-2005 by Jeff Dutton.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Data::Dumper;
use Test;
use vars qw(@TestREs $TestsPerRE);

BEGIN {
    plan tests => 1;
}
BEGIN { require "t/test_utils.pl"; }

use Parse::RandGen;


{   # README Example
    my $grammar = Parse::RandGen::Grammar->new("Filename");
    $grammar->defineRule("token")->set( prod=>[ cond=>qr/[a-zA-Z0-9_.]+/, ], );
    $grammar->defineRule("pathUnit")->set( prod=>[ cond=>"token", cond=>"'/'", ], );
    $grammar->defineRule("relativePath")->set( prod=>[ cond=>"pathUnit(*)", cond=>"token", ], );
    $grammar->defineRule("absolutePath")->set( prod=>[ cond=>"'/'", cond=>"pathUnit(*)", cond=>"token(?)", ], );
    $grammar->defineRule("path")->set( prod=>[ cond=>"absolutePath", ],
				       prod=>[ cond=>"relativePath", ],  );
    foreach my $i (0..100) {
	print "Here is a random path: <" . $grammar->rule("path")->pick() . ">\n";
    }
    print "\nPicking partially constrained paths...\n";
    foreach my $i (0..20) {
	print "Here is a random path: <" . $grammar->rule("path")->pick(vals=>{ token=>"foo", }) . ">\n";
    }
    ok(1);
}
