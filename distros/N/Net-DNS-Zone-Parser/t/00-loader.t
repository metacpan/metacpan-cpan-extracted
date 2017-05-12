#!/usr/bin/perl  -sw 
# Test script for loading parser and zonemodules
# $Id: 00-loader.t 454 2005-07-06 13:38:31Z olaf $
# 
# Called in a fashion simmilar to:
# /usr/bin/perl -Iblib/arch -Iblib/lib -I/usr/lib/perl5/5.6.1/i386-freebsd \
# -I/usr/lib/perl5/5.6.1 -e 'use Test::Harness qw(&runtests $verbose); \
# $verbose=0; runtests @ARGV;' t/<foo>

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.


use Test::More tests=>2;
use strict;

#use Data::Dumper;
BEGIN {use_ok('Net::DNS::Zone::Parser', qw(processGENERATEarg));


      }                                 # test 1



require_ok('Net::DNS::Zone::Parser');


diag("\nThese tests were ran with:\n");
diag("Net::DNS::VERSION:               ".$Net::DNS::VERSION);
diag("Net::DNS::SEC::VERSION:          ".$Net::DNS::SEC::VERSION);
diag("Net::DNS::Zone::Parser::VERSION: ".$Net::DNS::Zone::Parser::VERSION);
diag("Net::DNS::Zone::Parser::REVISION: ".$Net::DNS::Zone::Parser::REVISION);
diag("Net::DNS::Zone::Parser::NAMED_CHECKZONE: ".$Net::DNS::Zone::Parser::NAMED_CHECKZONE) if $Net::DNS::Zone::Parser::NAMED_CHECKZONE;
