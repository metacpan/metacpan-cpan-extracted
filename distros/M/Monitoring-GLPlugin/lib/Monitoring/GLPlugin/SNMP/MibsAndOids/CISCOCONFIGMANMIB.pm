package Monitoring::GLPlugin::SNMP::MibsAndOids::CISCOCONFIGMANMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'CISCO-CONFIG-MAN-MIB'} = {
  url => '',
  name => 'CISCO-CONFIG-MAN-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-CONFIG-MAN-MIB'} = {
  'ciscoConfigManMIBObjects' => '1.3.6.1.4.1.9.9.43.1',
  'ccmHistory' => '1.3.6.1.4.1.9.9.43.1.1',
  'ccmHistoryRunningLastChanged' => '1.3.6.1.4.1.9.9.43.1.1.1.0',
  'ccmHistoryRunningLastSaved' => '1.3.6.1.4.1.9.9.43.1.1.2.0',
  'ccmHistoryStartupLastChanged' => '1.3.6.1.4.1.9.9.43.1.1.3.0',
  'ccmHistoryMaxEventEntries' => '1.3.6.1.4.1.9.9.43.1.1.4.0',
  'ccmHistoryEventEntriesBumped' => '1.3.6.1.4.1.9.9.43.1.1.5.0',
  'ccmCLIHistory' => '1.3.6.1.4.1.9.9.43.1.2',
  'ccmCLICfg' => '1.3.6.1.4.1.9.9.43.1.3',
  'ccmCTIDObjects' => '1.3.6.1.4.1.9.9.43.1.4',
};


1;

__END__
