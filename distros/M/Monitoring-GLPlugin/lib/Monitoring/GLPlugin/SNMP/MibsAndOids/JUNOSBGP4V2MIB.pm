package Monitoring::GLPlugin::SNMP::MibsAndOids::JUNOSBGP4V2MIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'JUNOS-BGP4V2-MIB'} = {
  url => '',
  name => 'JUNOS-BGP4V2-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'JUNOS-BGP4V2-MIB'} = {
  'jnxBgpM2Peer' => '1.3.6.1.4.1.2636.5.1.1.2',
  'jnxBgpM2PeerData' => '1.3.6.1.4.1.2636.5.1.1.2.1',
  'jnxBgpM2PeerTable' => '1.3.6.1.4.1.2636.5.1.1.2.1.1',
  'jnxBgpM2PeerEntry' => '1.3.6.1.4.1.2636.5.1.1.2.1.1.1',
  'jnxBgpM2PeerState' => '1.3.6.1.4.1.2636.5.1.1.2.1.1.1.2',
  'jnxBgpM2PeerStateDefinition' => {
    '1' => 'idle',
    '2' => 'connect',
    '3' => 'active',
    '4' => 'opensent',
    '5' => 'openconfirm',
    '6' => 'established',
  },
  'jnxBgpM2PeerStatus' => '1.3.6.1.4.1.2636.5.1.1.2.1.1.1.3',
  'jnxBgpM2PeerStatusDefinition' => {
    '1' => 'halted',
    '2' => 'running',
  },
  'jnxBgpM2PeerRemoteAddrType' => '1.3.6.1.4.1.2636.5.1.1.2.1.1.1.10',
  'jnxBgpM2PeerRemoteAddrTypeDefinition' => {
    '1' => 'ipv4',
    '2' => 'ipv6',
    '3' => 'ipv4z',
    '4' => 'ipv6z',
    '16' => 'dns',
  },
  'jnxBgpM2PeerRemoteAddr' => '1.3.6.1.4.1.2636.5.1.1.2.1.1.1.11',
  'jnxBgpM2PeerRemotePort' => '1.3.6.1.4.1.2636.5.1.1.2.1.1.1.12',
  'jnxBgpM2PeerRemoteAs' => '1.3.6.1.4.1.2636.5.1.1.2.1.1.1.13',
  'jnxBgpM2PeerErrorsTable' => '1.3.6.1.4.1.2636.5.1.1.2.2.1',
  'jnxBgpM2PeerErrorsEntry' => '1.3.6.1.4.1.2636.5.1.1.2.2.1.1',
  'jnxBgpM2PeerLastErrorReceivedText' => '1.3.6.1.4.1.2636.5.1.1.2.2.1.1.5',
  'jnxBgpM2PeerLastErrorSentText' => '1.3.6.1.4.1.2636.5.1.1.2.2.1.1.6',
  'jnxBgpM2PeerEventTimesTable'	=> '1.3.6.1.4.1.2636.5.1.1.2.4.1',
  'jnxBgpM2PeerEventTimesEntry'	=> '1.3.6.1.4.1.2636.5.1.1.2.4.1.1',
  'jnxBgpM2PeerFsmEstablishedTime' => '1.3.6.1.4.1.2636.5.1.1.2.4.1.1.1',
};


1;

__END__
