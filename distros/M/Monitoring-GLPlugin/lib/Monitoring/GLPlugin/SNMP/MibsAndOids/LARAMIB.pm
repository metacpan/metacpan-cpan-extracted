package Monitoring::GLPlugin::SNMP::MibsAndOids::LARAMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'LARA-MIB'} = {
  url => '',
  name => 'LARA-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'LARA-MIB'} = {
  'lantronix' => '1.3.6.1.4.1.244',
  'products' => '1.3.6.1.4.1.244.1',
  'sls' => '1.3.6.1.4.1.244.1.11',
  'board' => '1.3.6.1.4.1.244.1.11.1',
  'Info' => '1.3.6.1.4.1.244.1.11.1.1',
  'firmwareVersion' => '1.3.6.1.4.1.244.1.11.1.1.1',
  'serialNumber' => '1.3.6.1.4.1.244.1.11.1.1.2',
  'IP' => '1.3.6.1.4.1.244.1.11.1.1.3',
  'Netmask' => '1.3.6.1.4.1.244.1.11.1.1.4',
  'Gateway' => '1.3.6.1.4.1.244.1.11.1.1.5',
  'MAC' => '1.3.6.1.4.1.244.1.11.1.1.6',
  'HardwareRev' => '1.3.6.1.4.1.244.1.11.1.1.7',
  'eventType' => '1.3.6.1.4.1.244.1.11.1.1.8',
  'eventDesc' => '1.3.6.1.4.1.244.1.11.1.1.9',
  'userLoginName' => '1.3.6.1.4.1.244.1.11.1.1.10',
  'remoteHost' => '1.3.6.1.4.1.244.1.11.1.1.11',
  'Users' => '1.3.6.1.4.1.244.1.11.1.2',
  'Actions' => '1.3.6.1.4.1.244.1.11.1.3',
  'host' => '1.3.6.1.4.1.244.1.11.2',
  'HostInfo' => '1.3.6.1.4.1.244.1.11.2.1',
  'checkHostPower' => '1.3.6.1.4.1.244.1.11.2.1.1',
  'checkHostPowerDefinition' => {
    '1' => 'hasPower',
    '2' => 'hasnoPower',
    '3' => 'error',
    '4' => 'notsupported',
  },
  'HostActions' => '1.3.6.1.4.1.244.1.11.2.2',
  'Common' => '1.3.6.1.4.1.244.1.11.3',
  'Traps' => '1.3.6.1.4.1.244.1.11.4',
  'DummyTrap' => '1.3.6.1.4.1.244.1.11.4.1',
  'Loginfailed' => '1.3.6.1.4.1.244.1.11.4.2',
  'Loginsuccess' => '1.3.6.1.4.1.244.1.11.4.3',
  'SecurityViolation' => '1.3.6.1.4.1.244.1.11.4.4',
  'Generic' => '1.3.6.1.4.1.244.1.11.4.5',
};


1;

__END__
