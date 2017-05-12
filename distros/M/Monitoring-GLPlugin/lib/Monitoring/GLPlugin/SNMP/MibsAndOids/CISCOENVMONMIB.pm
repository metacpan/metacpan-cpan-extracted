package Monitoring::GLPlugin::SNMP::MibsAndOids::CISCOENVMONMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'CISCO-ENVMON-MIB'} = {
  url => '',
  name => 'CISCO-ENVMON-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'CISCO-ENVMON-MIB'} = 
  '1.3.6.1.4.1.9.9.13';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-ENVMON-MIB'} = {
  'ciscoEnvMonPresent' => '1.3.6.1.4.1.9.9.13.1.1.0',
  'ciscoEnvMonPresentDefinition' => {
    '1' => 'oldAgs',
    '2' => 'ags',
    '3' => 'c7000',
    '4' => 'ci',
    '6' => 'cAccessMon',
    '7' => 'cat6000',
    '8' => 'ubr7200',
    '9' => 'cat4000',
    '10' => 'c10000',
    '11' => 'osr7600',
    '12' => 'c7600',
    '13' => 'c37xx',
    '14' => 'other',
  },
  'ciscoEnvMonVoltageStatusTable' => '1.3.6.1.4.1.9.9.13.1.2',
  'ciscoEnvMonVoltageStatusEntry' => '1.3.6.1.4.1.9.9.13.1.2.1',
  'ciscoEnvMonVoltageStatusIndex' => '1.3.6.1.4.1.9.9.13.1.2.1.1',
  'ciscoEnvMonVoltageStatusDescr' => '1.3.6.1.4.1.9.9.13.1.2.1.2',
  'ciscoEnvMonVoltageStatusValue' => '1.3.6.1.4.1.9.9.13.1.2.1.3',
  'ciscoEnvMonVoltageThresholdLow' => '1.3.6.1.4.1.9.9.13.1.2.1.4',
  'ciscoEnvMonVoltageThresholdHigh' => '1.3.6.1.4.1.9.9.13.1.2.1.5',
  'ciscoEnvMonVoltageLastShutdown' => '1.3.6.1.4.1.9.9.13.1.2.1.6',
  'ciscoEnvMonVoltageState' => '1.3.6.1.4.1.9.9.13.1.2.1.7',
  'ciscoEnvMonVoltageStateDefinition' => 'CISCO-ENVMON-MIB::ciscoEnvMonState',
  'ciscoEnvMonTemperatureStatusTable' => '1.3.6.1.4.1.9.9.13.1.3',
  'ciscoEnvMonTemperatureStatusEntry' => '1.3.6.1.4.1.9.9.13.1.3.1',
  'ciscoEnvMonTemperatureStatusIndex' => '1.3.6.1.4.1.9.9.13.1.3.1.1',
  'ciscoEnvMonTemperatureStatusDescr' => '1.3.6.1.4.1.9.9.13.1.3.1.2',
  'ciscoEnvMonTemperatureStatusValue' => '1.3.6.1.4.1.9.9.13.1.3.1.3',
  'ciscoEnvMonTemperatureThreshold' => '1.3.6.1.4.1.9.9.13.1.3.1.4',
  'ciscoEnvMonTemperatureLastShutdown' => '1.3.6.1.4.1.9.9.13.1.3.1.5',
  'ciscoEnvMonTemperatureState' => '1.3.6.1.4.1.9.9.13.1.3.1.6',
  'ciscoEnvMonTemperatureStateDefinition' => 'CISCO-ENVMON-MIB::ciscoEnvMonState',
  'ciscoEnvMonFanStatusTable' => '1.3.6.1.4.1.9.9.13.1.4',
  'ciscoEnvMonFanStatusEntry' => '1.3.6.1.4.1.9.9.13.1.4.1',
  'ciscoEnvMonFanStatusIndex' => '1.3.6.1.4.1.9.9.13.1.4.1.1',
  'ciscoEnvMonFanStatusDescr' => '1.3.6.1.4.1.9.9.13.1.4.1.2',
  'ciscoEnvMonFanState' => '1.3.6.1.4.1.9.9.13.1.4.1.3',
  'ciscoEnvMonFanStateDefinition' => 'CISCO-ENVMON-MIB::ciscoEnvMonState',
  'ciscoEnvMonSupplyStatusTable' => '1.3.6.1.4.1.9.9.13.1.5',
  'ciscoEnvMonSupplyStatusEntry' => '1.3.6.1.4.1.9.9.13.1.5.1',
  'ciscoEnvMonSupplyStatusIndex' => '1.3.6.1.4.1.9.9.13.1.5.1.1',
  'ciscoEnvMonSupplyStatusDescr' => '1.3.6.1.4.1.9.9.13.1.5.1.2',
  'ciscoEnvMonSupplyState' => '1.3.6.1.4.1.9.9.13.1.5.1.3',
  'ciscoEnvMonSupplyStateDefinition' => 'CISCO-ENVMON-MIB::ciscoEnvMonState',
  'ciscoEnvMonSupplySource' => '1.3.6.1.4.1.9.9.13.1.5.1.4',
  'ciscoEnvMonSupplySourceDefinition' => 'CISCO-ENVMON-MIB::ciscoEnvMonSupplySource',
  'ciscoEnvMonAlarmContacts' => '1.3.6.1.4.1.9.9.13.1.6.0',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCO-ENVMON-MIB'} = {
  'ciscoEnvMonState' => {
    '1' => 'normal',
    '2' => 'warning',
    '3' => 'critical',
    '4' => 'shutdown',
    '5' => 'notPresent',
    '6' => 'notFunctioning',
  },
  'ciscoEnvMonSupplySource' => {
    '1' => 'unknown',
    '2' => 'ac',
    '3' => 'dc',
    '4' => 'externalPowerSupply',
    '5' => 'internalRedundant',
  },
};

1;

__END__
