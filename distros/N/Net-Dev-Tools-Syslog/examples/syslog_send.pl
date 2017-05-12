#!/usr/bin/perl
#
# Perl script to test Net::Dev::Tools::Syslog sending
#
#


use strict;
use Net::Dev::Tools::Syslog;


my ($send_obj, $error,
    $facility, $severity,
    $ok,
);

my $server = '192.168.1.1';
my $port   = 7971;
my $proto  = 'udp';


my $test_send_all = 1;
my $sleep         = 0;
my $pid           = $$;



# create send object

($send_obj, $error) = Syslog->send(
   -server    => $server,
   -port      => $port,
   -proto     => $proto,
);

unless ($send_obj) {
   myprintf("ERROR: Syslog send failed: %s\n", $error);
   exit(1);
}

# send syslog message
printf("Sending syslog to %s:%s proto: %s  pid: %s\n", $server, $port, $proto, $pid );

# send all syslog type message
if ($test_send_all) {
   foreach $facility (@Syslog::FACILITY) {
      foreach $severity (@Syslog::SEVERITY) {
         #printf("send message:  %-10s  %s\n", $facility, $severity);
         ($ok, $error) = $send_obj->send_message(
            -facility  => $facility,
            -severity  => $severity,
            -hostname  => 1,
            -device    => 'myTestHost',
            -noTag     => 0,
            #-tag       => 'myTag',
            -pid       => 1,
            -content   => 'my syslog message content',
         );
         if(!$ok) {
            printf("ERROR: syslog->send_msg: %s\n", $error);
         }
         sleep $sleep;
      }
   }
}
else {
   ($ok, $error) = $send_obj->send_message(
      -hostname  => 1,
   );
   if(!$ok) {
      printf("ERROR: syslog->send_msg: %s\n", $error);
   }
}


exit(0);
