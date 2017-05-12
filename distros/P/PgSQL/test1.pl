#!/usr/local/bin/perl

# Copyright (c) 1998           Göran Thyni
# $Id: test1.pl,v 1.2 1998/08/11 15:50:38 goran Exp $

use strict;
use PgSQL;

my $res;
my $dbh = new PgSQL(DBName => 'goran', Host => 'localhost');
$res = $dbh->do("DROP TABLE y");
$res = $dbh->do("CREATE TABLE y (i integer, s varchar(21))");
print "## CREATE: $res\n";
$res = $dbh->begin;
print "## BEGIN: $res\n";
$res = $dbh->do("INSERT INTO y VALUES(1, 'ABCD')");
print "## INSERT 1: $res\n";
$res = $dbh->do("INSERT INTO y VALUES(2, 'B')");
print "## INSERT 2: $res\n";
$res = $dbh->do("INSERT INTO y VALUES(88, NULL)");
print "## INSERT 3: $res\n";
$res = $dbh->commit;
print "## COMMIT: $res\n";
my $sth = $dbh->do("SELECT * FROM y");
print "## SELECT: $sth\n";
while ($res = $sth->fetch)
  {
    print "## FETCH: @$res\n";
  }
$sth->finish;
$res = $dbh->do("DROP TABLE y");
print "## DROP: $res\n";
$res = $dbh->close;
print "## CLOSE: $res\n";

1;
