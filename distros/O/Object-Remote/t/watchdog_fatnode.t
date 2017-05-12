use strictures 1;
use Test::More;

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

use Object::Remote::Connector::Local;

$SIG{ALRM} = sub { die "alarm signal\n" };

my $fatnode_text = Object::Remote::Connector::Local->new(timeout => 1)->fatnode_text;

#this simulates a node that has hung before it reaches
#the watchdog initialization - it's an edge case that
#could cause remote processes to not get cleaned up
#if it's not handled right
eval {
  no warnings 'once';
  $Object::Remote::FatNode::INHIBIT_RUN_NODE = 1;
  eval $fatnode_text;

  if ($@) {
      die "could not eval fatnode text: $@";
  }

  while(1) {
      sleep(1);
  }
};

is($@, "alarm signal\n", "Alarm handler was invoked");

done_testing;

