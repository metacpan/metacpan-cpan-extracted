package Monitoring::GLPlugin::SNMP::MibsAndOids::ENTITYMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'ENTITY-MIB'} = {
  url => '',
  name => 'ENTITY-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'ENTITY-MIB'} = {
  'entPhysicalTable' => '1.3.6.1.2.1.47.1.1.1',
  'entPhysicalEntry' => '1.3.6.1.2.1.47.1.1.1.1',
  'entPhysicalIndex' => '1.3.6.1.2.1.47.1.1.1.1.1',
  'entPhysicalDescr' => '1.3.6.1.2.1.47.1.1.1.1.2',
  'entPhysicalVendorType' => '1.3.6.1.2.1.47.1.1.1.1.3',
  'entPhysicalContainedIn' => '1.3.6.1.2.1.47.1.1.1.1.4',
  'entPhysicalClass' => '1.3.6.1.2.1.47.1.1.1.1.5',
  'entPhysicalClassDefinition' => 'ENTITY-MIB::PhysicalClass',
  'entPhysicalParentRelPos' => '1.3.6.1.2.1.47.1.1.1.1.6',
  'entPhysicalName' => '1.3.6.1.2.1.47.1.1.1.1.7',
  'entPhysicalHardwareRev' => '1.3.6.1.2.1.47.1.1.1.1.8',
  'entPhysicalFirmwareRev' => '1.3.6.1.2.1.47.1.1.1.1.9',
  'entPhysicalSoftwareRev' => '1.3.6.1.2.1.47.1.1.1.1.10',
  'entPhysicalSerialNum' => '1.3.6.1.2.1.47.1.1.1.1.11',
  'entPhysicalMfgName' => '1.3.6.1.2.1.47.1.1.1.1.12',
  'entPhysicalModelName' => '1.3.6.1.2.1.47.1.1.1.1.13',
  'entPhysicalAlias' => '1.3.6.1.2.1.47.1.1.1.1.14',
  'entPhysicalAssetID' => '1.3.6.1.2.1.47.1.1.1.1.15',
  'entPhysicalIsFRU' => '1.3.6.1.2.1.47.1.1.1.1.16',
  'entPhysicalIsFRUDefinition' => {
    '1' => 'true',
    '2' => 'false',
  },
  'entPhysicalMfgDate' => '1.3.6.1.2.1.47.1.1.1.1.17',
  'entPhysicalUris' => '1.3.6.1.2.1.47.1.1.1.1.18',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'ENTITY-MIB'} = {
  'PhysicalClass' => {
    '1' => 'other',
    '2' => 'unknown',
    '3' => 'chassis',
    '4' => 'backplane',
    '5' => 'container',
    '6' => 'powerSupply',
    '7' => 'fan',
    '8' => 'sensor',
    '9' => 'module',
    '10' => 'port',
    '11' => 'stack',
    '12' => 'cpu',
  },
};

1;

__END__
