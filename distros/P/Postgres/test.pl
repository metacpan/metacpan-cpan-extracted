#! /usr/local/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..28\n"; }
END {print "not ok 1\n" unless $loaded;}
use Postgres;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$dbh = db_connect("template1") or die "Error: $Postgres::error";
print "ok 2\n";

if ($dbh->db() eq 'template1') {
  print "ok 3\n";
} else {
  print "not ok 3\n";
}

$host = $ENV{'PGHOST'} ? $ENV{'PGHOST'} : 'localhost';
if ($dbh->host() eq $host) {
  print "ok 4\n";
} else {
  print "not ok 4\n";
}

$options = $ENV{'PGOPTIONS'} ? $ENV{'PGOPTIONS'} : '';
if ($dbh->options() eq $options) {
  print "ok 5\n";
} else {
  print "not ok 5\n";
}

$port = $ENV{'PGPORT'} ? $ENV{'PGPORT'} : 5432;
if ($dbh->port() == $port) {
  print "ok 6\n";
} else {
  print "not ok 6\n";
}

$tty = $ENV{'PGTTY'} ? $ENV{'PGTTY'} : '';
if ($dbh->tty() == $tty) {
  print "ok 7\n";
} else {
  print "not ok 7\n";
}

$result = $dbh->execute("SELECT * from pg_class");
if ($result) {
  print "ok 8\n";
} else {
  print "no ok 8 Error: $Postgres::error\n";
}

if ($result->ntuples() > 0) {	# there had better be tuples in this one!
  print "ok 9\n";
} else {
  print "not ok 9\n";
}

if ($result->nfields() > 0) {
  print "ok 10\n";
} else {
  print "not ok 10\n";
}

if ($result->fname(0) eq 'relname') {
  print "ok 11\n";
} else {
  print "not ok 11\n";
}

if ($result->fnumber('relname') == 0) {
  print "ok 12\n";
} else {
  print "not ok 12\n";
}

if ($result->ftype(0) == 19) {
  print "ok 13\n";
} else {
  print "not ok 13\n";
}

if ($result->fsize(0) == 32) {
  print "ok 14\n";
} else {
  print "not ok 14\n";
}

# is this always going to return "pg_type"?  I think so...
if ($result->getvalue(0,0)) {	# better be a class name there!
  print "ok 15\n";
} else {
  print "not ok 15\n";
}

# if above is "pg_type" this should be 7
if ($result->getlength(0,0)) {
  print "ok 16\n";
} else {
  print "not ok 16\n";
}

# i'm assuming this is a non-NULL field.
if ($result->getisnull(0,0) == 0) {
  print "ok 17\n";
} else {
  print "not ok 17\n";
}

# I have not a clue what this returns.
if ($result->cmdStatus() == '') {
  print "ok 18\n";
} else {
  print "not ok 18\n";
}

# I have not a clue what this returns.
if ($result->oidStatus() == '') {
  print "ok 19\n";
} else {
  print "not ok 19\n";
}

@row = $result->fetchrow();

if (@row) {
  print "ok 20\n";
} else {
  print "not ok 20\n";
}

undef $result;
print "ok 21\n";

# test error return value
$result = $dbh->execute("xxxx");
if ($result) {
  print "not ok 22\n";
} else {
  print "ok 22\n";
}

# test query using cursor
$dbh->execute("BEGIN") or die "Unable to do transaction";
$result = $dbh->execute("DECLARE cx CURSOR FOR SELECT * from pg_class");
if ($result) {
  print "ok 23\n";
} else {
  print "not ok 23\n";
}

if ($result->ntuples() == 0) {	# should return 0 tuples
  print "ok 24\n";
} else {
  print "not ok 24\n";
}

$result = $dbh->execute("FETCH FORWARD 1 IN cx");
if ($result and $result->ntuples() == 1) {
  print "ok 25\n";
} else {
  print "not ok 25\n";
}


if (@row = $result->fetchrow()) {
  print "ok 26\n";
} else {
  print "not ok 26\n";
}

# this one should not return a row
if (@row = $result->fetchrow()) {
  print "not ok 27\n";
} else {
  print "ok 27\n";
}

$result = $dbh->execute("CLOSE cx");
if ($result) {
  print "ok 28\n";
} else {
  print "not ok 28\n";
}

$dbh->execute("END") or die "Unable to end transaction";

undef $dbh;

print "Done.\n";

