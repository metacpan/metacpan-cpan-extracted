package Monitoring::GLPlugin::SNMP::MibsAndOids::SENSORMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'SENSOR-MIB'} = {
  url => '',
  name => 'SENSOR-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'SENSOR-MIB'} = {
  'deviceSensorValueTable' => '1.3.6.1.4.1.3417.2.1.1.1.1',
  'deviceSensorValueEntry' => '1.3.6.1.4.1.3417.2.1.1.1.1.1',
  'deviceSensorIndex' => '1.3.6.1.4.1.3417.2.1.1.1.1.1.1',
  'deviceSensorTrapEnabled' => '1.3.6.1.4.1.3417.2.1.1.1.1.1.2',
  'deviceSensorUnits' => '1.3.6.1.4.1.3417.2.1.1.1.1.1.3',
  'deviceSensorUnitsDefinition' => {
    '1' => 'other',
    '2' => 'truthvalue',
    '3' => 'specialEnum',
    '4' => 'volts',
    '5' => 'celsius',
    '6' => 'rpm',
  },
  'deviceSensorScale' => '1.3.6.1.4.1.3417.2.1.1.1.1.1.4',
  'deviceSensorValue' => '1.3.6.1.4.1.3417.2.1.1.1.1.1.5',
  'deviceSensorCode' => '1.3.6.1.4.1.3417.2.1.1.1.1.1.6',
  'deviceSensorCodeDefinition' => {
    '1' => 'ok',
    '2' => 'unknown',
    '3' => 'not-installed',
    '4' => 'voltage-low-warning',
    '5' => 'voltage-low-critical',
    '6' => 'no-power',
    '7' => 'voltage-high-warning',
    '8' => 'voltage-high-critical',
    '9' => 'voltage-high-severe',
    '10' => 'temperature-high-warning',
    '11' => 'temperature-high-critical',
    '12' => 'temperature-high-severe',
    '13' => 'fan-slow-warning',
    '14' => 'fan-slow-critical',
    '15' => 'fan-stopped',
  },
  'deviceSensorStatus' => '1.3.6.1.4.1.3417.2.1.1.1.1.1.7',
  'deviceSensorStatusDefinition' => {
    '1' => 'ok',
    '2' => 'unavailable',
    '3' => 'nonoperational',
  },
  'deviceSensorTimeStamp' => '1.3.6.1.4.1.3417.2.1.1.1.1.1.8',
  'deviceSensorName' => '1.3.6.1.4.1.3417.2.1.1.1.1.1.9',
};


1;

__END__
