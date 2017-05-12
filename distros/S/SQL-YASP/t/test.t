#!/usr/bin/perl -w
use strict;
use SQL::YASP;
use Test::More;
plan tests => 1;

# tools for debugging
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# PLEASE NOTE: SQL::YASP is no longer under active development. The almost
# absence of tests reflects that fact.


# variables
my ($sql, $stmt, $rec);


#------------------------------------------------------------------------------
# SQL
#
$sql = <<'(SQL)';

select
	name
from
	members
where
	id=1

(SQL)
#
# SQL
#------------------------------------------------------------------------------


# parse
$stmt = SQL::YASP->parse($sql);

# should have statement
ok($stmt, 'should have statement');

