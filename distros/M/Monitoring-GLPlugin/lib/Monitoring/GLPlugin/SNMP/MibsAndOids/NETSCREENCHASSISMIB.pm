package Monitoring::GLPlugin::SNMP::MibsAndOids::NETSCREENCHASSISMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'NETSCREEN-CHASSIS-MIB'} = {
  url => '',
  name => 'NETSCREEN-CHASSIS-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'NETSCREEN-CHASSIS-MIB'} = {
  'nsPowerTable' => '1.3.6.1.4.1.3224.21.1',
  'nsPowerEntry' => '1.3.6.1.4.1.3224.21.1.1',
  'nsPowerId' => '1.3.6.1.4.1.3224.21.1.1.1',
  'nsPowerStatus' => '1.3.6.1.4.1.3224.21.1.1.2',
  'nsPowerStatusDefinition' => {
    '0' => 'fail',
    '1' => 'good',
  },
  'nsPowerDesc' => '1.3.6.1.4.1.3224.21.1.1.3',
  'nsFanTable' => '1.3.6.1.4.1.3224.21.2',
  'nsFanEntry' => '1.3.6.1.4.1.3224.21.2.1',
  'nsFanId' => '1.3.6.1.4.1.3224.21.2.1.1',
  'nsFanStatus' => '1.3.6.1.4.1.3224.21.2.1.2',
  'nsFanStatusDefinition' => {
    '0' => 'fail',
    '1' => 'good',
    '2' => 'notInstalled',
  },
  'nsFanDesc' => '1.3.6.1.4.1.3224.21.2.1.3',
  'sysBatteryStatus' => '1.3.6.1.4.1.3224.21.3.0',
  'sysBatteryStatusDefinition' => {
    '1' => 'good',
    '2' => 'error',
  },
  'nsTemperatureTable' => '1.3.6.1.4.1.3224.21.4',
  'nsTemperatureEntry' => '1.3.6.1.4.1.3224.21.4.1',
  'nsTemperatureId' => '1.3.6.1.4.1.3224.21.4.1.1',
  'nsTemperatureSlotId' => '1.3.6.1.4.1.3224.21.4.1.2',
  'nsTemperatureCur' => '1.3.6.1.4.1.3224.21.4.1.3',
  'nsTemperatureDesc' => '1.3.6.1.4.1.3224.21.4.1.4',
  'nsSlotTable' => '1.3.6.1.4.1.3224.21.5',
  'nsSlotEntry' => '1.3.6.1.4.1.3224.21.5.1',
  'nsSlotId' => '1.3.6.1.4.1.3224.21.5.1.1',
  'nsSlotType' => '1.3.6.1.4.1.3224.21.5.1.2',
  'nsSlotStatus' => '1.3.6.1.4.1.3224.21.5.1.3',
  'nsSlotStatusDefinition' => {
    '0' => 'fail',
    '1' => 'good',
    '2' => 'notInstalled',
  },
  'nsSlotSN' => '1.3.6.1.4.1.3224.21.5.1.4',
};


1;

__END__
