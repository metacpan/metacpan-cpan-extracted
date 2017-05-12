#!/bin/env perl -w
# -*- mode: cperl -*-
# $Id: 03-fixedLoadSimple.t,v 1.6 2004-09-11 04:48:02 ezra Exp $

BEGIN {
  unless(grep /blib/, @INC) {
    chdir 't' if -d 't';
    unshift @INC, '../lib' if -d '../lib';
  }
}

use Oracle::SQLLoader qw/$CHAR $INT $DECIMAL $DATE/;
use strict;
use Test;
use Cwd;

BEGIN {
 plan tests => 5
}


my $testTableName = "SQLLOADER_TEST_TABLE";
my $fixedLengthFile = getcwd() . "/$testTableName.fw";

ok(generateInputFile());
ok(goodLoad());
ok(generateBadLoadFile());
ok(warnLoad());
ok(errorLoad());


#ok(generateWrongOffsetLoadFile());
#ok(wrongOffsetLoad());

cleanup();


##############################################################################
sub generateInputFile {
  open (IN, ">$fixedLengthFile") || return 0;

#  char_col     char(10),
#  varchar_col  varchar2(10),
#  int_col      number(10),
#  float_col    number(15,5)

  print IN
"1charchar some vchar1111111111222222.22220041122 12:00
2charchar some vchar666666666699999.999920041122 12:00
3charchar some vchar222222222244444.444420041122 12:00
4charchar some vchar2222222222444444.44420041122 12:00";
  close IN;
  return 1;
} # sub generateInputFile



##############################################################################
sub goodLoad {
  my ($user, $pass) = split('/',$ENV{'ORACLE_USERID'});

  my $ldr = new Oracle::SQLLoader(
				  infile => $fixedLengthFile,
				  username => $user,
				  password => $pass,
				 );

  $ldr->addTable(table_name => $testTableName);


#  char_col     char(10),
#  varchar_col  varchar2(10),
#  int_col      number(10),
#  float_col    number(15,5)

  $ldr->addColumn(column_name => 'char_col',
		  field_offset => 0,
		  field_length => 8,
		  column_type => $CHAR);

  $ldr->addColumn(column_name => 'varchar_col',
		  field_offset => 10,
		  field_end => 19,
		  column_type => $CHAR);

  $ldr->addColumn(column_name => 'int_col',
		  field_offset => 20,
		  field_end => 29,
		  column_type => $INT);

  $ldr->addColumn(column_name => 'float_col',
		  field_offset => 30,
		  field_end => 39,
		  column_type => $DECIMAL);

  $ldr->addColumn(column_name => 'date_col',
		  field_offset => 40,
		  field_length => 13,
		  date_format => "YYYYMMDD HH24:MI",
		  column_type => $DATE);
  $ldr->executeLoader() || warn "Problem executing sqlldr: $@\n";

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
} # sub goodLoad



##############################################################################
sub generateBadLoadFile {
  open (IN, ">$fixedLengthFile") || return 0;

#  char_col     char(10),
#  varchar_col  varchar2(10),
#  int_col      number(10),
#  float_col    number(15,5)

  print IN
"xxxxxxxxxxxxxxxxxxxxxxxxxxxx
XXXXXXXXXXXXXXXX
XXXXXX
X";
  close IN;
  return 1;
} # sub generateBadLoadFile





##############################################################################
sub warnLoad {
  my ($user, $pass) = split('/',$ENV{'ORACLE_USERID'});
  my $ldr = new Oracle::SQLLoader(
				  infile => $fixedLengthFile,
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

  return 0 unless ref($ldr->getErrors()) eq 'ARRAY';
  return 0 if $ldr->getLastError();

  return 1;
} # sub warnLoad




##############################################################################
sub errorLoad {
  my ($user, $pass) = split('/',$ENV{'ORACLE_USERID'});
  my $ldr = new Oracle::SQLLoader(
				  infile => $fixedLengthFile,
				  terminated_by => ',',
				  username => $user,
				  password => $pass,
				 );


  $ldr->addTable(table_name => $testTableName);
  $ldr->addColumn(column_name => 'char_col');
  $ldr->addColumn(column_name => 'varchar_col');
  $ldr->addColumn(column_name => 'int_col');
  $ldr->addColumn(column_name => 'float_col');

  unlink $fixedLengthFile;
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
  unlink $fixedLengthFile;
}
