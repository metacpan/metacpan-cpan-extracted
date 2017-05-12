package Monitoring::GLPlugin::SNMP::MibsAndOids::BDTMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'BDT-MIB'} = {
  url => '',
  name => 'BDT-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'BDT-MIB'} = 
  '1.3.6.1.4.1.20884.10893.2.101.1';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'BDT-MIB'} = {
  'bdt' => '1.3.6.1.4.1.20884',
  'storage' => '1.3.6.1.4.1.20884.10893',
  'hardware' => '1.3.6.1.4.1.20884.10893.2',
  'bDTagent' => '1.3.6.1.4.1.20884.10893.2.101',
  'bDTAgentInfo' => '1.3.6.1.4.1.20884.10893.2.101.1',
  'bDTDisplayName' => '1.3.6.1.4.1.20884.10893.2.101.1.1',
  'bDTDescription' => '1.3.6.1.4.1.20884.10893.2.101.1.2',
  'bDTAgentVendor' => '1.3.6.1.4.1.20884.10893.2.101.1.3',
  'bDTAgentVersion' => '1.3.6.1.4.1.20884.10893.2.101.1.4',
  'bDTGlobalData' => '1.3.6.1.4.1.20884.10893.2.101.2',
  'bDTGlobalStatus' => '1.3.6.1.4.1.20884.10893.2.101.2.1',
  'bDTGlobalStatusDefinition' => 'BDT-MIB::bDTGlobalStatus',
  'bDTLastGlobalStatus' => '1.3.6.1.4.1.20884.10893.2.101.2.2',
  'bDTLastGlobalStatusDefinition' => 'BDT-MIB::bDTLastGlobalStatus',
  'bDTTimeStamp' => '1.3.6.1.4.1.20884.10893.2.101.2.3',
  'bDTGetTimeOut' => '1.3.6.1.4.1.20884.10893.2.101.2.4',
  'bDTErrorCode' => '1.3.6.1.4.1.20884.10893.2.101.2.5',
  'bDTRefreshRate' => '1.3.6.1.4.1.20884.10893.2.101.2.6',
  'bDTErrorData' => '1.3.6.1.4.1.20884.10893.2.101.2.9',
  'bDTDeviceInfo' => '1.3.6.1.4.1.20884.10893.2.101.4',
  'bDTDevSerialNumber' => '1.3.6.1.4.1.20884.10893.2.101.4.1',
  'bDTDevVendorID' => '1.3.6.1.4.1.20884.10893.2.101.4.2',
  'bDTDevProductID' => '1.3.6.1.4.1.20884.10893.2.101.4.3',
  'bDTDevFirmwareRev' => '1.3.6.1.4.1.20884.10893.2.101.4.4',
  'bDTDevRobFirmwareRev' => '1.3.6.1.4.1.20884.10893.2.101.4.5',
  'bDTDevBootcodeRev' => '1.3.6.1.4.1.20884.10893.2.101.4.6',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'BDT-MIB'} = {
  bDTGlobalStatus => {
    '1' => 'other',
    '2' => 'unknown',
    '3' => 'ok',
    '4' => 'non-critical',
    '5' => 'critical',
    '6' => 'non-Recoverable',
  },
  bDTLastGlobalStatus => {
    '1' => 'other',
    '2' => 'unknown',
    '3' => 'ok',
    '4' => 'non-critical',
    '5' => 'critical',
    '6' => 'non-recoverable',
  },
};

1;

__END__
