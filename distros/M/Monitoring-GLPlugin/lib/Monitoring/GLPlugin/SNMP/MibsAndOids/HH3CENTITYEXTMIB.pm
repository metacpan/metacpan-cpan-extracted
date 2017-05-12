package Monitoring::GLPlugin::SNMP::MibsAndOids::HH3CENTITYEXTMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'HH3C-ENTITY-EXT-MIB'} = {
  url => '',
  name => 'HH3C-ENTITY-EXT-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'HH3C-ENTITY-EXT-MIB'} = {
  'hh3cEntityExtStateTable' => '1.3.6.1.4.1.25506.2.6.1.1.1',
  'hh3cEntityExtStateEntry' => '1.3.6.1.4.1.25506.2.6.1.1.1.1',
  'hh3cEntityExtCpuUsage' => '1.3.6.1.4.1.25506.2.6.1.1.1.1.6',
  'hh3cEntityExtTemperature' => '1.3.6.1.4.1.25506.2.6.1.1.1.1.12',
  'hh3cEntityExtErrorStatus' => '1.3.6.1.4.1.25506.2.6.1.1.1.1.19',
  'hh3cEntityExtErrorStatusDefinition' => 'HH3C-ENTITY-EXT-MIB::hh3cEntityExtErrorStatusValue',
  'hh3cEntityExtCpuAvgUsage' => '1.3.6.1.4.1.25506.2.6.1.1.1.1.26',
  'hh3cEntityExtMemAvgUsage' => '1.3.6.1.4.1.25506.2.6.1.1.1.1.27',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'HH3C-ENTITY-EXT-MIB'} = {
  'hh3cEntityExtErrorStatusValue' => {
    '1' => 'notSupported',
    '2' => 'normal',
    '3' => 'postFailure',
    '4' => 'entityAbsent',
    '11' => 'poeError',
    '21' => 'stackError',
    '22' => 'stackPortBlocked',
    '23' => 'stackPortFailed',
    '31' => 'sfpRecvError',
    '32' => 'sfpSendError',
    '33' => 'sfpBothError',
    '41' => 'fanError',
    '51' => 'psuError',
    '61' => 'rpsError',
    '71' => 'moduleFaulty',
    '81' => 'sensorError',
    '91' => 'hardwareFaulty',
  },
};

1;

__END__
