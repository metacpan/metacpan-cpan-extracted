package Monitoring::GLPlugin::SNMP::MibsAndOids::ASYNCOSMAILMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'ASYNCOS-MAIL-MIB'} = {
  url => '',
  name => 'ASYNCOS-MAIL-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::requirements->{'ASYNCOS-MAIL-MIB'} = [
  'SNMPv2-TC-v1-MIB',
];

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'ASYNCOS-MAIL-MIB'} = {
  'asyncOSMailObjects' => '1.3.6.1.4.1.15497.1.1.1',
  'perCentMemoryUtilization' => '1.3.6.1.4.1.15497.1.1.1.1.0',
  'perCentCPUUtilization' => '1.3.6.1.4.1.15497.1.1.1.2.0',
  'perCentDiskIOUtilization' => '1.3.6.1.4.1.15497.1.1.1.3.0',
  'perCentQueueUtilization' => '1.3.6.1.4.1.15497.1.1.1.4.0',
  'queueAvailabilityStatus' => '1.3.6.1.4.1.15497.1.1.1.5.0',
  'queueAvailabilityStatusDefinition' => {
    '1' => 'queueSpaceAvailable',
    '2' => 'queueSpaceShortage',
    '3' => 'queueFull',
  },
  'resourceConservationReason' => '1.3.6.1.4.1.15497.1.1.1.6.0',
  'memoryAvailabilityStatus' => '1.3.6.1.4.1.15497.1.1.1.7.0',
  'memoryAvailabilityStatusDefinition' => {
    '1' => 'memoryAvailable',
    '2' => 'memoryShortage',
    '3' => 'memoryFull',
  },
  'powerSupplyTable' => '1.3.6.1.4.1.15497.1.1.1.8',
  'powerSupplyEntry' => '1.3.6.1.4.1.15497.1.1.1.8.1',
  'powerSupplyIndex' => '1.3.6.1.4.1.15497.1.1.1.8.1.1',
  'powerSupplyStatus' => '1.3.6.1.4.1.15497.1.1.1.8.1.2',
  'powerSupplyStatusDefinition' => {
    '1' => 'powerSupplyNotInstalled',
    '2' => 'powerSupplyHealthy',
    '3' => 'powerSupplyNoAC',
    '4' => 'powerSupplyFaulty',
  },
  'powerSupplyRedundancy' => '1.3.6.1.4.1.15497.1.1.1.8.1.3',
  'powerSupplyName' => '1.3.6.1.4.1.15497.1.1.1.8.1.4',
  'temperatureTable' => '1.3.6.1.4.1.15497.1.1.1.9',
  'temperatureEntry' => '1.3.6.1.4.1.15497.1.1.1.9.1',
  'temperatureIndex' => '1.3.6.1.4.1.15497.1.1.1.9.1.1',
  'degreesCelsius' => '1.3.6.1.4.1.15497.1.1.1.9.1.2',
  'temperatureName' => '1.3.6.1.4.1.15497.1.1.1.9.1.3',
  'fanTable' => '1.3.6.1.4.1.15497.1.1.1.10',
  'fanEntry' => '1.3.6.1.4.1.15497.1.1.1.10.1',
  'fanIndex' => '1.3.6.1.4.1.15497.1.1.1.10.1.1',
  'fanRPMs' => '1.3.6.1.4.1.15497.1.1.1.10.1.2',
  'fanName' => '1.3.6.1.4.1.15497.1.1.1.10.1.3',
  'workQueueMessages' => '1.3.6.1.4.1.15497.1.1.1.11.0',
  'keyExpirationTable' => '1.3.6.1.4.1.15497.1.1.1.12',
  'keyExpirationEntry' => '1.3.6.1.4.1.15497.1.1.1.12.1',
  'keyExpirationIndex' => '1.3.6.1.4.1.15497.1.1.1.12.1.1',
  'keyDescription' => '1.3.6.1.4.1.15497.1.1.1.12.1.2',
  'keyIsPerpetual' => '1.3.6.1.4.1.15497.1.1.1.12.1.3',
  'keyIsPerpetualDefinition' => 'SNMPv2-TC-v1-MIB::TruthValue',
  'keySecondsUntilExpire' => '1.3.6.1.4.1.15497.1.1.1.12.1.4',
  'updateTable' => '1.3.6.1.4.1.15497.1.1.1.13',
  'updateEntry' => '1.3.6.1.4.1.15497.1.1.1.13.1',
  'updateIndex' => '1.3.6.1.4.1.15497.1.1.1.13.1.1',
  'updateServiceName' => '1.3.6.1.4.1.15497.1.1.1.13.1.2',
  'updates' => '1.3.6.1.4.1.15497.1.1.1.13.1.3',
  'updateFailures' => '1.3.6.1.4.1.15497.1.1.1.13.1.4',
  'oldestMessageAge' => '1.3.6.1.4.1.15497.1.1.1.14.0',
  'outstandingDNSRequests' => '1.3.6.1.4.1.15497.1.1.1.15.0',
  'pendingDNSRequests' => '1.3.6.1.4.1.15497.1.1.1.16.0',
  'raidEvents' => '1.3.6.1.4.1.15497.1.1.1.17.0',
  'raidTable' => '1.3.6.1.4.1.15497.1.1.1.18',
  'raidEntry' => '1.3.6.1.4.1.15497.1.1.1.18.1',
  'raidIndex' => '1.3.6.1.4.1.15497.1.1.1.18.1.1',
  'raidStatus' => '1.3.6.1.4.1.15497.1.1.1.18.1.2',
  'raidStatusDefinition' => {
    '1' => 'driveHealthy',
    '2' => 'driveFailure',
    '3' => 'driveRebuild',
  },
  'raidID' => '1.3.6.1.4.1.15497.1.1.1.18.1.3',
  'raidLastError' => '1.3.6.1.4.1.15497.1.1.1.18.1.4',
  'openFilesOrSockets' => '1.3.6.1.4.1.15497.1.1.1.19.0',
  'mailTransferThreads' => '1.3.6.1.4.1.15497.1.1.1.20.0',
};


1;

__END__
