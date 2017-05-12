########################################################################
# File:     common.pl
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: common.pl,v 1.1 2000/02/10 01:49:42 winters Exp winters $
#
# A library for testing the Persistent classes.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

use Persistent::File;
use Persistent::Sybase;

########################################################################
# Functions
########################################################################

### loads the configuration parameters ###
sub load_config {
  my $cfg = shift;

  ### initialize config params ###
  $cfg->{TempDir}   = './temp';
  $cfg->{LoginFile} = './LOGIN';
  parse_login_file($cfg);
}

### prepares the test environment ###
sub prepare_env {
  my $cfg = shift;

  ### initialize environment ###
  mkdir $cfg->{TempDir}, 0777;
  create_table($cfg);
}

### cleans up the test environment ###
sub cleanup_env {
  my $cfg = shift;

  my $temp_dir = $cfg->{TempDir};
  unlink <$temp_dir/cars.*> if -d $temp_dir;
  rmdir $temp_dir;
  drop_table($cfg);
}

### performs the test and prints the appropriate message ###
sub test {
    local($^W) = 0;
    my($num, $true, $msg) = @_;
    print($true ? "ok $num\n" : "not ok $num: $msg\n");
}

### allocates and defines a car object ###
sub new_car {
  my($cfg, $type) = @_;

  ### allocate a persistent object ###
  my $car;
  if (defined $type && $type eq 'File') {
    $car = new Persistent::File("$cfg->{TempDir}/cars.txt", '|');
  } else {
    $car = new Persistent::Sybase($cfg->{DataSource},
				  $cfg->{User}, $cfg->{Passwd}, 'car');
  }

  ### define attributes of the object ###
  $car->add_attribute('license', 'id',         'VarChar',  undef, 7);
  $car->add_attribute('make',    'persistent', 'VarChar',  undef, 20);
  $car->add_attribute('model',   'persistent', 'VarChar',  undef, 20);
  $car->add_attribute('year',    'persistent', 'Number',   undef, 4);
  $car->add_attribute('color',   'persistent', 'VarChar',  undef, 20);

  $car;
}

### parses the login file and sets global login vars ###
sub parse_login_file {
  my $cfg = shift;

  open(LOGIN, "<$cfg->{LoginFile}") or die "Can't open $cfg->{LoginFile}: $!";
  foreach my $line (<LOGIN>) {
    ### skip comments and blank lines ###
    if ($line =~ /^\s*\#/ || $line =~ /^\s*$/) {
      next;
    }

    ### parse the line ###
    if ($line =~ /^\s*(\S+)\s*:\s*(.*\S)\s*$/) {
      $cfg->{$1} = $2;
    }
  }
  close(LOGIN);
}

### creates the table in the database ###
sub create_table {
  my $cfg = shift;

  my $dbh = DBI->connect($cfg->{DataSource}, $cfg->{User}, $cfg->{Passwd},
			 {AutoCommit => 1,
			  PrintError => 0,
			  RaiseError => 0});
  die("Can't connect to database: $DBI::errstr" .
      "\n------------------------------------------------------------\n" .
      "Make sure that the LOGIN file contains the correct information\n" .
      "to connect to your database." .
      "\n------------------------------------------------------------\n\n"
     ) if $DBI::err;

  ### query data dictionary for the existence of the table ###
  my $sth = $dbh->prepare("SELECT name FROM sysobjects " .
			  "WHERE name = 'car' AND type ='U'")
    or handle_dbi_error($dbh, "Can't prepare statement");
  $sth->execute() or handle_dbi_error($dbh, "Can't execute statement");
  my $count = 0;
  while ($sth->fetchrow_array()) { $count++ };

  ### create the table if it does not exist ###
  if ($count == 0) {
    $dbh->do(qq(
		CREATE TABLE car (
				  license VARCHAR(7)  NOT NULL,
				  make    VARCHAR(20) NULL,
				  model   VARCHAR(20) NULL,
				  year    VARCHAR(4)  NULL,
				  color   VARCHAR(20) NULL
				 )
	       )) or handle_dbi_error($dbh, "Can't create table");
  }
  $dbh->disconnect();
}

### drops the table in the database ###
sub drop_table {
  my $cfg = shift;

  my $dbh = DBI->connect($cfg->{DataSource}, $cfg->{User}, $cfg->{Passwd},
			 {AutoCommit => 1,
			  PrintError => 0,
			  RaiseError => 0});
  die "Can't connect to database: $DBI::errstr" if $DBI::err;

  ### query data dictionary for the existence of the table ###
  my $sth = $dbh->prepare("SELECT name FROM sysobjects " .
			  "WHERE name = 'car' AND type ='U'")
    or handle_dbi_error($dbh, "Can't prepare statement");
  $sth->execute() or handle_dbi_error($dbh, "Can't execute statement");
  my $count = 0;
  while ($sth->fetchrow_array()) { $count++ };

  ### drop the table if it exists ###
  if ($count == 1) {
    $dbh->do(qq(
		DROP TABLE car
	       )) or handle_dbi_error($dbh, "Can't drop table");
  }
  $dbh->disconnect();
}

### handler for DBI related errors ###
sub handle_dbi_error {
  my($dbh, $msg) = @_;

  my $errstr = $DBI::errstr;
  $dbh->disconnect();
  die "$msg: $errstr";
}

1;
