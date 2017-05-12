#!/usr/bin/perl  -sw 
# Test script for Zone functionalty
# $Id: 03-failures.t 726 2008-09-16 10:33:27Z olaf $
# 
# Called in a fashion simmilar to:
# /usr/bin/perl -Iblib/arch -Iblib/lib -I/usr/lib/perl5/5.6.1/i386-freebsd \
# -I/usr/lib/perl5/5.6.1 -e 'use Test::Harness qw(&runtests $verbose); \
# $verbose=0; runtests @ARGV;' t/01-zonetest.t

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test::More;
use strict;





use Net::DNS::Zone::Parser;

my $runs=1;
$runs=2 if $Net::DNS::Zone::Parser::NAMED_CHECKZONE;
plan tests=>$runs*4;
my $run=0;
while ($run<$runs){
    $Net::DNS::Zone::Parser::NAMED_CHECKZONE=0 if $run==1;
    $run++;   
# Create a new object
    my $parser = Net::DNS::Zone::Parser->new();
    ok( defined($parser), "Parser object creation");                        
    
    like( $parser->read("t/test.db.recurse1",{ ORIGIN=> "foo.test"}),
	  "/^READ FAILURE:.* too many open files/",
	  "Nested INCLUDE error returned");
    
    
    like  ($parser->read("t/test.db.brokenRR",{ ORIGIN=> "foo.test"}),
	   "/^READ FAILURE:.* unknown class/type/"
	   ,"Regular Expression of RR fails");
    
    
    like ($parser->read("t/test.db.brokenbrackets",{ ORIGIN=> "foo.test"}),
	  '/^READ FAILURE:.*unbalanced parentheses/'
	  ,"Multiple opening brackets error");
}
