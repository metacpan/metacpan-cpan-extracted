#!/usr/bin/perl -w
# $Revision: #5 $$Date: 2005/08/31 $$Author: jd150722 $
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
    $TestsPerRE = 100;  # Number of random strings chosen and tested for each regular expression
    @TestREs = ( 
		 qr/foo(bar|baz){3}/,
		 qr'[\-\_\.\!\~\*\'\(\)]+',
		 qr"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}",
		 qr"don't mess with texas!"i,
		 qr/^cacaw$/i,
		 qr/^Hello{3,}! La la la!$/,
		 qr/^X{2,3}$/,
		 qr/  Spaces    \s   Don\'t  \s  Matter/x,
		 qr/fo?oz/,
		 qr/^STOR\s[^\n]{20}/smi,
		 qr//,   # FIX

		 # To detect quant problems
		 qr/[a-z]{10}/,
		 qr/[a-z]{40,}/,
		 qr/[a-z]{10,20}/,
		 qr/([0-9]{7}){3}/,
		 qr/([0-9]){40,}/,
		 qr/([0-9]{40,}){3,}/,
		 qr/([0-9]{7,10}){3,5}/,

		 # misc REs taken from the Snort rules.
		 qr/^SITE\s+EXEC\s[^\n]*?%[^\n]*?%/,
		 qr/^HEAD[^s]{432}/,
		 qr/^.{27}/,
		 qr/^\x00.{3}\xFFSMB(\x73|\x74|\x75|\xa2|\x24|\x2d|\x2e|\x2f).{28}(\x73|\x74|\x75|\xa2|\x24|\x2d|\x2e|\x2f)/,
		 qr/^Max-dotdot[\s\r\n]*\d{3,}/,

		 # Subrule tests (created from using parentheses)
		 qr/ ((([a-z]){2,} | ([0-9]){3,}) \x20){6} \w+\./x,
		 qr/(((\d)\.){20,})(((\d))){1,2}/,
		 qr/((((S))))+(((t)+))((((((u))+))))((((d{2,}))))(((((e)))+))((((((r)))))+)/,
		 );

    plan tests => ($#TestREs+1);
}
BEGIN { require "t/test_utils.pl"; }

use Parse::RandGen;
$Parse::RandGen::Debug = 1;

foreach my $testRE (@TestREs) {
    my $re = Parse::RandGen::Regexp->new($testRE);
    my $error = "";

  TEST_LOOP:
    foreach my $doMatch (1, 0) {
	for (my $i=0; $i<$TestsPerRE; $i++) {
	    my $data = $re->pick(match=>$doMatch);
	    my $matches = ($data =~ qr/^$testRE$/)?1:0;

	    # Use Data Dumper to get readable data (sometimes funky characters are used)
	    my $d = Data::Dumper->new([$data]);
	    $d->Terse(1)->Indent(0)->Useqq(1);
	    my $dispData = $d->Dump();

	    if (($matches == $doMatch)
		|| !$doMatch #FIX - currently unable to guarantee a mismatch...  You can always get lucky ;-)
		) {
		printf("Success: %-20s regexp picked a %-6s for the input %s%s\n",
		       $testRE, ($doMatch?"MATCH":"MISS"), $dispData, ((!$doMatch&&$matches)?"  (the pick was for a MISS, but you can never be sure)":""));
	    } else {
		$error = sprintf("%%Error: %-20s regexp picked a %-6s for the input %s!\n",
				 $testRE, ($doMatch?"MATCH":"MISS"), $dispData);
		last TEST_LOOP;
	    }
	}
    }
    warn("\n\n$error\n\n") if $error;
    ok(!$error);
}
