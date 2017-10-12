$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'OPENBSD-SENSORS-MIB'} = {
  url => '',
  name => 'OPENBSD-SENSORS-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'OPENBSD-SENSORS-MIB'} =
  '1.3.6.1.4.1.30155.2';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'OPENBSD-SENSORS-MIB'} = {
  # openBSD.sensorMIBObjects
  sensorNumber => '1.3.6.1.4.1.30155.2.1.1',
  sensorTable => '1.3.6.1.4.1.30155.2.1.2',
  sensorEntry => '1.3.6.1.4.1.30155.2.1.2.1',
  sensorIndex => '1.3.6.1.4.1.30155.2.1.2.1.1',
  sensorDescr => '1.3.6.1.4.1.30155.2.1.2.1.2',
  sensorType => '1.3.6.1.4.1.30155.2.1.2.1.3',
  sensorDevice => '1.3.6.1.4.1.30155.2.1.2.1.4',
  sensorValue => '1.3.6.1.4.1.30155.2.1.2.1.5',
  sensorUnits => '1.3.6.1.4.1.30155.2.1.2.1.6',
  sensorStatus => '1.3.6.1.4.1.30155.2.1.2.1.7',
  sensorStatusDefinition => 'OPENBSD-SENSORS-MIB::sensorStatus',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'OPENBSD-SENSORS-MIB'} = {
  sensorStatus => {
    '0' => 'unspecified',
    '1' => 'ok',
    '2' => 'warn',
    '3' => 'critical',
    '4' => 'unknown',
  },
};

