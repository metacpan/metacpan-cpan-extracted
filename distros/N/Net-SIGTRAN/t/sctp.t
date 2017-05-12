use strict;
use threads;
use Data::Dumper;
use Test::More tests => 7;
BEGIN { use_ok('Net::SIGTRAN::SCTP') };

use Net::SIGTRAN::SCTP;

my $echostring='Hello World';

my $server=new Net::SIGTRAN::SCTP(
   PORT=>12345
);
cmp_ok($server,'>',0,'Unable to create Net::SIGTRAN::SCTP');
my $ssock=$server->bind();
cmp_ok($ssock,'>',0,'Unable to bind');

threads->create(\&serverthread,$server,$ssock)->detach();

my $client=new Net::SIGTRAN::SCTP(
   HOST=>'127.0.0.1',
   PORT=>12345
);
cmp_ok($client,'>',0,'Unable to create client Net::SIGTRAN::SCTP');
my $csock=$server->connect();
cmp_ok($csock,'>',0,'Unable to connect');
&clientread($echostring, $client,$csock); #Test Socket
$client->close($csock);

sub clientread {
   my $title=shift;
   my $client=shift;
   my $csock=shift;
   my ($readlen,$buffer)= $client->recieve($csock,1000);

   if ($buffer) {
      if ($buffer eq $echostring) {
         pass("Reading '$title' test");
      } else {
         fail("Reading '$title' test, get '$buffer'");
      }
   } else {
      fail("Reading $title test, Client Socket does not recieve any packet");
   }
}

sub serverthread {
   my $server=shift;
   my $ssock=shift;
   my $connSock = $server->accept($ssock);
   cmp_ok($connSock,'>',0,'Unable to accept Client Connection');
   print "Sending to $connSock\n";
   $server->send($connSock,0,length($echostring),$echostring);
   $server->close($connSock);
}
 
