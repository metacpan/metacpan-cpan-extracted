########################################################################
# File:     common.pl
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: common.pl,v 1.1 2000/02/10 00:18:58 winters Exp winters $
#
# A library for testing the Persistent classes.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

use Persistent::DBI;

########################################################################
# Functions
########################################################################

### loads the configuration parameters ###
sub load_config {
  my $cfg = shift;

  ### initialize config params ###
  $cfg->{TempDir}   = './temp';
  $cfg->{LoginFile} = './LOGIN';
}

### prepares the test environment ###
sub prepare_env {
  my $cfg = shift;

  ### initialize environment ###
#  mkdir $cfg->{TempDir}, 0777;
}

### cleans up the test environment ###
sub cleanup_env {
  my $cfg = shift;

#  my $temp_dir = $cfg->{TempDir};
#  unlink <$temp_dir/cars.*> if -d $temp_dir;
#  rmdir $temp_dir;
}

### performs the test and prints the appropriate message ###
sub test {
    local($^W) = 0;
    my($num, $true, $msg) = @_;
    print($true ? "ok $num\n" : "not ok $num: $msg\n");
}

1;
