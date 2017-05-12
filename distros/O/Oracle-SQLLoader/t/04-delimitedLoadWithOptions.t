#!/bin/env perl -w
# -*- mode: cperl -*-
# $Id: 04-delimitedLoadWithOptions.t,v 1.3 2004-09-11 04:42:20 ezra Exp $

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
 plan tests => 5
}


my $testTableName = "SQLLOADER_TEST_TABLE";
my $delimitedFile = getcwd() . "/$testTableName.csv";


ok(generateInputFile());

ok(goodLoad());

ok(generateBadFile());

ok(warnLoad());

ok(errorLoad());

cleanup();


##############################################################################
sub generateInputFile {
  open (IN, ">$delimitedFile") || return 0;

#  char_col     char(10),
#  varchar_col  varchar2(10),
#  int_col      number(10),
#  float_col    number(15,5)

  print IN
"49698431|baufile|49698431          EDITEDITEDITEDIT         8831125                   4731 N 47th Dr                                                                  Phoenix        AZ85031                                                55543882555232835022                    0004771 690.41            12-JUL-0 238.48           13-JUL-04                                                                         29-JUN-04       23-JUL-04                                                                                                                                                                                                                                                                            EDITEDITEDITEDITED             0       97      C000    81
49703288|baufile|49703288          EDITEDITEDITEDI          11131488                  5091 E Townsend Ave                                                             Fresno         CA93727                                                55543882555232835022                    0144031 1263.35           14-JUL-0 1152.07          01-JUL-04                                                                         29-MAY-04       17-JUL-04                                                                                                                                                                                                                                                                                                           0       0       C000    0
49705379|baufile|49705379          EDITEDITEDITEDITE        11385432                  4035 West Breckenridge Ct                                                       Beverly Hills  FL34465                                                55543882555232835022                    0166086 2373.33           18-MAY-0 1962.33          01-JUL-04                                                                         07-JUN-04       <Not Avai                                                                                                                                                                                                                                                                                                           0       0       C000    0";
  close IN;
  return 1;
} # sub generateInputFile



##############################################################################
sub goodLoad {
  my ($user, $pass) = split('/',$ENV{'ORACLE_USERID'});
  my $ldr = new Oracle::SQLLoader(
				  infile => $delimitedFile,
				  terminated_by => '|',
				  username => $user,
				  password => $pass,
				 );


  $ldr->addTable(table_name => $testTableName);
  $ldr->addColumn(column_name => 'char_col');
  $ldr->addColumn(column_name => 'varchar_col');
  $ldr->addColumn(column_name => 'largetext_col',
		  column_length => 3000);

  return 0 unless $ldr->executeLoader();
  return 0 unless $ldr->getNumberSkipped() == 0;
  return 0 unless $ldr->getNumberRead() == 3;
  return 0 unless $ldr->getNumberRejected() == 0;
  return 0 unless $ldr->getNumberDiscarded() == 0;
  return 0 unless $ldr->getNumberLoaded() == 3;
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
sub generateBadFile {
  open (IN, ">$delimitedFile") || return 0;

#  char_col     char(10),
#  varchar_col  varchar2(10),
#  int_col      number(10),
#  float_col    number(15,5)

  print IN
"aaaaaaaaaaa       aaa         11029391039131.333
bbbbbbbbbbb      bbbb        291029391039131.333
ccccccccccc     ccccc       2931029391039131.333
ddddddddddd    dddddd19329329321029391039131.333";
  close IN;
  return 1;
} # sub generateBadFile



##############################################################################
sub warnLoad {
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
  return 0 unless $ldr->getNumberRead() == 4;
  return 0 unless $ldr->getNumberRejected() == 4;
  return 0 unless $ldr->getNumberDiscarded() == 0;
  return 0 unless $ldr->getNumberLoaded() == 0;
  return 0 unless $ldr->getLastRejectMessage() eq
    'Column not found before end of logical record (use TRAILING NULLCOLS)';

  return 1;
} # sub warnLoad




##############################################################################
sub errorLoad {
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

  unlink $delimitedFile;

  # this is supposed to break
  return 0 unless not $ldr->executeLoader();

  # stats
  return 0 unless $ldr->getNumberSkipped() == 0;
  return 0 unless $ldr->getNumberRead() == 0;
  return 0 unless $ldr->getNumberRejected() == 0;
  return 0 unless $ldr->getNumberDiscarded() == 0;
  return 0 unless $ldr->getNumberLoaded() == 0;

  # shouldn't be any rejects, just some real error messages
  return 0 if defined $ldr->getLastRejectMessage();

  # catch messages with errors specific to these malformed lines
  my $errors = $ldr->getErrors();
  return 0 unless $#$errors == 3;
  return 0 unless $ldr->getLastError() =~ /SQL\*Loader-2026/;

  return 1;
} # sub errorLoad



##############################################################################
sub cleanup {
  unlink $delimitedFile;
}
