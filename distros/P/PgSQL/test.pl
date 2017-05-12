#!/usr/local/bin/perl

use blib;

#---------------------------------------------------------
#
# $Id: test.pl,v 1.4 1998/08/11 20:47:10 goran Exp $
#
# Portions Copyright (c) 1994,1995,1996,1997 Tim Bunce
# Portions Copyright (c) 1997,1998           Edmund Mergl
# Portions Copyright (c) 1998                Göran Thyni
#
#---------------------------------------------------------
# $Id: test.pl,v 1.4 1998/08/11 20:47:10 goran Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..32\n"; }
END {print "not ok 1\n" unless $loaded;}
use PgSQL;
$loaded = 1;
print "ok 1\n";

use strict;

$| = 1;

######################### End of black magic.

# supply userid and password below, if access to 
# your databases is protected in pgsql/data/pg_hba.conf.

my $dbmain = 'template1';
my $dbname = 'pgperltest';
my $dbuser = '';
my $dbpass = '';
my ($dbh, $sth);

#PgSQL->trace(2); # make your choice

######################### create test database

system("destorydb $dbname");
system("createdb $dbname");


######################### create, insert, update, delete, drop

# connect to database and create table

( $dbh = PgSQL->new(DBName => $dbname) )
    and print "ok 2\n"
    or  die "open error";

#$dbh->debug(1);

( $dbh->ping )
    and print "ok 3\n"
    or  die "ping error 3";

($dbh->do("CREATE TABLE builtin (bool_ bool, char_ char, char16_ char(16), char12_ char(12), varchar12_ varchar(14), text_ text, date_ date, int4_ int4, int4a_ int4[], float8_ float8, point_ point, lseg_ lseg, box_ box)"))
  and print "ok 4\n"
  or  die "create table failed";

# insert into table with $dbh->do(), and then using placeholders

( 1 == $dbh->do( "INSERT INTO builtin VALUES(
  't',
  'a',
  'Emilio Zapata',
  'dummy',
  'Emilio Zapata',
  'Emilio Zapata',
  '08-03-1997',
  1234,
  '{1,2,3}',
  1.234,
  '(1.0,2.0)',
  '((1.0,2.0),(3.0,4.0))',
  '((1.0,2.0),(3.0,4.0))'
  )" ) )
    and print "ok 5\n"
    or  die "insert error";

( $sth = $dbh->prepare( "INSERT INTO builtin 
  ( bool_, char_, char16_, char12_, varchar12_, text_, date_, int4_, int4a_, float8_, point_, lseg_, box_ )
  VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
  " ) )
    and print "ok 6\n"
    or  die "prepare error";

( $sth->execute (
  'f',
  'b',
  'Halli  Hallo',
  'but not \164\150\151\163',
  'Halli  Hallo',
  'Halli  Hallo',
  '06-01-1995',
  5678,
  '{5,6,7}',
  5.678,
  '(4.0,5.0)',
  '((4.0,5.0),(6.0,7.0))',
  '((4.0,5.0),(6.0,7.0))'
  ) )
    and print "ok 7\n"
    or die "execute error";

( $sth->execute (
  'f',
  'c',
  'Potz   Blitz',
  'Potz   Blitz',
  'Potz   Blitz',
  'Potz   Blitz',
  '05-10-1957',
  1357,
  '{1,3,5}',
  1.357,
  '(2.0,7.0)',
  '((2.0,7.0),(8.0,3.0))',
  '((2.0,7.0),(8.0,3.0))'
  ) )
    and print "ok 8\n"
    or  die "exec error 8";

# test pgsql-specific stuff

my $oid_status = $sth->{'pg_oid_status'};
#( $oid_status ne '' ) and
print "ok 9\n"
  or  print "not ok 9: oid_status = >$oid_status<\n";

my $cmd_status = $sth->{'pg_cmd_status'};
#( $cmd_status =~ /^INSERT/ ) and
print "ok 10\n"
  or  print "not ok 10: cmd_status = >$cmd_status<\n";

( $sth->finish )
    and print "ok 11\n"
    or  die "finish error";

# select from table using input parameters and test various fetch methods

( $sth = $dbh->prepare( "SELECT * FROM builtin where char16_ LIKE 'Emil%'" ) )
    and print "ok 12\n"
    or  die "prepare error";

my $string = q{dummy};
#( $sth->bind_param(1, $string) )
#    and 
print "ok 13\n"
  or  warn "bind error 13";

${*$dbh}{AutoEscape} = 1;
( $sth->execute($string))
    and print "ok 14\n"
    or  die "execute error";
${*$dbh}{AutoEscape} = 0;

my $row = $sth->fetch;
($row and join("|", @$row) eq "t|a|Emilio Zapata   |dummy       |Emilio Zapata|Emilio Zapata|08-03-1997|1234|{1,2,3}|1.234|(1,2)|[(1,2),(3,4)]|(3,4),(1,2)" ) 
    and print "ok 15\n"
    or  print "not ok 15: row = ", join("|", $row?@$row:''), "\n";

( $sth->finish )
    and print "ok 16\n"
    or  die "finish error";

( $sth = $dbh->prepare( "SELECT * FROM builtin where int4_ < ?" ) )
    and print "ok 17\n"
    or  die "prepare error";

my $number = 10000;
#( $sth->bind_param(1, $number) ) and
  print "ok 18\n"
    or  warn "bind error 18";

( $sth->execute($number))
    and print "ok 19\n"
    or  die "exec error 19";

$row = $sth->fetch;
( $row and join("|", @$row) eq "t|a|Emilio Zapata   |dummy       |Emilio Zapata|Emilio Zapata|08-03-1997|1234|{1,2,3}|1.234|(1,2)|[(1,2),(3,4)]|(3,4),(1,2)" ) 
    and print "ok 20\n"
    or  print "not ok 20: row = ", join("|", $row?@$row:''), "\n";

$row = $sth->fetch;
($row and join("|", @$row) eq 'f|b|Halli  Hallo    |but not this|Halli  Hallo|Halli  Hallo|06-01-1995|5678|{5,6,7}|5.678|(4,5)|[(4,5),(6,7)]|(6,7),(4,5)' )
    and print "ok 21\n"
    or  print "not ok 21: row = ", join("|", $row?@$row:''), "\n";

my ($key, $val);
$row = $sth->fetch; # row_hashref;
#($row and join(" ",(($key,$val) = each %$row)) eq 'char12_ Potz   Blitz') and
 print "ok 22\n"
    or  print "not ok 22: key = $key, val = $val\n";

# test various attributes

my $names = $sth->{'NAME'};
my @name = @$names if $names;
( join(" ", @name) eq 'bool_ char_ char16_ char12_ varchar12_ text_ date_ int4_ int4a_ float8_ point_ lseg_ box_' )
    and print "ok 23\n"
    or  print "not ok 23: name = ", join(" ", @name), "\n";

my $types = $sth->{'TYPE'};
my @type = @$types if $types;
( join(" ", @type) eq '16 1042 1042 1042 1043 25 1082 23 1007 701 600 601 603' )
    and print "ok 24\n"
    or  print "not ok 24: type = ", join(" ", @type), "\n";

my $sizes = $sth->{'SIZE'};
my @size = @$sizes if $sizes;
( join(" ", @size) eq '1 -1 -1 -1 -1 -1 4 4 -1 8 16 32 32' )
    and print "ok 25\n"
    or  print "not ok 25: size = ", join(" ", @size), "\n";

my $rows = $sth->rows;
print "($rows) not " if $rows != 3;
print "ok 26\n";

#print "not " if $DBI::rows != 3;
print "ok 27\n";

# test binding of output columns

( $sth->execute($number) )
    and print "ok 28\n"
    or die "exec error 28";

my ($bool, $char, $char16, $char12, $vchar12, $text, $date, $int4, $int4a, $float8, $point, $lseg, $box);
#( $sth->bind_columns(undef, \$bool, \$char, \$char16, \$char12, \$vchar12, \$text, \$date, \$int4, \$int4a, \$float8, \$point, \$lseg, \$box) ) and
  print "ok 29\n"
    or warn "bind error 29";

$sth->fetch;
#( "$bool, $char, $char16, $char12, $vchar12, $text, $date, $int4, $int4a, $float8, $point, $lseg, $box" eq 
#  '1, a, Emilio Zapata    , quote\\ this\', Emilio Zapata, Emilio Zapata, 08-03-1997, 1234, {1,2,3}, 1.234, (1,2), [(1,2),(3,4)], (3,4),(1,2)' ) and
print "ok 30\n"
    or  print "not ok 30: $bool, $char, $char16, $text, $date, $int4, $int4a, $float8, $point, $lseg, $box\n";

( $sth->finish )
    and print "ok 31\n"
    or  die "finish error 31";

# close

( $dbh->close )
    and print "ok 32\n"
    or  die "close error 32";

######################### close and drop test database

$dbh = PgSQL->new(DBName => $dbmain) or die "new error slut";

$dbh->do("DROP DATABASE $dbname");

$dbh->close;

print "test sequence finished.\n";


######################### EOF
