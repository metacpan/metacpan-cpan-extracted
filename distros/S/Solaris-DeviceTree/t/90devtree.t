# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use warnings;
use Test::More 'no_plan';
use English;

# Use the right perl for the scripts, because the scripts have
# not been installed and therefore the header with the execution
# program is wrong.

my $perl = $EXECUTABLE_NAME;

my $devtree = $ENV{'PWD'};
$devtree .= "/scripts/devtree";

if( ! -x $devtree ) {
  die "Cannot find devtree. It should be at $devtree but it's not there.\n";
}

sub checkrun {
  my ($cmd, %args) = @_;

  system "$perl $devtree $cmd >/dev/null 2>/dev/null";

  my $exit_value  = ($? >> 8);
  my $signal_num  = ($? & 127);
  my $dumped_core = ($? & 128);

  $args{'exit_value'} ||= 0;
  $args{'signal_num'} ||= 0;
  $args{'dumped_core'} ||= 0;

#  diag "exit: $exit_value signal: $signal_num dump: $dumped_core\n";

  ok( $exit_value == $args{'exit_value'} &&
      $signal_num == $args{'signal_num'} &&
      $dumped_core == $args{'dumped_core'},
      "Checking program run 'devtree $cmd' for errors" );
}

# Tests - tree printing
checkrun( "-p" );
checkrun( "--print" );
checkrun( "-pv" );
checkrun( "--print --all" );
checkrun( "-pw" );
checkrun( "--print --attr" );
checkrun( "-po" );
checkrun( "--print --prop" );
checkrun( "-pr" );
checkrun( "--print --promprop" );
checkrun( "-pm" );
checkrun( "--print --minor" );

# Tests - aliases
if( -r "/dev/openprom" ) {
  checkrun( "-a" );
  checkrun( "--aliases" );
  checkrun( "--aliases=disk" );
  checkrun( "-a disk" );
} else {
  # We are not allowed to read /dev/openprom. Expect 'permission denied' return code 13
  checkrun( "-a", exit_value => 13 );
  checkrun( "--aliases", exit_value => 13 );
  checkrun( "--aliases=disk", exit_value => 13 );
  checkrun( "-a disk", exit_value => 13 );
}

# Tests - disks
checkrun( "-d" );
checkrun( "--disks" );

# Tests - tapes
checkrun( "-t" );
checkrun( "--tapes" );

# Tests - networks
checkrun( "-n" );
checkrun( "--networks" );

# Tests - boot information
if( -r "/dev/openprom" ) {
  checkrun( "-b" );
  checkrun( "--bootinfo" );
} else {
  # We are not allowed to read /dev/openprom. Expect 'permission denied' return code 13
  checkrun( "-b", exit_value => 13 );
  checkrun( "--bootinfo", exit_value => 13 );
}


exit 0;
