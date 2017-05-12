use strict;
use threads;
use Data::Dumper;
use Test::More tests => 16;
BEGIN { use_ok('Net::SIGTRAN::SCTP') };

use Net::SIGTRAN::M3UA;

my $server=new Net::SIGTRAN::M3UA(
   PORT=>12346
);
cmp_ok($server,'>',0,'Unable to create Net::SIGTRAN::M3UA');
my $ssock=$server->bind();
cmp_ok($ssock,'>',0,'Unable to bind');

threads->create(\&serverthread,$server,$ssock)->detach();
#&serverthread($server,$ssock);

my $client=new Net::SIGTRAN::M3UA(
   HOST=>'127.0.0.1',
   PORT=>12346
);
cmp_ok($client,'>',0,'Unable to create client Net::SIGTRAN::M3UA');
my $csock=$client->connect();
cmp_ok($csock,'>',0,'Unable to connect');
&clientread('ASPUP',$client,$csock); #Read ASPUP
&clientread('ASPUP_ACK',$client,$csock); #Read ASPUP_ACK
&clientread('ASPAC',$client,$csock); #Read ASPAC
&clientread('ASPAC_ACK', $client,$csock); #Read ASPAC_ACK
&clientread('NTFY', $client,$csock); #Read NTFY
&clientread('DAUD', $client,$csock); #Read DAUD
&clientread('DAVA', $client,$csock); #Read DAVA
&clientread('DUNA', $client,$csock); #Read DUNA
&clientread('BEAT', $client,$csock); #Read BEAT
&clientread('BEAT_ACK', $client,$csock); #Read BEAT_ACK

$client->close($csock);

sub clientread {
   my $title=shift;
   my $client=shift;
   my $csock=shift;
   my ($buffer)=$client->readpdu($csock);
   if ($buffer) {
      if ($buffer->{'M3UA'} =~/Invalid|Unknown/) {
         fail("Reading $title test");
      } else {
         pass("reading $title test"); 
	 print STDERR Dumper($buffer);
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
   $server->ASPUP($connSock);
   $server->ASPUP_ACK($connSock);
   $server->ASPAC($connSock,2,0);
   $server->ASPAC_ACK($connSock,2,0);
   $server->NTFY($connSock,1,2);
   $server->DAUD($connSock,12,0,1142);
   $server->DAVA($connSock,12,0,1142);
   $server->DUNA($connSock,12,0,1142);
   my $heartbeat='0005000101ffd8398047021227041120';
   $server->BEAT($connSock,$heartbeat);
   $server->BEAT_ACK($connSock,$heartbeat);
   $server->close($connSock);
}
 
