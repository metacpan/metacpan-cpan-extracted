package Monitoring::GLPlugin::SNMP::MibsAndOids::CISCOLAGMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'CISCO-LAG-MIB'} = {
  url => '',
  name => 'CISCO-LAG-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'CISCO-LAG-MIB'} =
    '1.3.6.1.4.1.9.9.225';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-LAG-MIB'} = {
  ciscoLagMIB => '1.3.6.1.4.1.9.9.225',
  clagMIBObjects => '1.3.6.1.4.1.9.9.225.1',
  clagGlobalConfigObjects => '1.3.6.1.4.1.9.9.225.1.1',
  clagAggDistributionProtocol => '1.3.6.1.4.1.9.9.225.1.1.1',
  clagAggDistributionProtocolDefinition => 'CISCO-LAG-MIB::ClagDistributionProtocol',
  clagAggDistributionAddressMode => '1.3.6.1.4.1.9.9.225.1.1.2',
  clagAggDistributionAddressModeDefinition => 'CISCO-LAG-MIB::ClagDistributionAddressMode',
  clagAggDistributionMplsProtocol => '1.3.6.1.4.1.9.9.225.1.1.3',
  clagAggDistributionMplsProtocolDefinition => 'CISCO-LAG-MIB::ClagDistributionMplsProtocol',
  clagAggMaxAggregators => '1.3.6.1.4.1.9.9.225.1.1.4',
  clagAggHashDistMethodGlobalConfig => '1.3.6.1.4.1.9.9.225.1.1.5',
  clagAggHashDistMethodGlobalConfigDefinition => 'CISCO-LAG-MIB::clagAggHashDistMethodGlobalConfig',
  clagAgg => '1.3.6.1.4.1.9.9.225.1.2',
  clagAggProtocolTable => '1.3.6.1.4.1.9.9.225.1.2.1',
  clagAggProtocolEntry => '1.3.6.1.4.1.9.9.225.1.2.1.1',
  clagAggProtocolType => '1.3.6.1.4.1.9.9.225.1.2.1.1.1',
  clagAggProtocolTypeDefinition => 'CISCO-LAG-MIB::ClagAggregationProtocol',
  clagAggPort => '1.3.6.1.4.1.9.9.225.1.3',
  clagAggPortTable => '1.3.6.1.4.1.9.9.225.1.3.1',
  clagAggPortEntry => '1.3.6.1.4.1.9.9.225.1.3.1.1',
  clagAggPortAdminStatus => '1.3.6.1.4.1.9.9.225.1.3.1.1.1',
  clagAggPortAdminStatusDefinition => 'CISCO-LAG-MIB::ClagPortAdminStatus',
  clagAggPortRate => '1.3.6.1.4.1.9.9.225.1.3.1.1.2',
  clagAggPortRateDefinition => 'CISCO-LAG-MIB::clagAggPortRate',
  clagAggPortList => '1.3.6.1.4.1.9.9.225.1.4',
  clagAggPortListTable => '1.3.6.1.4.1.9.9.225.1.4.1',
  clagAggPortListEntry => '1.3.6.1.4.1.9.9.225.1.4.1.1',
  clagAggPortListPorts => '1.3.6.1.4.1.9.9.225.1.4.1.1.1',
  clagAggChannelIntf => '1.3.6.1.4.1.9.9.225.1.5',
  clagAggChannelIfTable => '1.3.6.1.4.1.9.9.225.1.5.1',
  clagAggChannelIfEntry => '1.3.6.1.4.1.9.9.225.1.5.1.1',
  clagAggChannelIfFastSwitchOver => '1.3.6.1.4.1.9.9.225.1.5.1.1.1',
  clagAggChannelIfMaxBundle => '1.3.6.1.4.1.9.9.225.1.5.1.1.2',
  clagAggChannelIfMinLink => '1.3.6.1.4.1.9.9.225.1.5.1.1.3',
  clagAggChannelIfHashDistAdminMethod => '1.3.6.1.4.1.9.9.225.1.5.1.1.4',
  clagAggChannelIfHashDistAdminMethodDefinition => 'CISCO-LAG-MIB::clagAggChannelIfHashDistAdminMethod',
  clagAggChannelIfHashDistOperMethod => '1.3.6.1.4.1.9.9.225.1.5.1.1.5',
  clagAggChannelIfHashDistOperMethodDefinition => 'CISCO-LAG-MIB::clagAggChannelIfHashDistOperMethod',
  clagMIBNotifications => '1.3.6.1.4.1.9.9.225.2',
  clagMIBConformance => '1.3.6.1.4.1.9.9.225.3',
  clagMIBCompliances => '1.3.6.1.4.1.9.9.225.3.1',
  clagMIBGroups => '1.3.6.1.4.1.9.9.225.3.2',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCO-LAG-MIB'} = {
  ClagAggregationProtocol => {
    '1' => 'lacp',
    '2' => 'pagp',
  },
  ClagPortAdminStatus => {
    '1' => 'off',
    '2' => 'on',
    '3' => 'active',
    '4' => 'passive',
  },
  ClagDistributionMplsProtocol => {
    '1' => 'label',
    '2' => 'labelIp',
  },
  clagAggPortRate => {
    '1' => 'fast',
    '2' => 'normal',
  },
  clagAggChannelIfHashDistAdminMethod => {
    '1' => 'none',
    '2' => 'adaptive',
    '3' => 'fixed',
  },
  ClagDistributionProtocol => {
    '1' => 'ip',
    '2' => 'mac',
    '3' => 'port',
    '4' => 'vlanIpPort',
    '5' => 'vlanIp',
    '6' => 'ipPort',
  },
  ClagDistributionAddressMode => {
    '1' => 'source',
    '2' => 'destination',
    '3' => 'both',
  },
  clagAggChannelIfHashDistOperMethod => {
    '1' => 'other',
    '2' => 'adaptive',
    '3' => 'fixed',
  },
  clagAggHashDistMethodGlobalConfig => {
    '1' => 'adaptive',
    '2' => 'fixed',
  },
};
