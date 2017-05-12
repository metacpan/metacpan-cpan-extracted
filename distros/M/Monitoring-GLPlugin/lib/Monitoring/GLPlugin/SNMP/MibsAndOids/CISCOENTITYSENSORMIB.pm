package Monitoring::GLPlugin::SNMP::MibsAndOids::CISCOENTITYSENSORMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'CISCO-ENTITY-SENSOR-MIB'} = {
  url => '',
  name => 'CISCO-ENTITY-SENSOR-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::requirements->{'CISCO-ENTITY-SENSOR-MIB'} = [
  'SNMPv2-TC-v1-MIB',
];

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'CISCO-ENTITY-SENSOR-MIB'} = 
  '1.3.6.1.4.1.9.9.91';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-ENTITY-SENSOR-MIB'} = {
  'entSensorValueTable' => '1.3.6.1.4.1.9.9.91.1.1.1',
  'entSensorValueEntry' => '1.3.6.1.4.1.9.9.91.1.1.1.1',
  'entSensorType' => '1.3.6.1.4.1.9.9.91.1.1.1.1.1',
  'entSensorTypeDefinition' => 'CISCO-ENTITY-SENSOR-MIB::SensorDataType',
  'entSensorScale' => '1.3.6.1.4.1.9.9.91.1.1.1.1.2',
  'entSensorScaleDefinition' => 'CISCO-ENTITY-SENSOR-MIB::SensorDataScale',
  'entSensorPrecision' => '1.3.6.1.4.1.9.9.91.1.1.1.1.3',
  'entSensorValue' => '1.3.6.1.4.1.9.9.91.1.1.1.1.4',
  'entSensorStatus' => '1.3.6.1.4.1.9.9.91.1.1.1.1.5',
  'entSensorStatusDefinition' => 'CISCO-ENTITY-SENSOR-MIB::SensorStatus',
  'entSensorValueTimeStamp' => '1.3.6.1.4.1.9.9.91.1.1.1.1.6',
  'entSensorValueUpdateRate' => '1.3.6.1.4.1.9.9.91.1.1.1.1.7',
  'entSensorMeasuredEntity' => '1.3.6.1.4.1.9.9.91.1.1.1.1.8',
  'entSensorThresholdTable' => '1.3.6.1.4.1.9.9.91.1.2.1',
  'entSensorThresholdEntry' => '1.3.6.1.4.1.9.9.91.1.2.1.1',
  'entSensorThresholdIndex' => '1.3.6.1.4.1.9.9.91.1.2.1.1.1',
  'entSensorThresholdSeverity' => '1.3.6.1.4.1.9.9.91.1.2.1.1.2',
  'entSensorThresholdSeverityDefinition' => 'CISCO-ENTITY-SENSOR-MIB::SensorThresholdSeverity',
  'entSensorThresholdRelation' => '1.3.6.1.4.1.9.9.91.1.2.1.1.3',
  'entSensorThresholdRelationDefinition' => 'CISCO-ENTITY-SENSOR-MIB::SensorThresholdRelation',
  'entSensorThresholdValue' => '1.3.6.1.4.1.9.9.91.1.2.1.1.4',
  'entSensorThresholdEvaluation' => '1.3.6.1.4.1.9.9.91.1.2.1.1.5',
  'entSensorThresholdEvaluationDefinition' => 'SNMPv2-TC-v1-MIB::TruthValue',
  'entSensorThresholdNotificationEnable' => '1.3.6.1.4.1.9.9.91.1.2.1.1.6',
  'entSensorThresholdNotificationEnableDefinition' => 'SNMPv2-TC-v1-MIB::TruthValue',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCO-ENTITY-SENSOR-MIB'} = {
  'SensorStatus' => {
    '1' => 'ok',
    '2' => 'unavailable',
    '3' => 'nonoperational',
  },
  'SensorThresholdSeverity' => {
    '1' => 'other',
    '10' => 'minor',
    '20' => 'major',
    '30' => 'critical',
  },
  'SensorThresholdRelation' => {
    '1' => 'lessThan',
    '2' => 'lessOrEqual',
    '3' => 'greaterThan',
    '4' => 'greaterOrEqual',
    '5' => 'equalTo',
    '6' => 'notEqualTo',
  },
  'SensorDataType' => {
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
    '13' => 'specialEnum',
    '14' => 'dBm',
  },
  'SensorDataScale' => {
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
};

1;

__END__
