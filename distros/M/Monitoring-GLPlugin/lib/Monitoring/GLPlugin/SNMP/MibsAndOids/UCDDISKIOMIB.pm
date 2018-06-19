package Monitoring::GLPlugin::SNMP::MibsAndOids::UCDDISKIOMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'UCD-DISKIO-MIB'} = {
  url => 'http://www.circitor.fr/Mibs/Files/UCD-DISKIO-MIB.mib',
  name => 'UCD-DISKIO-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'UCD-DISKIO-MIB'} =
    '1.3.6.1.4.1.2021.13.15';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'UCD-DISKIO-MIB'} = {
  ucdDiskIOMIB => '1.3.6.1.4.1.2021.13.15',
  diskIOTable => '1.3.6.1.4.1.2021.13.15.1',
  diskIOEntry => '1.3.6.1.4.1.2021.13.15.1.1',
  diskIOIndex => '1.3.6.1.4.1.2021.13.15.1.1.1',
  diskIODevice => '1.3.6.1.4.1.2021.13.15.1.1.2',
  diskIONRead => '1.3.6.1.4.1.2021.13.15.1.1.3',
  diskIONWritten => '1.3.6.1.4.1.2021.13.15.1.1.4',
  diskIOReads => '1.3.6.1.4.1.2021.13.15.1.1.5',
  diskIOWrites => '1.3.6.1.4.1.2021.13.15.1.1.6',
  diskIOLA1 => '1.3.6.1.4.1.2021.13.15.1.1.9',
  diskIOLA5 => '1.3.6.1.4.1.2021.13.15.1.1.10',
  diskIOLA15 => '1.3.6.1.4.1.2021.13.15.1.1.11',
  diskIONReadX => '1.3.6.1.4.1.2021.13.15.1.1.12',
  diskIONWrittenX => '1.3.6.1.4.1.2021.13.15.1.1.13',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'UCD-DISKIO-MIB'} = {
};
