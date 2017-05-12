#!/usr/bin/perl
#
# Usage: "perl -I./lib litmus.pl > litmus.new; diff litmus.out litmus.new
#

use File::Temp;
use HTTP::Daemon;
use Net::DAV::Server;
use Filesys::Virtual::Plain;


# Set up Filesystem
my $tempdir = File::Temp::tempdir(CLEANUP => 1);
my $filesys = Filesys::Virtual::Plain->new({root_path => $tempdir});
my $webdav = Net::DAV::Server->new();
$webdav->filesys($filesys);

# Set up Server
my $d = HTTP::Daemon->new(
  LocalAddr => 'localhost',
  LocalPort => 4242,
  ReuseAddr => 1) || die;

# Run litmus against it
if (my $pid = fork()) {
  if( -1 == system("litmus", $d->url()) ) {
      print "Unable to start the 'litmus' program.\n";
  }
  kill 9, $pid;
  exit 0;
} 

# and do the requests...
else {
  while (my $c = $d->accept) {
    while (my $request = $c->get_request) {
      my $response = $webdav->run($request);
      $c->send_response ($response);
      $c->close;
    } 
    undef($c);
  }
}
