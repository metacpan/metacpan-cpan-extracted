# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sorauta-Utility.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use lib qw/lib/;
use Test::More tests => 2;
BEGIN { use_ok('Sorauta::Device::USB::Synchronizer') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# synchronized test
{
  my $TARGET_DIR_PATH = '/Users/yuki/Desktop/test_usb_synchronizer';
  my $SYNCHRONIZED_DIR_LIST = ["test1", "test2"];
  my $OS = 'Mac';
  my $INTERVAL_TIME = 0;
  my $ALLOW_OVERRIDE_FILE = 0;
  my $DEBUG = 0;
  my $CONNECTED_EVENT_REF = sub {
    my($self, $driver_path) = @_;
    print "connected!!";
  };
  my $UPDATED_EVENT_REF = sub {
    my $self = shift;
    print "updated!!";
  };

  # USB監視開始
  my $result = Sorauta::Device::USB::Synchronizer->new({
    target_dir_path       => $TARGET_DIR_PATH,
    synchronized_dir_list => $SYNCHRONIZED_DIR_LIST,
    os                    => $OS,
    interval_time         => $INTERVAL_TIME,
    allow_override_file   => $ALLOW_OVERRIDE_FILE,
    debug                 => $DEBUG,
    connected_event_ref   => $CONNECTED_EVENT_REF,
    updated_event_ref     => $UPDATED_EVENT_REF,
  })->execute;

  ok($result, "synchronized test");
}

1;
