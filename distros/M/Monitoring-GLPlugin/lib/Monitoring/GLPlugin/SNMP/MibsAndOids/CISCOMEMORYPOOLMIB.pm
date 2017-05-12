package Monitoring::GLPlugin::SNMP::MibsAndOids::CISCOMEMORYPOOLMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'CISCO-MEMORY-POOL-MIB'} = {
  url => '',
  name => 'CISCO-MEMORY-POOL-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-MEMORY-POOL-MIB'} = {
  'ciscoMemoryPoolTable' => '1.3.6.1.4.1.9.9.48.1.1',
  'ciscoMemoryPoolEntry' => '1.3.6.1.4.1.9.9.48.1.1.1',
  'ciscoMemoryPoolType' => '1.3.6.1.4.1.9.9.48.1.1.1.1',
  'ciscoMemoryPoolTypeDefinition' => {
    '1' => 'processor memory',
    '2' => 'i/o memory',
    '3' => 'pci memory',
    '4' => 'fast memory',
    '5' => 'multibus memory',
  },
  'ciscoMemoryPoolName' => '1.3.6.1.4.1.9.9.48.1.1.1.2',
  'ciscoMemoryPoolAlternate' => '1.3.6.1.4.1.9.9.48.1.1.1.3',
  'ciscoMemoryPoolValid' => '1.3.6.1.4.1.9.9.48.1.1.1.4',
  'ciscoMemoryPoolUsed' => '1.3.6.1.4.1.9.9.48.1.1.1.5',
  'ciscoMemoryPoolFree' => '1.3.6.1.4.1.9.9.48.1.1.1.6',
  'ciscoMemoryPoolLargestFree' => '1.3.6.1.4.1.9.9.48.1.1.1.7',
};


1;

__END__
