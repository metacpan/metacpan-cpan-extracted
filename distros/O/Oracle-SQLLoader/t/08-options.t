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
 plan tests => 16
}


my $testTableName = "SQLLOADER_TEST_TABLE";
my $delimitedFile = getcwd() . "/$testTableName.csv";


ok(generateInputFile(), 'generate input file');

my %tests = (
             bindsize  => 256000,
             columnarrayrows => 5000,
             direct => 'false',
             discardmax => 500,
             errors => 50,
             load => 10,
             multithreading => 'false',
             parallel => 'false',
             readsize => 0,
             rows => 64,
             skip => 0,
             skip_index_maintenance => 'false',
             skip_unusable_indexes => 'false',
             streamsize => 256000,
             silent => 'ALL',
            );

foreach my $key (sort keys %tests) {
  my $val = $tests{$key};
  ok(loadOption($key, $val), "$key = $val");
}


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
sub loadOption {
  my ($user, $pass) = split('/',$ENV{'ORACLE_USERID'});
  my ($option, $value) = @_;
  my $ldr = new Oracle::SQLLoader(
				  infile => $delimitedFile,
				  terminated_by => ',',
				  username => $user,
				  password => $pass,
                                  $option => $value,
                                 );

  return 0 unless $ldr->{'_cfg_global'}{$option} eq $value;

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
} # sub loadOption


##############################################################################
sub cleanup {
  unlink $delimitedFile;
}
