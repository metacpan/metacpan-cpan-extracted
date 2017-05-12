#!/usr/bin/perl

# $Id: objective.pl,v 1.4 2004/12/01 17:34:07 mike Exp $

use strict;
use warnings;

use Net::Z3950::RadioMARC;

my $t = new Net::Z3950::RadioMARC();
$t->set(host => 'indexdata.com', port => '210', db => 'gils');
$t->set(delay => 3);
$t->set(verbosity => 2);
$t->set(messages => { ok => "This is the default 'OK' message" });

$t->add("etc/sample.marc");
$t->set(identityField => '710$a');

$t->test('@attr 1=4 data', { ok => '245$a is searchable as 1=4',
			     notfound => 'Search OK but record not found',
			     fail => '%{query}: search fails: %{errmsg}' });
$t->test('@attr 1=999 data', {});
$t->test('@attr 1=4 fruit', {});
