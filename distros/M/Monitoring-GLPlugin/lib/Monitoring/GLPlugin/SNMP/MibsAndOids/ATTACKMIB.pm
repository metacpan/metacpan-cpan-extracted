package Monitoring::GLPlugin::SNMP::MibsAndOids::ATTACKMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'ATTACK-MIB'} = {
  url => '',
  name => 'ATTACK-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'ATTACK-MIB'} = {
  'deviceAttackTable' => '1.3.6.1.4.1.3417.2.3.1.1.1',
  'deviceAttackEntry' => '1.3.6.1.4.1.3417.2.3.1.1.1.1',
  'deviceAttackIndex' => '1.3.6.1.4.1.3417.2.3.1.1.1.1.1',
  'deviceAttackName' => '1.3.6.1.4.1.3417.2.3.1.1.1.1.2',
  'deviceAttackStatus' => '1.3.6.1.4.1.3417.2.3.1.1.1.1.3',
  'deviceAttackStatusDefinition' => {
    '1' => 'no-attack',
    '2' => 'under-attack',
  },
  'deviceAttackTime' => '1.3.6.1.4.1.3417.2.3.1.1.1.1.4',
};


1;

__END__
