package Monitoring::GLPlugin::SNMP::MibsAndOids::HPICFCHASSISMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'HP-ICF-CHASSIS-MIB'} = {
  url => '',
  name => 'HP-ICF-CHASSIS-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'HP-ICF-CHASSIS-MIB'} = {
  'hpicfSensorTable' => '1.3.6.1.4.1.11.2.14.11.1.2.6',
  'hpicfSensorEntry' => '1.3.6.1.4.1.11.2.14.11.1.2.6.1',
  'hpicfSensorIndex' => '1.3.6.1.4.1.11.2.14.11.1.2.6.1.1',
  'hpicfSensorObjectId' => '1.3.6.1.4.1.11.2.14.11.1.2.6.1.2',
  'hpicfSensorObjectIdDefinition' => {
    '1' => 'fan sensor',
    '2' => 'power supply',
    '3' => 'redundant power supply',
    '4' => 'over-temperature sensor',
  },
  'hpicfSensorNumber' => '1.3.6.1.4.1.11.2.14.11.1.2.6.1.3',
  'hpicfSensorStatus' => '1.3.6.1.4.1.11.2.14.11.1.2.6.1.4',
  'hpicfSensorStatusDefinition' => {
    '1' => 'unknown',
    '2' => 'bad',
    '3' => 'warning',
    '4' => 'good',
    '5' => 'notPresent',
  },
  'hpicfSensorWarnings' => '1.3.6.1.4.1.11.2.14.11.1.2.6.1.5',
  'hpicfSensorFailures' => '1.3.6.1.4.1.11.2.14.11.1.2.6.1.6',
  'hpicfSensorDescr' => '1.3.6.1.4.1.11.2.14.11.1.2.6.1.7',
};


1;

__END__
