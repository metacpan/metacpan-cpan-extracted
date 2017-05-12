# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sorauta-Cache-HTTP-Request-Image.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use lib qw/lib/;
use Test::More tests => 3;
BEGIN { use_ok('Sorauta::Capture::ScreenShot') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $OS = "Mac"; # or Win(but not implement now)
my $CAPTURE_FILE_PATH = "/Users/yuki/Desktop/capture.jpg";
my $INTERVAL_TIME = 0;
my $DEBUG = 0;
my $API_URL = "http://api_url/path/to";
my $API_ATTRS = {
  file_name     => [$CAPTURE_FILE_PATH],
  test          => 'fugapiyo',
};

# capture test
{
  my $res = Sorauta::Capture::ScreenShot->new({
    os                    => $OS,
    capture_file_path     => $CAPTURE_FILE_PATH,
    interval_time         => $INTERVAL_TIME,
    debug                 => $DEBUG,
  })->execute;

  ok($res, "capture test");
}

# capture and send api test
{
  my $res = Sorauta::Capture::ScreenShot->new({
    os                    => $OS,
    capture_file_path     => $CAPTURE_FILE_PATH,
    interval_time         => $INTERVAL_TIME,
    debug                 => $DEBUG,
    api_url               => $API_URL,
    api_attr              => $API_ATTRS,
  })->execute;

  ok($res, "capture and send api test");
}

1;
