package Monitoring::GLPlugin::SNMP::MibsAndOids::NETSWITCHMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'NETSWITCH-MIB'} = {
  url => '',
  name => 'NETSWITCH-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'NETSWITCH-MIB'} =
    '1.3.6.1.4.1.11.2.14.11.5.1.1';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'NETSWITCH-MIB'} = {
  hpOpSystem => '1.3.6.1.4.1.11.2.14.11.5.1.1',
  hpBuf => '1.3.6.1.4.1.11.2.14.11.5.1.1.1',
  hpMsgBuf => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.1',
  hpMsgBufTable => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.1.1',
  hpMsgBufEntry => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.1.1.1',
  hpMsgBufSlotIndex => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.1.1.1.1',
  hpMsgBufCorrupted => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.1.1.1.2',
  hpMsgBufFree => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.1.1.1.3',
  hpMsgBufInit => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.1.1.1.4',
  hpMsgBufMin => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.1.1.1.5',
  hpMsgBufMiss => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.1.1.1.6',
  hpMsgBufSize => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.1.1.1.7',
  hpPktBuf => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.2',
  hpPktBufTable => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.2.1',
  hpPktBufEntry => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.2.1.1',
  hpPktBufSlotIndex => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.2.1.1.1',
  hpPktBufCorrupted => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.2.1.1.2',
  hpPktBufFree => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.2.1.1.3',
  hpPktBufInit => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.2.1.1.4',
  hpPktBufMin => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.2.1.1.5',
  hpPktBufMiss => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.2.1.1.6',
  hpPktBufSize => '1.3.6.1.4.1.11.2.14.11.5.1.1.1.2.1.1.7',
  hpMem => '1.3.6.1.4.1.11.2.14.11.5.1.1.2',
  hpLocalMem => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.1',
  hpLocalMemTable => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1',
  hpLocalMemEntry => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1',
  hpLocalMemSlotIndex => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1.1',
  hpLocalMemSlabCnt => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1.2',
  hpLocalMemFreeSegCnt => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1.3',
  hpLocalMemAllocSegCnt => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1.4',
  hpLocalMemTotalBytes => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1.5',
  hpLocalMemFreeBytes => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1.6',
  hpLocalMemAllocBytes => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1.7',
  hpGlobalMem => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.2',
  hpGlobalMemTable => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.2.1',
  hpGlobalMemEntry => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.2.1.1',
  hpGlobalMemSlotIndex => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.2.1.1.1',
  hpGlobalMemSlabCnt => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.2.1.1.2',
  hpGlobalMemFreeSegCnt => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.2.1.1.3',
  hpGlobalMemAllocSegCnt => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.2.1.1.4',
  hpGlobalMemTotalBytes => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.2.1.1.5',
  hpGlobalMemFreeBytes => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.2.1.1.6',
  hpGlobalMemAllocBytes => '1.3.6.1.4.1.11.2.14.11.5.1.1.2.2.1.1.7',
  hpSwitchOsVersion => '1.3.6.1.4.1.11.2.14.11.5.1.1.3',
  hpSwitchRomVersion => '1.3.6.1.4.1.11.2.14.11.5.1.1.4',
  hpSwitchSmartCardType => '1.3.6.1.4.1.11.2.14.11.5.1.1.5',
  hpSwitchSmartCardTypeDefinition => 'NETSWITCH-MIB::hpSwitchSmartCardType',
  hpSwitchBaseMACAddress => '1.3.6.1.4.1.11.2.14.11.5.1.1.6',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'NETSWITCH-MIB'} = {
  hpSwitchSmartCardType => {
    '1' => 'none',
    '2' => 'fddi',
    '3' => 'atm',
    '4' => 'fddiAndATM',
    '5' => 'other',
  },
};
