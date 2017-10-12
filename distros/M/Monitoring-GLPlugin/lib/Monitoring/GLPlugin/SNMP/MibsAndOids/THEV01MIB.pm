package Monitoring::GLPlugin::SNMP::MibsAndOids::THEV01MIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'THE_V01-MIB'} = {
  url => '',
  name => 'THE_V01-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'THE_V01-MIB'} =
  '1.3.6.1.4.1.18248.20';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'THE_V01-MIB'} = {
  papouchProjekt => '1.3.6.1.4.1.18248',
  the => '1.3.6.1.4.1.18248.20',
  version1 => '1.3.6.1.4.1.18248.20.1',
  device_var => '1.3.6.1.4.1.18248.20.1.1',
  deviceName => '1.3.6.1.4.1.18248.20.1.1.1',
  psAlarmString => '1.3.6.1.4.1.18248.20.1.1.2',
  table_channel => '1.3.6.1.4.1.18248.20.1.2',
  channelTable => '1.3.6.1.4.1.18248.20.1.2.1',
  channelEntry => '1.3.6.1.4.1.18248.20.1.2.1.1',
  inChStatus => '1.3.6.1.4.1.18248.20.1.2.1.1.1',
  inChStatusDefinition => {
    0 => 'ok',
    1 => 'notAvailable',
    2 => 'overFlow',
    3 => 'underFlow',
    4 => 'err',
  },
  inChValue => '1.3.6.1.4.1.18248.20.1.2.1.1.2',
  inChUnits => '1.3.6.1.4.1.18248.20.1.2.1.1.3',
  inChUnitsDefinition => {
    0 => 'celsius',
    1 => 'fahrenheit',
    2 => 'kelvin',
    3 => 'percents',
  },
  table_watchValue => '1.3.6.1.4.1.18248.20.1.3',
  watchValTable => '1.3.6.1.4.1.18248.20.1.3.1',
  watchValEntry => '1.3.6.1.4.1.18248.20.1.3.1.1',
  modeWatch => '1.3.6.1.4.1.18248.20.1.3.1.1.1',
  modeWatchDefinition => {
    0 => 'inactive',
    1 => 'active',
  },
  limitHi => '1.3.6.1.4.1.18248.20.1.3.1.1.2',
  limitLo => '1.3.6.1.4.1.18248.20.1.3.1.1.3',
  limitHy => '1.3.6.1.4.1.18248.20.1.3.1.1.4',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'THE_V01-MIB'} = {
};
