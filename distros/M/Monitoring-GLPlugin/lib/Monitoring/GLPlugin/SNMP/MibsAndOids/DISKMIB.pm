package Monitoring::GLPlugin::SNMP::MibsAndOids::DISKMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'DISK-MIB'} = {
  url => '',
  name => 'DISK-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'DISK-MIB'} = {
  'deviceDiskValueTable' => '1.3.6.1.4.1.3417.2.2.1.1.1',
  'deviceDiskValueEntry' => '1.3.6.1.4.1.3417.2.2.1.1.1.1',
  'deviceDiskIndex' => '1.3.6.1.4.1.3417.2.2.1.1.1.1.1',
  'deviceDiskTrapEnabled' => '1.3.6.1.4.1.3417.2.2.1.1.1.1.2',
  'deviceDiskStatus' => '1.3.6.1.4.1.3417.2.2.1.1.1.1.3',
  'deviceDiskStatusDefinition' => {
    '1' => 'present',
    '2' => 'initializing',
    '3' => 'inserted',
    '4' => 'offline',
    '5' => 'removed',
    '6' => 'not-present',
    '7' => 'empty',
    '8' => 'bad',
    '9' => 'unknown',
  },
  'deviceDiskTimeStamp' => '1.3.6.1.4.1.3417.2.2.1.1.1.1.4',
  'deviceDiskVendor' => '1.3.6.1.4.1.3417.2.2.1.1.1.1.5',
  'deviceDiskProduct' => '1.3.6.1.4.1.3417.2.2.1.1.1.1.6',
  'deviceDiskRevision' => '1.3.6.1.4.1.3417.2.2.1.1.1.1.7',
  'deviceDiskSerialN' => '1.3.6.1.4.1.3417.2.2.1.1.1.1.8',
  'deviceDiskBlockSize' => '1.3.6.1.4.1.3417.2.2.1.1.1.1.9',
  'deviceDiskBlockCount' => '1.3.6.1.4.1.3417.2.2.1.1.1.1.10',
};


1;

__END__
