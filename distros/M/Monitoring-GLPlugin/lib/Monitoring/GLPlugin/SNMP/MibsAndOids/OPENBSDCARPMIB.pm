$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'OPENBSD-CARP-MIB'} = {
  url => '',
  name => 'OPENBSD-CARP-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'OPENBSD-CARP-MIB'} =
  '1.3.6.1.4.1.30155.6';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'OPENBSD-CARP-MIB'} = {
  # openBSD.carpMIBObjects.carpSysctl
  carpAllow => '1.3.6.1.4.1.30155.6.1.1',
  carpPreempt => '1.3.6.1.4.1.30155.6.1.2',
  carpLog => '1.3.6.1.4.1.30155.6.1.3',
  # openBSD.carpMIBObjects.carpSysctl
  carpIfNumber => '1.3.6.1.4.1.30155.6.2.1',
  carpIfTable => '1.3.6.1.4.1.30155.6.2.2',
  carpIfEntry => '1.3.6.1.4.1.30155.6.2.2.1',
  carpIfIndex => '1.3.6.1.4.1.30155.6.2.2.1.1',
  carpIfDescr => '1.3.6.1.4.1.30155.6.2.2.1.2',
  carpIfVhid => '1.3.6.1.4.1.30155.6.2.2.1.3',
  carpIfDev => '1.3.6.1.4.1.30155.6.2.2.1.4',
  carpIfAdvbase => '1.3.6.1.4.1.30155.6.2.2.1.5',
  carpIfAdvskew => '1.3.6.1.4.1.30155.6.2.2.1.6',
  carpIfState => '1.3.6.1.4.1.30155.6.2.2.1.7',
  carpIfStateDefinition => 'OPENBSD-CARP-MIB::carpIfState',
  # openBSD.carpMIBObjects.carpSysctl
  carpIpPktsRecv => '1.3.6.1.4.1.30155.6.3.1',
  carpIp6PktsRecv => '1.3.6.1.4.1.30155.6.3.2',
  carpPktDiscardsForBadInterface => '1.3.6.1.4.1.30155.6.3.3',
  carpPktDiscardsForWrongTtl => '1.3.6.1.4.1.30155.6.3.4',
  carpPktShorterThanHeader => '1.3.6.1.4.1.30155.6.3.5',
  carpPktDiscardsForBadChecksum => '1.3.6.1.4.1.30155.6.3.6',
  carpPktDiscardsForBadVersion => '1.3.6.1.4.1.30155.6.3.7',
  carpPktDiscardsForTooShort => '1.3.6.1.4.1.30155.6.3.8',
  carpPktDiscardsForBadAuth => '1.3.6.1.4.1.30155.6.3.9',
  carpPktDiscardsForBadVhid => '1.3.6.1.4.1.30155.6.3.10',
  carpPktDiscardsForBadAddressList => '1.3.6.1.4.1.30155.6.3.11',
  carpIpPktsSent => '1.3.6.1.4.1.30155.6.3.12',
  carpIp6PktsSent => '1.3.6.1.4.1.30155.6.3.13',
  carpNoMemory => '1.3.6.1.4.1.30155.6.3.14',
  carpTransitionsToMaster => '1.3.6.1.4.1.30155.6.3.15',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'OPENBSD-CARP-MIB'} = {
  carpIfState => {
    '0' => 'init',
    '1' => 'backup',
    '2' => 'master',
  },
};

