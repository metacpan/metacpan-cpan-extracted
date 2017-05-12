use strict;
use warnings;
use Data::Dumper;

use Test::More;

use_ok('Net::SolarWinds::REST::Batch');



isa_ok(new Net::SolarWinds::REST::Batch,'Net::SolarWinds::REST::Batch');

SKIP: {

   skip "ENV: TEST_HOST, TEST_PASS, TEST_SERVER, and TEST_USER must be set!", 11
     unless 4==grep {defined($_)} @ENV{qw(TEST_HOST TEST_USER TEST_PASS TEST_SERVER)};

   my $host=$ENV{TEST_HOST};
   
   #my $log=Net::SolarWinds::Log->new(filename=>'stdout',fh=>\*STDOUT);
   #$log->set_loglevel(Net::SolarWinds::Log->LOG_INFO);
   my $rest=new Net::SolarWinds::REST::Batch(
     USER=>$ENV{TEST_USER},
     PASS=>$ENV{TEST_PASS},
     SERVER=>$ENV{TEST_SERVER},
     #log=>$log,
   );
   my $result=$rest->get_node($host);
   ok($result,'testing get_node using ENV: TEST_HOST');
  
   SKIP: {
     skip "Could not find nodeid!", 11 unless $result;
     my $nodeid=$result->get_data->{NodeID};
     my $ip=$result->get_data->{IPAddress};
     my $data=$result->get_data;
     if(0){
       my $result=$rest->add_volumes($nodeid,'/var');
       ok($result,"test at your own risk!") or diag($result);
     }

     # try the other 2 ways next
     ok($rest->get_node($nodeid),'checking get_node NodeID');
     ok($rest->get_node($ip),'checking get_node IPAddress');

     ok($rest->getPollerInterfaceMap($nodeid),'checking getPollerInterfaceMap');
     ok($rest->get_poller_map($nodeid),'checking get_poller_map');
     ok($rest->GetNodeInterfacePollers($nodeid),'checking GetNodeInterfacePollers');
   }
}

done_testing;
