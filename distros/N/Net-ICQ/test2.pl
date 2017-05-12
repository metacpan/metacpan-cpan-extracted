#==================
# NOTE: this is a work in progress.  don't expect it to do
# anything useful yet.  I just put it in CVS so others could
# see a more complex example of Net::ICQ usage.
#==================

#!/usr/bin/perl

use strict;
use Net::ICQ;
use Data::Dumper;


my (
    $icq,
    $ready
   );


$ready = 0;

$icq = Net::ICQ->new($ARGV[0], $ARGV[1])
    or print ("Please specify a UIN and password on the command line\n"), exit;

$icq->{_debug} = 1;

# register dump_event as the handler for ALL (!) events
foreach (values(%Net::ICQ::srv_codes)) {
  $icq->add_handler($_, \&dump_event);
}

$icq->add_handler('SRV_X2', \&handle_x2);
$icq->add_handler('SRV_LOGIN_REPLY', \&handle_login_reply);

# register a SIGINT handler, so ctrl-c will trigger a clean shutdown
$SIG{INT} = \&disconnect;


$icq->connect();
print "connecting...\n";
while (!$ready) {
  $icq->do_one_loop;
}
print "ready\n";

print "looping (ctrl-c to exit)\n";
$icq->start;





# dump event contents
sub dump_event {
  my ($icq, $event) = @_;

  print Dumper($event);
}


# send CMD_ACK_MESSAGES on X2 from server to keep it from sending us
# any received offline msgs on next login
sub handle_x2 {
  my ($icq, $event) = @_;

  print (":X2\n");
  $icq->send_event('CMD_ACK_MESSAGES');
}


# set ready to 1 to signal we can send events now
sub handle_login_reply {
  my ($icq, $event) = @_;

  print (":LOGIN_REPLY\n");
  $ready = 1;
}


sub disconnect {
  $icq->disconnect();
  exit();
}
