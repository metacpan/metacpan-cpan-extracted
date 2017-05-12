package Monitoring::GLPlugin::SNMP::MibsAndOids::ENTITYSENSORMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'ENTITY-SENSOR-MIB'} = {
  url => '',
  name => 'ENTITY-SENSOR-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'ENTITY-SENSOR-MIB'} = {
  'entitySensorObjects' => '1.3.6.1.2.1.99.1',
  'entPhySensorTable' => '1.3.6.1.2.1.99.1.1',
  'entPhySensorEntry' => '1.3.6.1.2.1.99.1.1.1',
  'entPhySensorType' => '1.3.6.1.2.1.99.1.1.1.1',
  'entPhySensorTypeDefinition' => {
    '1' => 'other',
    '2' => 'unknown',
    '3' => 'voltsAC',
    '4' => 'voltsDC',
    '5' => 'amperes',
    '6' => 'watts',
    '7' => 'hertz',
    '8' => 'celsius',
    '9' => 'percentRH',
    '10' => 'rpm',
    '11' => 'cmm',
    '12' => 'truthvalue',
  },
  'entPhySensorScale' => '1.3.6.1.2.1.99.1.1.1.2',
  'entPhySensorScaleDefinition' => {
    '1' => 'yocto',
    '2' => 'zepto',
    '3' => 'atto',
    '4' => 'femto',
    '5' => 'pico',
    '6' => 'nano',
    '7' => 'micro',
    '8' => 'milli',
    '9' => 'units',
    '10' => 'kilo',
    '11' => 'mega',
    '12' => 'giga',
    '13' => 'tera',
    '14' => 'exa',
    '15' => 'peta',
    '16' => 'zetta',
    '17' => 'yotta',
  },
  'entPhySensorPrecision' => '1.3.6.1.2.1.99.1.1.1.3',
  'entPhySensorValue' => '1.3.6.1.2.1.99.1.1.1.4',
  'entPhySensorOperStatus' => '1.3.6.1.2.1.99.1.1.1.5',
  'entPhySensorOperStatusDefinition' => {
    '1' => 'ok',
    '2' => 'unavailable',
    '3' => 'nonoperational',
  },
  'entPhySensorUnitsDisplay' => '1.3.6.1.2.1.99.1.1.1.6',
  'entPhySensorValueTimeStamp' => '1.3.6.1.2.1.99.1.1.1.7',
  'entPhySensorValueUpdateRate' => '1.3.6.1.2.1.99.1.1.1.8',
  'entitySensorConformance' => '1.3.6.1.2.1.99.3',
  'entitySensorCompliances' => '1.3.6.1.2.1.99.3.1',
  'entitySensorGroups' => '1.3.6.1.2.1.99.3.2',
};


1;

__END__
