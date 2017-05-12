#!/bin/env perl -w
# -*- mode: cperl -*-
# $Id: 01-createTable.t,v 1.9 2005-07-28 03:09:35 ezra Exp $

BEGIN {
  unless(grep /blib/, @INC) {
    chdir 't' if -d 't';
    unshift @INC, '../lib' if -d '../lib';
  }
}

use Oracle::SQLLoader;
use strict;
use Test;
use Cwd;

BEGIN {
 plan tests => 3
}


my $testTableName = "SQLLOADER_TEST_TABLE";
my $ddlFile = getcwd() . "/$testTableName.sql";
my $sqlplus = $^O =~/win32/i ? 'sqlplus.exe' : 'sqlplus';

ok(($sqlplus = Oracle::SQLLoader->findProgram($sqlplus)));

ok(generateSQL());

ok(createTable());

cleanup();


sub generateSQL {
  open (DDL, ">$ddlFile") || return 0;
  print "generateSQL to file $ddlFile\n";
  print DDL "
drop table $testTableName;\n
create table $testTableName (
  char_col     char(10),
  varchar_col  varchar2(10),
  int_col      number(10),
  float_col    number(15,5),
  largetext_col varchar2(4000),
  date_col     date
);\n exit;\n";
  close DDL;
  return 1;
}


sub createTable {
  return 0 unless exists $ENV{'ORACLE_USERID'};
  return 0 unless exists $ENV{'ORACLE_SID'};
  my $userId = $ENV{'ORACLE_USERID'}. '@' .$ENV{'ORACLE_SID'};
  my $exe = "$sqlplus $userId \@$testTableName.sql";
  print "Creating table with command \"$exe\"\n";
  my $resLog = `$exe`;
  return 1 if $resLog =~ /Table created\./;
  return 0;
}

sub cleanup {
  unlink $ddlFile;
}
