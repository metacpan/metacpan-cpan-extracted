#!/bin/env perl -w
# -*- mode: cperl -*-
# $Id: 02-delimitedLoadSimple.t,v 1.4 2004-09-05 05:56:02 ezra Exp $

BEGIN {
  unless(grep /blib/, @INC) {
    chdir 't' if -d 't';
    unshift @INC, '../lib' if -d '../lib';
  }
}

use Oracle::SQLLoader;
use strict;
use Test::More;
use Cwd;

BEGIN {
 plan tests => 5
}


my $testTableName = "SQLLOADER_TEST_TABLE";
my $delimitedFile = getcwd() . "/$testTableName.csv";


ok(generateInputFile());

ok(loadDirect1(), "load direct '1'");
ok(loadDirect0(), "load direct '0'");
ok(loadDirectTrue(), "load direct 'true'");
ok(loadDirectFalse(), "load direct 'false'");


cleanup();





##############################################################################
sub generateInputFile {
  open (IN, ">$delimitedFile") || return 0;

#  char_col     char(10),
#  varchar_col  varchar2(10),
#  int_col      number(10),
#  float_col    number(15,5)

  print IN
"aaaaaaaaaa,aaa,1,102910391.333
bbbbbbbbbb,bbbb,29,103910131.333
cccccccccc,ccccc,293,391039131.333
dddddddddd,dddddd,1932932932,1039131.333";
  close IN;
  return 1;
} # sub generateInputFile



##############################################################################
sub loadDirect1 {
  my ($user, $pass) = split('/',$ENV{'ORACLE_USERID'});
  my $ldr = new Oracle::SQLLoader(
				  infile => $delimitedFile,
				  terminated_by => ',',
				  username => $user,
				  password => $pass,
                                  direct => 1,
				 );


  $ldr->addTable(table_name => $testTableName);
  $ldr->addColumn(column_name => 'char_col');
  $ldr->addColumn(column_name => 'varchar_col');
  $ldr->addColumn(column_name => 'int_col');
  $ldr->addColumn(column_name => 'float_col');

  return 0 unless $ldr->executeLoader();
  return 0 unless $ldr->getNumberSkipped() == 0;
  return 0 unless $ldr->getNumberRead() == 4;
  return 0 unless $ldr->getNumberRejected() == 0;
  return 0 unless $ldr->getNumberDiscarded() == 0;
  return 0 unless $ldr->getNumberLoaded() == 4;
  return 0 unless not defined $ldr->getLastRejectMessage();

  # no telling what these are. let's check for defined...
  return 0 unless defined $ldr->getLoadBegin();
  return 0 unless defined $ldr->getLoadEnd();
  return 0 unless defined $ldr->getElapsedSeconds();
  return 0 unless defined $ldr->getCpuSeconds();

  # yay.
  return 1;
} # sub loadDirect1



##############################################################################
sub loadDirect0 {
  my ($user, $pass) = split('/',$ENV{'ORACLE_USERID'});
  my $ldr = new Oracle::SQLLoader(
				  infile => $delimitedFile,
				  terminated_by => ',',
				  username => $user,
				  password => $pass,
                                  direct => 0,
				 );


  $ldr->addTable(table_name => $testTableName);
  $ldr->addColumn(column_name => 'char_col');
  $ldr->addColumn(column_name => 'varchar_col');
  $ldr->addColumn(column_name => 'int_col');
  $ldr->addColumn(column_name => 'float_col');

  return 0 unless $ldr->executeLoader();
  return 0 unless $ldr->getNumberRead() == 4;
  return 0 unless $ldr->getNumberRejected() == 0;
  return 0 unless $ldr->getNumberDiscarded() == 0;
  return 0 unless $ldr->getNumberLoaded() == 4;
  return 0 unless not defined $ldr->getLastRejectMessage();

  # no telling what these are. let's check for defined...
  return 0 unless defined $ldr->getLoadBegin();
  return 0 unless defined $ldr->getLoadEnd();
  return 0 unless defined $ldr->getElapsedSeconds();
  return 0 unless defined $ldr->getCpuSeconds();

  # yay.
  return 1;
} # sub loadDirect0



##############################################################################
sub loadDirectTrue {
  my ($user, $pass) = split('/',$ENV{'ORACLE_USERID'});
  my $ldr = new Oracle::SQLLoader(
				  infile => $delimitedFile,
				  terminated_by => ',',
				  username => $user,
				  password => $pass,
                                  direct => 'true',
				 );


  $ldr->addTable(table_name => $testTableName);
  $ldr->addColumn(column_name => 'char_col');
  $ldr->addColumn(column_name => 'varchar_col');
  $ldr->addColumn(column_name => 'int_col');
  $ldr->addColumn(column_name => 'float_col');

  return 0 unless $ldr->executeLoader();
  return 0 unless $ldr->getNumberRead() == 4;
  return 0 unless $ldr->getNumberRejected() == 0;
  return 0 unless $ldr->getNumberDiscarded() == 0;
  return 0 unless $ldr->getNumberLoaded() == 4;
  return 0 unless not defined $ldr->getLastRejectMessage();

  # no telling what these are. let's check for defined...
  return 0 unless defined $ldr->getLoadBegin();
  return 0 unless defined $ldr->getLoadEnd();
  return 0 unless defined $ldr->getElapsedSeconds();
  return 0 unless defined $ldr->getCpuSeconds();

  # yay.
  return 1;
} # sub loadDirectTrue



##############################################################################
sub loadDirectFalse {
  my ($user, $pass) = split('/',$ENV{'ORACLE_USERID'});
  my $ldr = new Oracle::SQLLoader(
				  infile => $delimitedFile,
				  terminated_by => ',',
				  username => $user,
				  password => $pass,
                                  direct => 'false',
				 );


  $ldr->addTable(table_name => $testTableName);
  $ldr->addColumn(column_name => 'char_col');
  $ldr->addColumn(column_name => 'varchar_col');
  $ldr->addColumn(column_name => 'int_col');
  $ldr->addColumn(column_name => 'float_col');

  return 0 unless $ldr->executeLoader();
  return 0 unless $ldr->getNumberSkipped() == 0;
  return 0 unless $ldr->getNumberRead() == 4;
  return 0 unless $ldr->getNumberRejected() == 0;
  return 0 unless $ldr->getNumberDiscarded() == 0;
  return 0 unless $ldr->getNumberLoaded() == 4;
  return 0 unless not defined $ldr->getLastRejectMessage();

  # no telling what these are. let's check for defined...
  return 0 unless defined $ldr->getLoadBegin();
  return 0 unless defined $ldr->getLoadEnd();
  return 0 unless defined $ldr->getElapsedSeconds();
  return 0 unless defined $ldr->getCpuSeconds();

  # yay.
  return 1;
} # sub loadDirectFalse

##############################################################################
sub cleanup {
  unlink $delimitedFile;
}
