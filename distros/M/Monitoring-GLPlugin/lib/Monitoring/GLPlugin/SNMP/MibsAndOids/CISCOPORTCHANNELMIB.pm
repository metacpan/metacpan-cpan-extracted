package Monitoring::GLPlugin::SNMP::MibsAndOids::CISCOPORTCHANNELMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'CISCO-PORT-CHANNEL-MIB'} = {
  url => '',
  name => 'CISCO-PORT-CHANNEL-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'CISCO-PORT-CHANNEL-MIB'} =
    '1.3.6.1.4.1.9.9.285';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-PORT-CHANNEL-MIB'} = {
  ciscoPortChannelMIB => '1.3.6.1.4.1.9.9.285',
  ciscoPortChannelObjects => '1.3.6.1.4.1.9.9.285.1',
  portChannelConfig => '1.3.6.1.4.1.9.9.285.1.1',
  portChannelTable => '1.3.6.1.4.1.9.9.285.1.1.1',
  portChannelEntry => '1.3.6.1.4.1.9.9.285.1.1.1.1',
  portChannelIndex => '1.3.6.1.4.1.9.9.285.1.1.1.1.1',
  portChannelIfIndex => '1.3.6.1.4.1.9.9.285.1.1.1.1.2',
  portChannelAdminChannelMode => '1.3.6.1.4.1.9.9.285.1.1.1.1.3',
  portChannelAdminChannelModeDefinition => 'CISCO-PORT-CHANNEL-MIB::PortChannelMode',
  portChannelOperChannelMode => '1.3.6.1.4.1.9.9.285.1.1.1.1.4',
  portChannelOperChannelModeDefinition => 'CISCO-PORT-CHANNEL-MIB::PortChannelMode',
  portChannelAddType => '1.3.6.1.4.1.9.9.285.1.1.1.1.5',
  portChannelAddTypeDefinition => 'CISCO-PORT-CHANNEL-MIB::portChannelAddType',
  portChannelLastActionStatus => '1.3.6.1.4.1.9.9.285.1.1.1.1.6',
  portChannelLastActionStatusDefinition => 'CISCO-PORT-CHANNEL-MIB::portChannelLastActionStatus',
  portChannelLastActionStatusCause => '1.3.6.1.4.1.9.9.285.1.1.1.1.7',
  portChannelLastActionTime => '1.3.6.1.4.1.9.9.285.1.1.1.1.8',
  portChannelMemberList => '1.3.6.1.4.1.9.9.285.1.1.1.1.9',
  portChannelCreationTime => '1.3.6.1.4.1.9.9.285.1.1.1.1.10',
  portChannelRowStatus => '1.3.6.1.4.1.9.9.285.1.1.1.1.11',
  portChannelMemberOperStatus => '1.3.6.1.4.1.9.9.285.1.1.1.1.12',
  portChannelProtocolEnable => '1.3.6.1.4.1.9.9.285.1.1.2',
  portChannelGrpIfExtTable => '1.3.6.1.4.1.9.9.285.1.1.3',
  portChannelGrpIfExtEntry => '1.3.6.1.4.1.9.9.285.1.1.3.1',
  portChannelGrpIfAutoCreation => '1.3.6.1.4.1.9.9.285.1.1.3.1.1',
  portChannelExtTable => '1.3.6.1.4.1.9.9.285.1.1.4',
  portChannelExtEntry => '1.3.6.1.4.1.9.9.285.1.1.4.1',
  portChannelExtChannelGrpMode => '1.3.6.1.4.1.9.9.285.1.1.4.1.1',
  portChannelExtChannelGrpModeDefinition => 'CISCO-PORT-CHANNEL-MIB::PortChannelGroupMode',
  portChannelExtAutoCreated => '1.3.6.1.4.1.9.9.285.1.1.4.1.2',
  portChannelExtPersistent => '1.3.6.1.4.1.9.9.285.1.1.4.1.3',
  portChannelExtPersistentDefinition => 'CISCO-PORT-CHANNEL-MIB::portChannelExtPersistent',
  portChannelExtOperChannelGrpMode => '1.3.6.1.4.1.9.9.285.1.1.4.1.4',
  portChannelExtOperChannelGrpModeDefinition => 'CISCO-PORT-CHANNEL-MIB::PortChannelGroupMode',
  portChannelStatistics => '1.3.6.1.4.1.9.9.285.1.2',
  portChannelNotification => '1.3.6.1.4.1.9.9.285.1.3',
  portChannelNotifications => '1.3.6.1.4.1.9.9.285.1.3.0',
  portChannelMIBConformance => '1.3.6.1.4.1.9.9.285.2',
  portChannelMIBCompliances => '1.3.6.1.4.1.9.9.285.2.1',
  portChannelMIBGroups => '1.3.6.1.4.1.9.9.285.2.2',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCO-PORT-CHANNEL-MIB'} = {
  PortChannelGroupMode => {
    '1' => 'on',
    '2' => 'active',
  },
  PortChannelMode => {
    '1' => 'auto',
    '2' => 'on',
    '3' => 'off',
    '4' => 'desirable',
  },
  portChannelLastActionStatus => {
    '1' => 'successful',
    '2' => 'failed',
  },
  portChannelExtPersistent => {
    '1' => 'noOp',
    '2' => 'enable',
  },
  portChannelAddType => {
    '1' => 'normal',
    '2' => 'force',
  },
};
