# test of Exporter with DBIx::Interpolate and FILTER.

use strict;
use lib 't/lib';
use DBD::Mock;
use Test::More 'no_plan';
use DBIx::Interpolate 'sql_interp', FILTER => 1;
BEGIN {require 't/lib.pl';}

my $dbh = DBI->connect('DBI:Mock:', '', '')
    or die "Cannot create handle: $DBI::errstr\n";
my $dbx = new DBIx::Interpolate($dbh);

my $x = 3;
my_deeply([sql_interp(sql[where x = $x])], ["where x =  ?", 3]);
