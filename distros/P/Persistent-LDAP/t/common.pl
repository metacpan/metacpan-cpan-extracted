########################################################################
# File:     common.pl
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: common.pl,v 1.2 2000/02/08 03:09:42 winters Exp winters $
#
# A library for testing the Persistent classes.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

use Persistent::File;
use Persistent::LDAP;

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
}

### cleans up the test environment ###
sub cleanup_env {
  my $cfg = shift;

  my $temp_dir = $cfg->{TempDir};
  unlink <$temp_dir/persons.*> if -d $temp_dir;
  rmdir $temp_dir;
  delete_entries($cfg);
}

### performs the test and prints the appropriate message ###
sub test {
    local($^W) = 0;
    my($num, $true, $msg) = @_;
    print($true ? "ok $num\n" : "not ok $num: $msg\n");
}

### allocates and defines a person object ###
sub new_person {
  my($cfg, $type) = @_;

  ### allocate a persistent object ###
  my $person;
  if (defined $type && $type eq 'File') {
    $person = new Persistent::File("$cfg->{TempDir}/persons.txt", '|');
  } else {
    $person = new Persistent::LDAP($cfg->{Host}, $cfg->{Port},
				$cfg->{BindDN}, $cfg->{Passwd},
				$cfg->{BaseDN});
  }

  ### define attributes of the object ###
  $person->add_attribute('uid',             'ID',         'String');
  $person->add_attribute('userpassword',    'Persistent', 'String');
  $person->add_attribute('objectclass',     'Persistent', 'String');
  $person->add_attribute('givenname',       'Persistent', 'String');
  $person->add_attribute('sn',              'Persistent', 'String');
  $person->add_attribute('cn',              'Persistent', 'String');
  $person->add_attribute('mail',            'Persistent', 'String');
  $person->add_attribute('telephonenumber', 'Persistent', 'String');

  $person;
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

### deletes the entries from the directory that were added for the test ###
sub delete_entries {
  my $cfg = shift;

  ### Don't eval it -- if it fails, let it die. ###
  ### Test::Harness will catch it. ###
  my $person = new_person($cfg);
  $person->restore_where('mail=*49ers.com');
  while ($person->restore_next()) {
    $person->delete();
  }
}

1;
