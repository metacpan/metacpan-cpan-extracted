#!/usr/bin/perl

# $Id: simple.pl,v 1.12 2004/12/16 16:54:06 mike Exp $

use strict;
use warnings;

use Net::Z3950::RadioMARC;


set host => 'indexdata.com', port => '210', db => 'gils';
#set host => 'localhost', port => '9999', db => 'Default';
set delay => 0;			# Don't delay at all between searches
set verbosity => 2;
set messages => { ok => "This is the default 'OK' message" };

add "etc/sample.marc";
set identityField => '710$a';

test '@attr 1=4 data', { ok => '245$a is searchable as 1=4',
			 notfound => 'Search OK but record not found',
			 fail => '%{query}: search fails: %{errmsg}' };
test '@attr 1=999 data';
test '@attr 1=4 fruit';
