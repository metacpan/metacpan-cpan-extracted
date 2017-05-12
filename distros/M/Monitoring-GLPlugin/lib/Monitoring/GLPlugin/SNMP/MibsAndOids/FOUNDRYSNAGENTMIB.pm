package Monitoring::GLPlugin::SNMP::MibsAndOids::FOUNDRYSNAGENTMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'FOUNDRY-SN-AGENT-MIB'} = {
  url => '',
  name => 'FOUNDRY-SN-AGENT-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'FOUNDRY-SN-AGENT-MIB'} = {
  'snChasPwrSupplyTable' => '1.3.6.1.4.1.1991.1.1.1.2.1',
  'snChasPwrSupplyEntry' => '1.3.6.1.4.1.1991.1.1.1.2.1.1',
  'snChasPwrSupplyIndex' => '1.3.6.1.4.1.1991.1.1.1.2.1.1.1',
  'snChasPwrSupplyDescription' => '1.3.6.1.4.1.1991.1.1.1.2.1.1.2',
  'snChasPwrSupplyOperStatus' => '1.3.6.1.4.1.1991.1.1.1.2.1.1.3',
  'snChasPwrSupplyOperStatusDefinition' => {
    '1' => 'other',
    '2' => 'normal',
    '3' => 'failure',
  },
  'snChasFan' => '1.3.6.1.4.1.1991.1.1.1.3',
  'snChasFanTable' => '1.3.6.1.4.1.1991.1.1.1.3.1',
  'snChasFanEntry' => '1.3.6.1.4.1.1991.1.1.1.3.1.1',
  'snChasFanIndex' => '1.3.6.1.4.1.1991.1.1.1.3.1.1.1',
  'snChasFanDescription' => '1.3.6.1.4.1.1991.1.1.1.3.1.1.2',
  'snChasFanOperStatus' => '1.3.6.1.4.1.1991.1.1.1.3.1.1.3',
  'snChasFanOperStatusDefinition' => {
    '1' => 'other',
    '2' => 'normal',
    '3' => 'failure',
  },
  'snAgGblCpuUtil1SecAvg' => '1.3.6.1.4.1.1991.1.1.2.1.50.0',
  'snAgGblCpuUtil5SecAvg' => '1.3.6.1.4.1.1991.1.1.2.1.51.0',
  'snAgGblCpuUtil1MinAvg' => '1.3.6.1.4.1.1991.1.1.2.1.52.0',
  'snAgGblDynMemUtil' => '1.3.6.1.4.1.1991.1.1.2.1.53.0',
  'snAgGblDynMemTotal' => '1.3.6.1.4.1.1991.1.1.2.1.54.0',
  'snAgGblDynMemFree' => '1.3.6.1.4.1.1991.1.1.2.1.55.0',
  'snAgentCpuUtilTable' => '1.3.6.1.4.1.1991.1.1.2.11.1',
  'snAgentCpuUtilEntry' => '1.3.6.1.4.1.1991.1.1.2.11.1.1',
  'snAgentCpuUtilSlotNum' => '1.3.6.1.4.1.1991.1.1.2.11.1.1.1',
  'snAgentCpuUtilCpuId' => '1.3.6.1.4.1.1991.1.1.2.11.1.1.2',
  'snAgentCpuUtilInterval' => '1.3.6.1.4.1.1991.1.1.2.11.1.1.3',
  'snAgentCpuUtilValue' => '1.3.6.1.4.1.1991.1.1.2.11.1.1.4',
  'snAgentCpuUtilPercent' => '1.3.6.1.4.1.1991.1.1.2.11.1.1.5',
  'snAgentCpuUtil100thPercent' => '1.3.6.1.4.1.1991.1.1.2.11.1.1.6',
  'snAgentTempTable' => '1.3.6.1.4.1.1991.1.1.2.13.1',
  'snAgentTempEntry' => '1.3.6.1.4.1.1991.1.1.2.13.1.1',
  'snAgentTempSlotNum' => '1.3.6.1.4.1.1991.1.1.2.13.1.1.1',
  'snAgentTempSensorId' => '1.3.6.1.4.1.1991.1.1.2.13.1.1.2',
  'snAgentTempSensorDescr' => '1.3.6.1.4.1.1991.1.1.2.13.1.1.3',
  'snAgentTempValue' => '1.3.6.1.4.1.1991.1.1.2.13.1.1.4',
};


1;

__END__
