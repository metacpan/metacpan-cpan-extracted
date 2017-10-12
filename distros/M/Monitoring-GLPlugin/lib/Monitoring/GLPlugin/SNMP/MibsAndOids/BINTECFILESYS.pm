package Monitoring::GLPlugin::SNMP::MibsAndOids::MIBFILESYS;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'MIB-FILESYS'} = {
  url => '',
  name => 'MIB-FILESYS',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'MIB-FILESYS'} =
    '1.3.6.1.4.1.272.4.22.7';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'MIB-FILESYS'} = {
  fsMIB => '1.3.6.1.4.1.272.4.22.7',
  fsDiskTable => '1.3.6.1.4.1.272.4.22.7.1',
  fsDiskEntry => '1.3.6.1.4.1.272.4.22.7.1.1',
  fsDiskId => '1.3.6.1.4.1.272.4.22.7.1.1.1',
  fsDiskDevName => '1.3.6.1.4.1.272.4.22.7.1.1.2',
  fsDiskDevInfo => '1.3.6.1.4.1.272.4.22.7.1.1.3',
  fsDiskStatus => '1.3.6.1.4.1.272.4.22.7.1.1.4',
  fsDiskStatusDefinition => {
    '0' => 'inserted',
    '1' => 'mounted',
    '2' => 'readonly',
    '7' => 'error',
  },
  fsDiskCommand => '1.3.6.1.4.1.272.4.22.7.1.1.5',
  fsDiskCommandDefinition => 'BINTEC-FILESYS::fsDiskCommand',
  fsDiskFsType => '1.3.6.1.4.1.272.4.22.7.1.1.6',
  fsDiskFsTypeDefinition => 'BINTEC-FILESYS::fsDiskFsType',
  fsDiskSize => '1.3.6.1.4.1.272.4.22.7.1.1.8',
  fsDiskBlocks => '1.3.6.1.4.1.272.4.22.7.1.1.9',
  fsDiskFreeBlocks => '1.3.6.1.4.1.272.4.22.7.1.1.11',
  fsDiskInfoMsg => '1.3.6.1.4.1.272.4.22.7.1.1.13',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'MIB-FILESYS'} = {
  fsDiskCommand => {
    '0' => 'none',
    '1' => 'mount',
    '2' => 'umount',
    '3' => 'format',
  },
  fsDiskFsType => {
    '0' => 'unkown',
    '1' => 'fat12',
    '2' => 'fat16',
    '3' => 'fat32',
  },
};
