 
use Net::UPnP::ControlPoint;

my $obj = Net::UPnP::ControlPoint->new();

@dev_list = $obj->search(st =>'upnp:rootdevice', mx => 3);

$devNum= 0;
foreach $dev (@dev_list) {
   $device_type = $dev->getdevicetype();
   if  ($device_type ne 'urn:schemas-upnp-org:device:MediaServer:1') {
       next;
   }
   print "[$devNum] : " . $dev->getfriendlyname() . "\n";
   unless ($dev->getservicebyname('urn:schemas-upnp-org:service:ContentDirectory:1')) {
       next;
   }
   $condir_service = $dev->getservicebyname('urn:schemas-upnp-org:service:ContentDirectory:1');
   unless (defined(condir_service)) {
       next;
   }
   %action_in_arg = (
           'ObjectID' => 0,
           'BrowseFlag' => 'BrowseDirectChildren',
           'Filter' => '*',
           'StartingIndex' => 0,
           'RequestedCount' => 0,
           'SortCriteria' => '',
       );
   $action_res = $condir_service->postcontrol('Browse', \%action_in_arg);
   unless ($action_res->getstatuscode() == 200) {
           next;
   }
   $actrion_out_arg = $action_res->getargumentlist();
   unless ($actrion_out_arg->{'Result'}) {
       next;
   }
   $result = $actrion_out_arg->{'Result'};
   while ($result =~ m/<dc:title>(.*?)<\/dc:title>/sgi) {
       print "\t$1\n";
   }
   $devNum++;
}