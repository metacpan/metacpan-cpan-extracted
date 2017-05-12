package Monitoring::GLPlugin::SNMP::MibsAndOids::NETSCREENRESOURCEMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'NETSCREEN-RESOURCE-MIB'} = {
  url => '',
  name => 'NETSCREEN-RESOURCE-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'NETSCREEN-RESOURCE-MIB'} = {
  'nsResCpuAvg' => '1.3.6.1.4.1.3224.16.1.1.0',
  'nsResCpuLast1Min' => '1.3.6.1.4.1.3224.16.1.2.0',
  'nsResCpuLast5Min' => '1.3.6.1.4.1.3224.16.1.3.0',
  'nsResCpuLast15Min' => '1.3.6.1.4.1.3224.16.1.4.0',
  'nsResMemAllocate' => '1.3.6.1.4.1.3224.16.2.1.0',
  'nsResMemLeft' => '1.3.6.1.4.1.3224.16.2.2.0',
  'nsResMemFrag' => '1.3.6.1.4.1.3224.16.2.3.0',
  'nsResSessAllocate' => '1.3.6.1.4.1.3224.16.3.2.0',
  'nsResSessMaxium' => '1.3.6.1.4.1.3224.16.3.3.0',
  'nsResSessFailed' => '1.3.6.1.4.1.3224.16.3.4.0',
};


1;

__END__
