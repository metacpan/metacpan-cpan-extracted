$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'OPENBSD-MEM-MIB'} = {
  url => '',
  name => 'OPENBSD-MEM-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'OPENBSD-MEM-MIB'} =
  '1.3.6.1.4.1.30155.5';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'OPENBSD-MEM-MIB'} = {
  # openBSD.memMIBObjects
  memMIBVersion => '1.3.6.1.4.1.30155.5.1',
  memIfTable => '1.3.6.1.4.1.30155.5.2',
  memIfEntry => '1.3.6.1.4.1.30155.5.2.1',
  memIfIndex => '1.3.6.1.2.1.2.2.1.1',
  memIfName => '1.3.6.1.4.1.30155.5.2.1.1',
  memIfLiveLocks => '1.3.6.1.4.1.30155.5.2.1.2',
};

