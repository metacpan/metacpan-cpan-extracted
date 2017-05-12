package Monitoring::GLPlugin::SNMP::MibsAndOids::PROXYMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'PROXY-MIB'} = {
  url => '',
  name => 'PROXY-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'PROXY-MIB'} = {
  'proxyMemUsage' => '1.3.6.1.3.25.17.1.1.0',
  'proxyStorage' => '1.3.6.1.3.25.17.1.2.0',
  'proxyCpuUsage' => '1.3.6.1.3.25.17.1.3.0',
  'proxyUpTime' => '1.3.6.1.3.25.17.1.4.0',
  'proxyConfig' => '1.3.6.1.3.25.17.2',
  'proxyAdmin' => '1.3.6.1.3.25.17.2.1.0',
  'proxySoftware' => '1.3.6.1.3.25.17.2.2.0',
  'proxyVersion' => '1.3.6.1.3.25.17.2.3.0',
  'proxySysPerf' => '1.3.6.1.3.25.17.3.1',
  'proxyCpuLoad' => '1.3.6.1.3.25.17.3.1.1.0',
  'proxyNumObjects' => '1.3.6.1.3.25.17.3.1.2.0',
  'proxyProtoPerf' => '1.3.6.1.3.25.17.3.2',
};


1;

__END__
