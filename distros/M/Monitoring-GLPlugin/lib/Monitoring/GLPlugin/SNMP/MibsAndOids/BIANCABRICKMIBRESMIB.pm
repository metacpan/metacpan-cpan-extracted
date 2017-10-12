package Monitoring::GLPlugin::SNMP::MibsAndOids::MIBRESOURCE;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'BIANCA-BRICK-MIBRES-MIB'} = {
  url => '',
  name => 'BIANCA-BRICK-MIBRES-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'BIANCA-BRICK-MIBRES-MIB'} =
    '1.3.6.1.4.1.272.4.17.4';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'BIANCA-BRICK-MIBRES-MIB'} = {
  resource => '1.3.6.1.4.1.272.4.17.4.255',
  cpuTable => '1.3.6.1.4.1.272.4.17.4.1',
  cpuEntry => '1.3.6.1.4.1.272.4.17.4.1.1',
  cpuNumber => '1.3.6.1.4.1.272.4.17.4.1.1.1',
  cpuDescr => '1.3.6.1.4.1.272.4.17.4.1.1.2',
  cpuTotalUser => '1.3.6.1.4.1.272.4.17.4.1.1.3',
  cpuTotalSystem => '1.3.6.1.4.1.272.4.17.4.1.1.4',
  cpuTotalStreams => '1.3.6.1.4.1.272.4.17.4.1.1.5',
  cpuTotalIdle => '1.3.6.1.4.1.272.4.17.4.1.1.6',
  cpuLoadUser => '1.3.6.1.4.1.272.4.17.4.1.1.7',
  cpuLoadSystem => '1.3.6.1.4.1.272.4.17.4.1.1.8',
  cpuLoadStreams => '1.3.6.1.4.1.272.4.17.4.1.1.9',
  cpuLoadIdle => '1.3.6.1.4.1.272.4.17.4.1.1.10',
  cpuLoadUser10s => '1.3.6.1.4.1.272.4.17.4.1.1.11',
  cpuLoadSystem10s => '1.3.6.1.4.1.272.4.17.4.1.1.12',
  cpuLoadStreams10s => '1.3.6.1.4.1.272.4.17.4.1.1.13',
  cpuLoadIdle10s => '1.3.6.1.4.1.272.4.17.4.1.1.14',
  cpuLoadUser60s => '1.3.6.1.4.1.272.4.17.4.1.1.15',
  cpuLoadSystem60s => '1.3.6.1.4.1.272.4.17.4.1.1.16',
  cpuLoadStreams60s => '1.3.6.1.4.1.272.4.17.4.1.1.17',
  cpuLoadIdle60s => '1.3.6.1.4.1.272.4.17.4.1.1.18',
  memoryTable => '1.3.6.1.4.1.272.4.17.4.2',
  memoryEntry => '1.3.6.1.4.1.272.4.17.4.2.1',
  memoryType => '1.3.6.1.4.1.272.4.17.4.2.1.1',
  memoryTypeDefinition => 'BIANCA-BRICK-MIBRES-MIB::memoryType',
  memoryDescr => '1.3.6.1.4.1.272.4.17.4.2.1.2',
  memoryBlockSize => '1.3.6.1.4.1.272.4.17.4.2.1.3',
  memoryTotal => '1.3.6.1.4.1.272.4.17.4.2.1.4',
  memoryInuse => '1.3.6.1.4.1.272.4.17.4.2.1.5',
  memoryDramUse => '1.3.6.1.4.1.272.4.17.4.2.1.6',
  memoryNAllocs => '1.3.6.1.4.1.272.4.17.4.2.1.7',
  memoryNFrees => '1.3.6.1.4.1.272.4.17.4.2.1.8',
  memoryNFails => '1.3.6.1.4.1.272.4.17.4.2.1.9',
  dspTable => '1.3.6.1.4.1.272.4.17.4.3',
  dspEntry => '1.3.6.1.4.1.272.4.17.4.3.1',
  dspSlot => '1.3.6.1.4.1.272.4.17.4.3.1.1',
  dspUnit => '1.3.6.1.4.1.272.4.17.4.3.1.2',
  dspDescr => '1.3.6.1.4.1.272.4.17.4.3.1.3',
  dspCapabilities => '1.3.6.1.4.1.272.4.17.4.3.1.4',
  dspTotalChannels => '1.3.6.1.4.1.272.4.17.4.3.1.5',
  dspUsedChannels => '1.3.6.1.4.1.272.4.17.4.3.1.6',
  resourceMIB => '1.3.6.1.4.1.272.4.17.4.255',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'BIANCA-BRICK-MIBRES-MIB'} = {
  memoryType => {
    '1' => 'flash',
    '2' => 'dram',
    '3' => 'dpool',
  },
};

