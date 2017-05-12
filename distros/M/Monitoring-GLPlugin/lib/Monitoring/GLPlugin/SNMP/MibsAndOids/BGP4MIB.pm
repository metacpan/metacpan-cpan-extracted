package Monitoring::GLPlugin::SNMP::MibsAndOids::BGP4MIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'BGP4-MIB'} = {
  url => '',
  name => 'BGP4-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'BGP4-MIB'} = {
  'bgpVersion' => '1.3.6.1.2.1.15.1.0',
  'bgpLocalAs' => '1.3.6.1.2.1.15.2.0',
  'bgpPeerTable' => '1.3.6.1.2.1.15.3',
  'bgpPeerEntry' => '1.3.6.1.2.1.15.3.1',
  'bgpPeerIdentifier' => '1.3.6.1.2.1.15.3.1.1',
  'bgpPeerState' => '1.3.6.1.2.1.15.3.1.2',
  'bgpPeerStateDefinition' => {
    '1' => 'idle',
    '2' => 'connect',
    '3' => 'active',
    '4' => 'opensent',
    '5' => 'openconfirm',
    '6' => 'established',
  },
  'bgpPeerAdminStatus' => '1.3.6.1.2.1.15.3.1.3',
  'bgpPeerAdminStatusDefinition' => {
    '1' => 'stop',
    '2' => 'start',
  },
  'bgpPeerNegotiatedVersion' => '1.3.6.1.2.1.15.3.1.4',
  'bgpPeerLocalAddr' => '1.3.6.1.2.1.15.3.1.5',
  'bgpPeerLocalPort' => '1.3.6.1.2.1.15.3.1.6',
  'bgpPeerRemoteAddr' => '1.3.6.1.2.1.15.3.1.7',
  'bgpPeerRemotePort' => '1.3.6.1.2.1.15.3.1.8',
  'bgpPeerRemoteAs' => '1.3.6.1.2.1.15.3.1.9',
  'bgpPeerInUpdates' => '1.3.6.1.2.1.15.3.1.10',
  'bgpPeerOutUpdates' => '1.3.6.1.2.1.15.3.1.11',
  'bgpPeerInTotalMessages' => '1.3.6.1.2.1.15.3.1.12',
  'bgpPeerOutTotalMessages' => '1.3.6.1.2.1.15.3.1.13',
  'bgpPeerLastError' => '1.3.6.1.2.1.15.3.1.14',
  'bgpPeerFsmEstablishedTransitions' => '1.3.6.1.2.1.15.3.1.15',
  'bgpPeerFsmEstablishedTime' => '1.3.6.1.2.1.15.3.1.16',
  'bgpPeerConnectRetryInterval' => '1.3.6.1.2.1.15.3.1.17',
  'bgpPeerHoldTime' => '1.3.6.1.2.1.15.3.1.18',
  'bgpPeerKeepAlive' => '1.3.6.1.2.1.15.3.1.19',
  'bgpPeerHoldTimeConfigured' => '1.3.6.1.2.1.15.3.1.20',
  'bgpPeerKeepAliveConfigured' => '1.3.6.1.2.1.15.3.1.21',
  'bgpPeerMinASOriginationInterval' => '1.3.6.1.2.1.15.3.1.22',
  'bgpPeerMinRouteAdvertisementInterval' => '1.3.6.1.2.1.15.3.1.23',
  'bgpPeerInUpdateElapsedTime' => '1.3.6.1.2.1.15.3.1.24',
};


1;

__END__
