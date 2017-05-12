package Monitoring::GLPlugin::SNMP::MibsAndOids::RAPIDCITYMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'RAPID-CITY-MIB'} = {
  url => '',
  name => 'RAPID-CITY-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'RAPID-CITY-MIB'} = 
  '1.3.6.1.4.1.2272';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'RAPID-CITY-MIB'} = {
  'rcSysCpuUtil' => '1.3.6.1.4.1.2272.1.1.20',
  'rcSysDramSize' => '1.3.6.1.4.1.2272.1.1.46',
  'rcSysDramUsed' => '1.3.6.1.4.1.2272.1.1.47',
  'rcSysDramFree' => '1.3.6.1.4.1.2272.1.1.48',
  'rcChasSerialNumber' => '1.3.6.1.4.1.2272.1.4.2',
  'rcChasHardwareRevision' => '1.3.6.1.4.1.2272.1.4.3',
  'rcChasNumSlots' => '1.3.6.1.4.1.2272.1.4.4',
  'rcChasNumPorts' => '1.3.6.1.4.1.2272.1.4.5',
  'rcChasTestResult' => '1.3.6.1.4.1.2272.1.4.6',
  'rcChasTestResultDefinition' => {
    '1' => 'other',
    '2' => 'ok',
    '3' => 'crceeprom',
    '4' => 'timer',
    '5' => 'procdram',
    '6' => 'led',
    '7' => 'formaccpuaccess',
    '8' => 'asiccpuaccess',
    '9' => 'memory',
    '10' => 'loopback',
  },
  'rcChasFan' => '1.3.6.1.4.1.2272.1.4.7',
  'rcChasFanTable' => '1.3.6.1.4.1.2272.1.4.7.1',
  'rcChasFanEntry' => '1.3.6.1.4.1.2272.1.4.7.1.1',
  'rcChasFanId' => '1.3.6.1.4.1.2272.1.4.7.1.1.1',
  'rcChasFanOperStatus' => '1.3.6.1.4.1.2272.1.4.7.1.1.2',
  'rcChasFanOperStatusDefinition' => {
    '1' => 'unknown',
    '2' => 'up',
    '3' => 'down',
  },
  'rcChasFanAmbientTemperature' => '1.3.6.1.4.1.2272.1.4.7.1.1.3',
  'rcChasPowerSupply' => '1.3.6.1.4.1.2272.1.4.8',
  'rcChasPowerSupplyTable' => '1.3.6.1.4.1.2272.1.4.8.1',
  'rcChasPowerSupplyEntry' => '1.3.6.1.4.1.2272.1.4.8.1.1',
  'rcChasPowerSupplyId' => '1.3.6.1.4.1.2272.1.4.8.1.1.1',
  'rcChasPowerSupplyOperStatus' => '1.3.6.1.4.1.2272.1.4.8.1.1.2',
  'rcChasPowerSupplyOperStatusDefinition' => {
    '1' => 'unknown',
    '2' => 'empty',
    '3' => 'up',
    '4' => 'down',
  },
  'rcChasPowerSupplyDetailTable' => '1.3.6.1.4.1.2272.1.4.8.2',
  'rcChasPowerSupplyDetailEntry' => '1.3.6.1.4.1.2272.1.4.8.2.1',
  'rcChasPowerSupplyDetailId' => '1.3.6.1.4.1.2272.1.4.8.2.1.1',
  'rcChasPowerSupplyDetailType' => '1.3.6.1.4.1.2272.1.4.8.2.1.2',
  'rcChasPowerSupplyDetailTypeDefinition' => {
    '0' => 'unknown',
    '1' => 'ac',
    '2' => 'dc',
  },
  'rcChasPowerSupplyDetailSerialNumber' => '1.3.6.1.4.1.2272.1.4.8.2.1.3',
  'rcChasPowerSupplyDetailHardwareRevision' => '1.3.6.1.4.1.2272.1.4.8.2.1.4',
  'rcChasPowerSupplyDetailPartNumber' => '1.3.6.1.4.1.2272.1.4.8.2.1.5',
  'rcChasPowerSupplyDetailDescription' => '1.3.6.1.4.1.2272.1.4.8.2.1.6',
  'rc2kChassisPortOperStatus' => '1.3.6.1.4.1.2272.1.100.1.1.0',
  'rc2kChassisTemperature' => '1.3.6.1.4.1.2272.1.100.1.2.0',
  'rc2kChassisAmbientLowerTemperature' => '1.3.6.1.4.1.2272.1.100.1.3.0',
  'rc2kChassisAmbientUpperTemperature' => '1.3.6.1.4.1.2272.1.100.1.4.0',
};


1;

__END__
