package Monitoring::GLPlugin::SNMP::MibsAndOids::SLHWLIBT950MIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'SL-HW-LIB-T950-MIB'} = {
  url => '',
  name => 'SL-HW-LIB-T950-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'SL-HW-LIB-T950-MIB'} = 
  '1.3.6.1.4.1.3478.1.1.3.1.1';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'SL-HW-LIB-T950-MIB'} = {
  'slT950MIB' => '1.3.6.1.4.1.3478.1.1.3.1.1',
  'slT950Confs' => '1.3.6.1.4.1.3478.1.1.3.1.1.1',
  'slT950Groups' => '1.3.6.1.4.1.3478.1.1.3.1.1.1.1',
  'slT950Compl' => '1.3.6.1.4.1.3478.1.1.3.1.1.1.2',
  'slT950Objs' => '1.3.6.1.4.1.3478.1.1.3.1.1.2',
  'slT950LibraryObjs' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1',
  'slT950GeneralObjs' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1',
  'slT950GeneralStatusObjs' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1',
  'slT950GeneralStatusPowerStatus' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.1',
  'slT950GeneralStatusPowerStatusDefinition' => 'SL-HW-LIB-T950-MIB::SLComponentStatus',
  'slT950GeneralStatusFansStatus' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.2',
  'slT950GeneralStatusFansStatusDefinition' => {
    '1' => 'ok',
    '2' => 'warning',
    '3' => 'failure',
  },
  'slT950GeneralStatusTap1Status' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.3',
  'slT950GeneralStatusTap1StatusDefinition' => {
    '1' => 'ok',
    '2' => 'warning',
    '3' => 'failure',
  },
  'slT950GeneralStatusTap2Status' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.4',
  'slT950GeneralStatusTap2StatusDefinition' => {
    '1' => 'ok',
    '2' => 'warning',
    '3' => 'failure',
  },
  'slT950GeneralStatusPartitionCount' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.5',
  'slT950GeneralStatusPartitionTable' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.6',
  'slT950GeneralStatusPartitionEntry' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.6.1',
  'slT950GeneralStatusPartitionIndex' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.6.1.1',
  'slT950GeneralStatusPartitionName' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.6.1.2',
  'slT950GeneralStatusPartitionTotalAvailableDrives' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.6.1.3',
  'slT950GeneralStatusPartitionFullDrives' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.6.1.4',
  'slT950GeneralStatusPartitionTotalAvailableStorageSlots' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.6.1.5',
  'slT950GeneralStatusPartitionFullStorageSlots' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.6.1.6',
  'slT950GeneralStatusPartitionTotalAvailableEntryExitSlots' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.6.1.7',
  'slT950GeneralStatusPartitionFullEntryExitSlots' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.1.6.1.8',
  'slT950InventoryObjs' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.1.2',
  'slT950ConfigurationObjs' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.2',
  'slT950MaintenancelObjs' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.3',
  'slT950SecurityObjs' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.4',
  'slT950MessageObjs' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.5',
  'slT950MessageCount' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.5.1',
  'slT950MessageTable' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.5.2',
  'slT950MessageEntry' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.5.2.1',
  'slT950MessageIndex' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.5.2.1.1',
  'slT950MessageNumber' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.5.2.1.2',
  'slT950MessageSeverity' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.5.2.1.3',
  'slT950MessageSeverityDefinition' => {
    '1' => 'info',
    '2' => 'warning',
    '3' => 'error',
    '4' => 'fatal',
  },
  'slT950MessageText' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.5.2.1.4',
  'slT950MessageRemedyText' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.5.2.1.5',
  'slT950MessageTime' => '1.3.6.1.4.1.3478.1.1.3.1.1.2.1.5.2.1.6',
  'slT950Events' => '1.3.6.1.4.1.3478.1.1.3.1.1.3',
  'slT950EventsV2' => '1.3.6.1.4.1.3478.1.1.3.1.1.3.0',
  'slT950MibModule' => '1.3.6.1.4.1.3478.3.1.4',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'SL-HW-LIB-T950-MIB'} = {
  'SLComponentStatus' => {
    '1' => 'ok',
    '2' => 'failure',
  },
};

1;

__END__
