package Monitoring::GLPlugin::SNMP::MibsAndOids::SWMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'SW-MIB'} = {
  url => '',
  name => 'SW-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'SW-MIB'} = 
  '1.3.6.1.4.1.1588.2.1.1.1';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'SW-MIB'} = {
  'sw' => '1.3.6.1.4.1.1588.2.1.1.1',
  'swFirmwareVersion' => '1.3.6.1.4.1.1588.2.1.1.1.1.6.0',
  'swSensorTable' => '1.3.6.1.4.1.1588.2.1.1.1.1.22',
  'swSensorEntry' => '1.3.6.1.4.1.1588.2.1.1.1.1.22.1',
  'swSensorIndex' => '1.3.6.1.4.1.1588.2.1.1.1.1.22.1.1',
  'swSensorType' => '1.3.6.1.4.1.1588.2.1.1.1.1.22.1.2',
  'swSensorTypeDefinition' => {
    '1' => 'temperature',
    '2' => 'fan',
    '3' => 'power-supply',
  },
  'swSensorStatus' => '1.3.6.1.4.1.1588.2.1.1.1.1.22.1.3',
  'swSensorStatusDefinition' => {
    '1' => 'unknown',
    '2' => 'faulty',
    '3' => 'below-min',
    '4' => 'nominal',
    '5' => 'above-max',
    '6' => 'absent',
  },
  'swSensorValue' => '1.3.6.1.4.1.1588.2.1.1.1.1.22.1.4',
  'swSensorInfo' => '1.3.6.1.4.1.1588.2.1.1.1.1.22.1.5',
  'swFwFabricWatchLicense' => '1.3.6.1.4.1.1588.2.1.1.1.10.1.0',
  'swFwFabricWatchLicenseDefinition' => {
    '1' => 'swFwLicensed',
    '2' => 'swFwNotLicensed',
  },
  'swFwThresholdTable' => '1.3.6.1.4.1.1588.2.1.1.1.10.3',
  'swFwThresholdEntry' => '1.3.6.1.4.1.1588.2.1.1.1.10.3.1',
  'swFwThresholdIndex' => '1.3.6.1.4.1.1588.2.1.1.1.10.3.1.1',
  'swFwStatus' => '1.3.6.1.4.1.1588.2.1.1.1.10.3.1.2',
  'swFwName' => '1.3.6.1.4.1.1588.2.1.1.1.10.3.1.3',
  'swFwLabel' => '1.3.6.1.4.1.1588.2.1.1.1.10.3.1.4',
  'swFwCurVal' => '1.3.6.1.4.1.1588.2.1.1.1.10.3.1.5',
  'swFwLastEvent' => '1.3.6.1.4.1.1588.2.1.1.1.10.3.1.6',
  'swFwLastEventVal' => '1.3.6.1.4.1.1588.2.1.1.1.10.3.1.7',
  'swFwLastEventTime' => '1.3.6.1.4.1.1588.2.1.1.1.10.3.1.8',
  'swFwLastState' => '1.3.6.1.4.1.1588.2.1.1.1.10.3.1.9',
  'swFwBehaviorType' => '1.3.6.1.4.1.1588.2.1.1.1.10.3.1.10',
  'swFwBehaviorInt' => '1.3.6.1.4.1.1588.2.1.1.1.10.3.1.11',
  'swCpuOrMemoryUsage' => '1.3.6.1.4.1.1588.2.1.1.1.26',
  'swCpuUsage' => '1.3.6.1.4.1.1588.2.1.1.1.26.1',
  'swCpuNoOfRetries' => '1.3.6.1.4.1.1588.2.1.1.1.26.2',
  'swCpuUsageLimit' => '1.3.6.1.4.1.1588.2.1.1.1.26.3',
  'swCpuPollingInterval' => '1.3.6.1.4.1.1588.2.1.1.1.26.4',
  'swCpuAction' => '1.3.6.1.4.1.1588.2.1.1.1.26.5',
  'swMemUsage' => '1.3.6.1.4.1.1588.2.1.1.1.26.6',
  'swMemNoOfRetries' => '1.3.6.1.4.1.1588.2.1.1.1.26.7',
  'swMemUsageLimit' => '1.3.6.1.4.1.1588.2.1.1.1.26.8',
  'swMemPollingInterval' => '1.3.6.1.4.1.1588.2.1.1.1.26.9',
  'swMemAction' => '1.3.6.1.4.1.1588.2.1.1.1.26.10',
  'swMemUsageLimit1' => '1.3.6.1.4.1.1588.2.1.1.1.26.11',
  'swMemUsageLimit3' => '1.3.6.1.4.1.1588.2.1.1.1.26.12',
};


1;

__END__
