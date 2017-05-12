package Monitoring::GLPlugin::SNMP::MibsAndOids::HWGWLDMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'HWg-WLD-MIB'} = {
  url => "http://hwg-wld.hwg.cz/HWg_WLD.mib",
  name => "HWg-WLD-MIB",
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'HWg-WLD-MIB'} = 
  '1.3.6.1.4.1.21796.4.5';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'HWg-WLD-MIB'} = {
  hwgroup => '1.3.6.1.4.1.21796',
  x390 => '1.3.6.1.4.1.21796.4',
  hwgwld => '1.3.6.1.4.1.21796.4.5',
  sensTable => '1.3.6.1.4.1.21796.4.5.4',
  sensEntry => '1.3.6.1.4.1.21796.4.5.4.1', # gibts nicht, aber wldEntry ist bloed
  wldEntry => '1.3.6.1.4.1.21796.4.5.4.1',
  wldIndex => '1.3.6.1.4.1.21796.4.5.4.1.1',
  wldName => '1.3.6.1.4.1.21796.4.5.4.1.2',
  wldState => '1.3.6.1.4.1.21796.4.5.4.1.3',
  wldStateDefinition => 'HWg-WLD-MIB::SensorState',
  wldSN => '1.3.6.1.4.1.21796.4.5.4.1.4',
  wldID => '1.3.6.1.4.1.21796.4.5.4.1.5',
  wldValue => '1.3.6.1.4.1.21796.4.5.4.1.6',
  wldValueDefinition => 'HWg-WLD-MIB::SensorValue',
  info => '1.3.6.1.4.1.21796.4.5.70',
  infoAddressMAC => '1.3.6.1.4.1.21796.4.5.70.1',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'HWg-WLD-MIB'} = {
  'SensorState' => {
    '0' => 'invalid',
    '1' => 'normal',
    '2' => 'alarm',
  },
  'SensorValue' => {
    '0' => 'normal',
    '1' => 'flooded',
    '2' => 'disconnect',
    '3' => 'invalid',
  },
};

1;

__END__

