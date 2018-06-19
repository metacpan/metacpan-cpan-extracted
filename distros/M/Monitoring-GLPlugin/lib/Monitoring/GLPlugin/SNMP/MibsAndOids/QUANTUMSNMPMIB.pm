package Monitoring::GLPlugin::SNMP::MibsAndOids::QUANTUMSNMPMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'QUANTUM-SNMP-MIB'} = {
  url => '',
  name => 'QUANTUM-SNMP-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'QUANTUM-SNMP-MIB'} =
    '1.3.6.1.4.1.2036.2.1';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'QUANTUM-SNMP-MIB'} = {
  atlp => '1.3.6.1.4.1.2036',
  quantum => '1.3.6.1.4.1.2036.2',
  quantumsnmp => '1.3.6.1.4.1.2036.2.1',
  qSystemInfo => '1.3.6.1.4.1.2036.2.1.1',
  qDeviceName => '1.3.6.1.4.1.2036.2.1.1.1',
  qAssignedName => '1.3.6.1.4.1.2036.2.1.1.2',
  qLocation => '1.3.6.1.4.1.2036.2.1.1.3',
  qVendorId => '1.3.6.1.4.1.2036.2.1.1.4',
  qProductId => '1.3.6.1.4.1.2036.2.1.1.5',
  qProductRev => '1.3.6.1.4.1.2036.2.1.1.6',
  qState => '1.3.6.1.4.1.2036.2.1.1.7',
  qStateDefinition => 'QUANTUM-SNMP-MIB::DeviceState',
  qTrapDescription => '1.3.6.1.4.1.2036.2.1.1.8',
  qSenseKey => '1.3.6.1.4.1.2036.2.1.1.9',
  qAsc => '1.3.6.1.4.1.2036.2.1.1.10',
  qAscq => '1.3.6.1.4.1.2036.2.1.1.11',
  qSerialNumber => '1.3.6.1.4.1.2036.2.1.1.12',
  qTrapDestination => '1.3.6.1.4.1.2036.2.1.2',
  qTrapAddress1 => '1.3.6.1.4.1.2036.2.1.2.1',
  qTrapAddress2 => '1.3.6.1.4.1.2036.2.1.2.2',
  qTrapAddress3 => '1.3.6.1.4.1.2036.2.1.2.3',
  qTrapAddress4 => '1.3.6.1.4.1.2036.2.1.2.4',
  qTrapAddress5 => '1.3.6.1.4.1.2036.2.1.2.5',
  qTrapEnable => '1.3.6.1.4.1.2036.2.1.3',
  qInfoEnable => '1.3.6.1.4.1.2036.2.1.3.1',
  qInfoEnableDefinition => 'QUANTUM-SNMP-MIB::TrapToggle',
  qWarningEnable => '1.3.6.1.4.1.2036.2.1.3.2',
  qWarningEnableDefinition => 'QUANTUM-SNMP-MIB::TrapToggle',
  qCriticalEnable => '1.3.6.1.4.1.2036.2.1.3.3',
  qCriticalEnableDefinition => 'QUANTUM-SNMP-MIB::TrapToggle',
  qAvailableEnable => '1.3.6.1.4.1.2036.2.1.3.4',
  qAvailableEnableDefinition => 'QUANTUM-SNMP-MIB::TrapToggle',
  qUnavailableEnable => '1.3.6.1.4.1.2036.2.1.3.5',
  qUnavailableEnableDefinition => 'QUANTUM-SNMP-MIB::TrapToggle',
  qNoInterventionNeededEnable => '1.3.6.1.4.1.2036.2.1.3.6',
  qNoInterventionNeededEnableDefinition => 'QUANTUM-SNMP-MIB::TrapToggle',
  qRequestedInterventionEnable => '1.3.6.1.4.1.2036.2.1.3.7',
  qRequestedInterventionEnableDefinition => 'QUANTUM-SNMP-MIB::TrapToggle',
  qRequiredInterventionEnable => '1.3.6.1.4.1.2036.2.1.3.8',
  qRequiredInterventionEnableDefinition => 'QUANTUM-SNMP-MIB::TrapToggle',
  qTraps => '1.3.6.1.4.1.2036.2.1.4',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'QUANTUM-SNMP-MIB'} = {
  TrapToggle => {
    '1' => 'disabled',
    '2' => 'enabled',
    '3' => 'trapnotavailable',
  },
  DeviceState => {
    '1' => 'unavailable',
    '2' => 'available',
    '3' => 'online',
    '4' => 'offline',
    '5' => 'goingonline',
    '6' => 'statenotavailable',
  },
};
