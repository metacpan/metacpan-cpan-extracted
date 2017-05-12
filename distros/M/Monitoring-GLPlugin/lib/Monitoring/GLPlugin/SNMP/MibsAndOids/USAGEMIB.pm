package Monitoring::GLPlugin::SNMP::MibsAndOids::USAGEMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'USAGE-MIB'} = {
  url => '',
  name => 'USAGE-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'USAGE-MIB'} = {
  'deviceUsageTable' => '1.3.6.1.4.1.3417.2.4.1.1',
  'deviceUsageEntry' => '1.3.6.1.4.1.3417.2.4.1.1.1',
  'deviceUsageIndex' => '1.3.6.1.4.1.3417.2.4.1.1.1.1',
  'deviceUsageTrapEnabled' => '1.3.6.1.4.1.3417.2.4.1.1.1.2',
  'deviceUsageName' => '1.3.6.1.4.1.3417.2.4.1.1.1.3',
  'deviceUsagePercent' => '1.3.6.1.4.1.3417.2.4.1.1.1.4',
  'deviceUsageHigh' => '1.3.6.1.4.1.3417.2.4.1.1.1.5',
  'deviceUsageStatus' => '1.3.6.1.4.1.3417.2.4.1.1.1.6',
  'deviceUsageStatusDefinition' => {
    '1' => 'ok',
    '2' => 'high',
  },
  'deviceUsageTime' => '1.3.6.1.4.1.3417.2.4.1.1.1.7',
};


1;

__END__
