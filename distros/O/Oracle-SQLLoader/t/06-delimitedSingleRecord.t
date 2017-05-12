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
use Test;
use Cwd;

BEGIN {
 plan tests => 4
}


my $testTableName = "SQLLOADER_TEST_TABLE";
my $delimitedFile = getcwd() . "/$testTableName.csv";


ok(generateInputFile());

ok(goodLoad());

ok(generateNoDelimiterLoadFile());

ok(noDelimiterLoad());

cleanup();





##############################################################################
sub generateInputFile {
  open (IN, ">$delimitedFile") || return 0;

#  char_col     char(10),
#  varchar_col  varchar2(10),
#  int_col      number(10),
#  float_col    number(15,5)

  print IN
"aaaaaaaaaa,aaa,1,102910391.333";
  close IN;
  return 1;
} # sub generateInputFile



##############################################################################
sub goodLoad {
  my ($user, $pass) = split('/',$ENV{'ORACLE_USERID'});
  my $ldr = new Oracle::SQLLoader(
				  infile => $delimitedFile,
				  terminated_by => ',',
				  username => $user,
				  password => $pass,
				 );


  $ldr->addTable(table_name => $testTableName);
  $ldr->addColumn(column_name => 'char_col');
  $ldr->addColumn(column_name => 'varchar_col');
  $ldr->addColumn(column_name => 'int_col');
  $ldr->addColumn(column_name => 'float_col');

  return 0 unless $ldr->executeLoader();
  return 0 unless $ldr->getNumberSkipped() == 0;
  return 0 unless $ldr->getNumberRead() == 1;
  return 0 unless $ldr->getNumberRejected() == 0;
  return 0 unless $ldr->getNumberDiscarded() == 0;
  return 0 unless $ldr->getNumberLoaded() == 1;
  return 0 unless not defined $ldr->getLastRejectMessage();

  # no telling what these are. let's check for defined...
  return 0 unless defined $ldr->getLoadBegin();
  return 0 unless defined $ldr->getLoadEnd();
  return 0 unless defined $ldr->getElapsedSeconds();
  return 0 unless defined $ldr->getCpuSeconds();

  # yay.
  return 1;
} # sub goodLoad


##############################################################################
sub generateNoDelimiterLoadFile {
  open (IN, ">$delimitedFile") || return 0;

#  char_col     char(10),
#  varchar_col  varchar2(10),
#  int_col      number(10),
#  float_col    number(15,5)

  print IN
"aaaaaaaaaaa       aaa         11029391039131.333";
  close IN;
  return 1;
} # sub generateNoDelimiterLoadFile



##############################################################################
sub noDelimiterLoad {
  my ($user, $pass) = split('/',$ENV{'ORACLE_USERID'});
  my $ldr = new Oracle::SQLLoader(
				  infile => $delimitedFile,
				  terminated_by => ',',
				  username => $user,
				  password => $pass,
				 );


  $ldr->addTable(table_name => $testTableName);
  $ldr->addColumn(column_name => 'char_col');
  $ldr->addColumn(column_name => 'varchar_col');
  $ldr->addColumn(column_name => 'int_col');
  $ldr->addColumn(column_name => 'float_col');

  # this is supposed to break
  return 0 unless not $ldr->executeLoader();

  # stats
  return 0 unless $ldr->getNumberSkipped() == 0;
  return 0 unless $ldr->getNumberRead() == 1;
  return 0 unless $ldr->getNumberRejected() == 1;
  return 0 unless $ldr->getNumberDiscarded() == 0;
  return 0 unless $ldr->getNumberLoaded() == 0;
  return 0 unless $ldr->getLastRejectMessage() eq
    'Column not found before end of logical record (use TRAILING NULLCOLS)';

  return 1;
} # sub noDelimiterLoad



##############################################################################
sub cleanup {
  unlink $delimitedFile;
}
