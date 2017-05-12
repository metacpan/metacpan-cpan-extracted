use strict;
use warnings;

use Test::More;
use Data::Dumper;

use_ok('Net::SolarWinds::REST');



isa_ok(new Net::SolarWinds::REST,'Net::SolarWinds::REST');


{
  my $sw=new SolarWinds::Test;
  cmp_ok($sw->bogus('123'),'eq','should be a query with "123"',"Internals auto query resolution");
}

SKIP: {
   
   skip "ENV: TEST_HOST, TEST_PASS, TEST_SERVER, and TEST_USER must be set!", 13
     unless 4==grep {defined($_)} @ENV{qw(TEST_HOST TEST_USER TEST_PASS TEST_SERVER)};
  
   my $host=$ENV{TEST_HOST};
   my $rest=new Net::SolarWinds::REST(
     USER=>$ENV{TEST_USER},
     PASS=>$ENV{TEST_PASS},
     SERVER=>$ENV{TEST_SERVER},
   );

   my $result=$rest->getNodesByDisplayName($host);
   ok($result,"checking getNodesByDisplayName") or diag($result);

   # we don't really care if there are results, we just care that there isn't an error
   foreach my $method (qw(
      getApplicationTemplate 
      getNodesByIp 
      getVolumeTypeMap 
      getEngines)) {
     ok($rest->$method('bogus'),"checking $method");
   }
   ok($rest->getEngine('bogus','bogus'),"checking getEngine");

   
   my $nodeid=$#{$result->get_data->{results}}!=-1 ? $result->get_data->{results}->[0]->{NodeID} : undef;
   SKIP: {
     skip "Test Node not found",6 unless $nodeid;
     ok($rest->getNodesByID($nodeid),"checking getNodesByID");
     ok($rest->getTemplatesOnNode($nodeid),"checking getTemplatesOnNode");
     ok($rest->getNodeUri($nodeid),"checking getNodeUri");
     ok($rest->getVolumeMap($nodeid),"checking getVolumeMap");
     ok($rest->getInterfacesOnNode($nodeid),"checking getInterfacesOnNode");
     my $result=$rest->GetNodePollers($nodeid,'N');
     ok($result,"checking GetNodePollers") or diag($result);
   }

}

# used for internal testing.. should never be indexed by cpan.. I hope..
{
package # internal testing
SolarWinds::Test;
use base qw(Net::SolarWinds::REST);
use constant SWQL_bogus=>'should be a query with "%s"';
sub bogus {
  my ($sw,@args)=@_;
  $sw->query_lookup(@args);
}
}

done_testing;
