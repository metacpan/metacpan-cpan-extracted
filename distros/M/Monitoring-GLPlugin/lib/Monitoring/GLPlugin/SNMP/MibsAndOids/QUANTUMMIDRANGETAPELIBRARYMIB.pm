package Monitoring::GLPlugin::SNMP::MibsAndOids::QUANTUMMIDRANGETAPELIBRARYMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB'} = {
  url => 'http://qsupport.quantum.com/kb/flare/content/Scalar_i6/downloads/SupDocs/6-68533-01_Scalar_i3_i6_SNMP_Guide.pdf',
  name => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB'} =
    '1.3.6.1.4.1.3697.1.10.15',

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB'} = {
  quantum => '1.3.6.1.4.1.3697',
  storage => '1.3.6.1.4.1.3697.1',
  library => '1.3.6.1.4.1.3697.1.10',
  mrTapeLibraryMIB => '1.3.6.1.4.1.3697.1.10.15',
  mrTapeLibraryMIBNotificationPrefix => '1.3.6.1.4.1.3697.1.10.15.1',
  mrTapeLibraryMIBNotifications => '1.3.6.1.4.1.3697.1.10.15.1.0',
  mrTapeLibraryMIBConformance => '1.3.6.1.4.1.3697.1.10.15.2',
  mrTapeLibraryMIBCompliances => '1.3.6.1.4.1.3697.1.10.15.2.1',
  mrTapeLibraryMIBGroups => '1.3.6.1.4.1.3697.1.10.15.2.2',
  mrTapeLibrary => '1.3.6.1.4.1.3697.1.10.15.5',
  libraryIpAddress => '1.3.6.1.4.1.3697.1.10.15.5.1',
  libraryURL => '1.3.6.1.4.1.3697.1.10.15.5.2',
  libraryName => '1.3.6.1.4.1.3697.1.10.15.5.3',
  libraryVendor => '1.3.6.1.4.1.3697.1.10.15.5.4',
  libraryModel => '1.3.6.1.4.1.3697.1.10.15.5.5',
  libraryDescription => '1.3.6.1.4.1.3697.1.10.15.5.6',
  libraryProductName => '1.3.6.1.4.1.3697.1.10.15.5.7',
  librarySerialNumber => '1.3.6.1.4.1.3697.1.10.15.5.8',
  libraryFirmwareVersion => '1.3.6.1.4.1.3697.1.10.15.5.9',
  libraryGlobalStatus => '1.3.6.1.4.1.3697.1.10.15.5.10',
  libraryGlobalStatusDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::RASSubSystemStatus',
  rasSubSystem => '1.3.6.1.4.1.3697.1.10.15.5.50',
  libraryRASStatus => '1.3.6.1.4.1.3697.1.10.15.5.50.1',
  libraryRASStatusDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::RASSubSystemStatus',
  driveRASStatus => '1.3.6.1.4.1.3697.1.10.15.5.50.2',
  driveRASStatusDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::RASSubSystemStatus',
  mediaRASStatus => '1.3.6.1.4.1.3697.1.10.15.5.50.3',
  mediaRASStatusDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::RASSubSystemStatus',
  physicalLibrary => '1.3.6.1.4.1.3697.1.10.15.5.60',
  physicalLibraryState => '1.3.6.1.4.1.3697.1.10.15.5.60.1',
  physicalLibraryStateDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::LibraryState',
  aggregatedMagazineStatus => '1.3.6.1.4.1.3697.1.10.15.5.60.2',
  aggregatedMagazineStatusDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::LibraryMagazineStatus',
  aggregatedIEAreaStatus => '1.3.6.1.4.1.3697.1.10.15.5.60.3',
  aggregatedIEAreaStatusDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::IEAreaStatus',
  libraryCartridgeSlots => '1.3.6.1.4.1.3697.1.10.15.5.60.4',
  libraryStorageSlotCount => '1.3.6.1.4.1.3697.1.10.15.5.60.4.1',
  libraryCleanSlotCount => '1.3.6.1.4.1.3697.1.10.15.5.60.4.2',
  libraryIESlotCount => '1.3.6.1.4.1.3697.1.10.15.5.60.4.3',
  libraryMedia => '1.3.6.1.4.1.3697.1.10.15.5.60.5',
  libraryMediaCount => '1.3.6.1.4.1.3697.1.10.15.5.60.5.1',
  libraryCleaningTapeCount => '1.3.6.1.4.1.3697.1.10.15.5.60.5.2',
  logicalLibrary => '1.3.6.1.4.1.3697.1.10.15.5.70',
  libraryPartitionCount => '1.3.6.1.4.1.3697.1.10.15.5.70.1',
  logicalLibraryTable => '1.3.6.1.4.1.3697.1.10.15.5.70.2',
  logicalLibraryEntry => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1',
  logicalLibraryIndex => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.1',
  logicalLibraryName => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.2',
  logicalLibrarySerialNumber => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.3',
  logicalLibraryModel => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.4',
  logicalLibraryType => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.5',
  logicalLibraryTypeDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::PartitionType',
  logicalLibraryInterface => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.6',
  logicalLibraryInterfaceDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::InterfaceMethod',
  logicalLibraryControl => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.7',
  logicalLibraryControlDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::RedundancyConfiguration',
  logicalLibraryMode => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.8',
  logicalLibraryModeDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::DeviceMode',
  logicalLibraryState => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.9',
  logicalLibraryStateDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::LibraryState',
  logicalLibraryAutoClean => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.10',
  logicalLibraryAutoCleanDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::DisabledEnabled',
  logicalLibraryNumSlots => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.11',
  logicalLibraryNumIE => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.12',
  logicalLibraryNumTapeDrives => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.13',
  logicalLibraryStorageElemAddr => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.14',
  logicalLibraryIEElemAddr => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.15',
  logicalLibraryTapeDriveElemAddr => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.16',
  logicalLibraryChangerDeviceAddr => '1.3.6.1.4.1.3697.1.10.15.5.70.2.1.17',
  physicalDrive => '1.3.6.1.4.1.3697.1.10.15.5.80',
  libraryPhDriveCount => '1.3.6.1.4.1.3697.1.10.15.5.80.1',
  physicalDriveTable => '1.3.6.1.4.1.3697.1.10.15.5.80.2',
  physicalDriveEntry => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1',
  phDriveIndex => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.1',
  phDriveLocation => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.2',
  phDriveDeviceId => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.3',
  phDriveVendor => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.4',
  phDriveType => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.5',
  phDriveInterfaceType => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.6',
  phDriveInterfaceTypeDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::InterfaceType',
  phDriveAddress => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.7',
  phDrivePhysicalSerialNumber => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.8',
  phDriveLogicalSerialNumber => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.9',
  phDriveFirmwareVersion => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.10',
  phDriveMode => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.11',
  phDriveModeDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::DeviceMode',
  phDriveState => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.12',
  phDriveStateDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::DeviceState',
  phDriveRasStatus => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.13',
  phDriveRasStatusDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::RASSubSystemStatus',
  phDriveLoads => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.14',
  phDriveCleaningStatus => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.15',
  phDriveCleaningStatusDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::CleaningStatus',
  phDriveLogicalLibraryName => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.16',
  phDriveControlPathDrive => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.17',
  phDriveControlPathDriveDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::ControlPathType',
  phDriveDataPathConfiguration => '1.3.6.1.4.1.3697.1.10.15.5.80.2.1.18',
  phDriveDataPathConfigurationDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::RedundancyConfiguration',
  libraryPowerSupply => '1.3.6.1.4.1.3697.1.10.15.5.100',
  libraryPSCount => '1.3.6.1.4.1.3697.1.10.15.5.100.1',
  libraryPowerSupplyTable => '1.3.6.1.4.1.3697.1.10.15.5.100.2',
  libraryPowerSupplyEntry => '1.3.6.1.4.1.3697.1.10.15.5.100.2.1',
  libraryPSIndex => '1.3.6.1.4.1.3697.1.10.15.5.100.2.1.1',
  libraryPSName => '1.3.6.1.4.1.3697.1.10.15.5.100.2.1.2',
  libraryPSLocation => '1.3.6.1.4.1.3697.1.10.15.5.100.2.1.3',
  libraryPSType => '1.3.6.1.4.1.3697.1.10.15.5.100.2.1.4',
  libraryPSTypeDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::VoltageType',
  libraryPSWattage => '1.3.6.1.4.1.3697.1.10.15.5.100.2.1.5',
  # einzige fundstelle fuer diese mib war ein pdf, s.o.
  # da drin steht
  # libraryPSWattage
  # DESCRIPTION "Power output rating in units of Watts."
  # ::= { libraryPowerSupplyEntry 5 }
  # libraryPSStatus
  # DESCRIPTION "Status of the P/S."
  # ::= { libraryPowerSupplyEntry 7 }
  # libraryPSPowerConsumption
  # DESCRIPTION "Power consumption in units of Watts."
  # ::= { libraryPowerSupplyEntry 8 }
  # in den beispieldaten steht
  # .1.3.6.1.4.1.3697.1.10.15.5.100.2.1.5.0 = INTEGER: 315
  # .1.3.6.1.4.1.3697.1.10.15.5.100.2.1.5.1 = INTEGER: 315
  # .1.3.6.1.4.1.3697.1.10.15.5.100.2.1.5.2 = INTEGER: 315
  # .1.3.6.1.4.1.3697.1.10.15.5.100.2.1.5.3 = INTEGER: 315
  # .1.3.6.1.4.1.3697.1.10.15.5.100.2.1.6.0 = INTEGER: 1
  # .1.3.6.1.4.1.3697.1.10.15.5.100.2.1.6.1 = INTEGER: 1
  # .1.3.6.1.4.1.3697.1.10.15.5.100.2.1.6.2 = INTEGER: 1
  # .1.3.6.1.4.1.3697.1.10.15.5.100.2.1.6.3 = INTEGER: 1
  # .1.3.6.1.4.1.3697.1.10.15.5.100.2.1.7.0 = INTEGER: 62
  # .1.3.6.1.4.1.3697.1.10.15.5.100.2.1.7.1 = INTEGER: 54
  # .1.3.6.1.4.1.3697.1.10.15.5.100.2.1.7.2 = INTEGER: 58
  # .1.3.6.1.4.1.3697.1.10.15.5.100.2.1.7.3 = INTEGER: 44
  # .1.3.6.1.4.1.3697.1.10.15.5.100.2.1.8 = INTEGER: 62
  # d.h. status ist 62, 54, 58, 44, und _1_ powerconsumption mit 62,
  # die ganz zufaellig dem status von index 0 entspricht.
  # das ist sowohl murks in der mib-datei als auch in der implementierung.
  # ich korrigiere jetzt libraryPSStatus = die vergessene 6 und
  # libraryPSPowerConsumption = 7 und woher der ...2.1.8 kommt ist mir wurscht
  # 
  libraryPSStatus => '1.3.6.1.4.1.3697.1.10.15.5.100.2.1.6',
  libraryPSStatusDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::PSStatus',
  libraryPSPowerConsumption => '1.3.6.1.4.1.3697.1.10.15.5.100.2.1.7',
  libraryVoltageSensor => '1.3.6.1.4.1.3697.1.10.15.5.110',
  libraryVoltageSensorCount => '1.3.6.1.4.1.3697.1.10.15.5.110.1',
  libraryVoltageSensorTable => '1.3.6.1.4.1.3697.1.10.15.5.110.2',
  libraryVoltageSensorEntry => '1.3.6.1.4.1.3697.1.10.15.5.110.2.1',
  libraryVoltageSensorIndex => '1.3.6.1.4.1.3697.1.10.15.5.110.2.1.1',
  libraryVoltageSensorName => '1.3.6.1.4.1.3697.1.10.15.5.110.2.1.2',
  libraryVoltageSensorLocation => '1.3.6.1.4.1.3697.1.10.15.5.110.2.1.3',
  libraryVoltageSensorType => '1.3.6.1.4.1.3697.1.10.15.5.110.2.1.4',
  libraryVoltageSensorTypeDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::VoltageType',
  libraryVoltageSensorStatus => '1.3.6.1.4.1.3697.1.10.15.5.110.2.1.5',
  libraryVoltageSensorStatusDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::SensorStatus',
  libraryVoltageSensorValue => '1.3.6.1.4.1.3697.1.10.15.5.110.2.1.6',
  libraryEnvironmentalSensor => '1.3.6.1.4.1.3697.1.10.15.5.120',
  libraryHumidity => '1.3.6.1.4.1.3697.1.10.15.5.120.1',
  libraryHumiditySensorCount => '1.3.6.1.4.1.3697.1.10.15.5.120.1.1',
  libraryHumiditySensorTable => '1.3.6.1.4.1.3697.1.10.15.5.120.1.2',
  libraryHumiditySensorEntry => '1.3.6.1.4.1.3697.1.10.15.5.120.1.2.1',
  libraryHumiditySensorIndex => '1.3.6.1.4.1.3697.1.10.15.5.120.1.2.1.1',
  libraryHumiditySensorName => '1.3.6.1.4.1.3697.1.10.15.5.120.1.2.1.2',
  libraryHumiditySensorLocation => '1.3.6.1.4.1.3697.1.10.15.5.120.1.2.1.3',
  libraryHumiditySensorStatus => '1.3.6.1.4.1.3697.1.10.15.5.120.1.2.1.4',
  libraryHumiditySensorStatusDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::SensorStatus',
  libraryHumiditySensorValue => '1.3.6.1.4.1.3697.1.10.15.5.120.1.2.1.5',
  libraryTemperature => '1.3.6.1.4.1.3697.1.10.15.5.120.2',
  libraryTemperatureSensorCount => '1.3.6.1.4.1.3697.1.10.15.5.120.2.1',
  libraryTemperatureSensorTable => '1.3.6.1.4.1.3697.1.10.15.5.120.2.2',
  libraryTemperatureSensorEntry => '1.3.6.1.4.1.3697.1.10.15.5.120.2.2.1',
  libraryTemperatureSensorIndex => '1.3.6.1.4.1.3697.1.10.15.5.120.2.2.1.1',
  libraryTemperatureSensorName => '1.3.6.1.4.1.3697.1.10.15.5.120.2.2.1.2',
  libraryTemperatureSensorLocation => '1.3.6.1.4.1.3697.1.10.15.5.120.2.2.1.3',
  libraryTemperatureSensorStatus => '1.3.6.1.4.1.3697.1.10.15.5.120.2.2.1.4',
  libraryTemperatureSensorStatusDefinition => 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB::SensorStatus',
  libraryTemperatureSensorValue => '1.3.6.1.4.1.3697.1.10.15.5.120.2.2.1.5',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB'} = {
  VoltageType => {
    '0' => 'unknown',
    '1' => 'ac',
    '2' => 'dc',
  },
  InterfaceMethod => {
    '0' => 'unknown',
    '1' => 'noInterface',
    '2' => 'viaControlPathDrive',
    '3' => 'viaConnectionBlade',
    '4' => 'viaControllerBlade',
  },
  RASSubSystemStatus => {
    '0' => 'unknown',
    '1' => 'redFailure',
    '2' => 'orangeDegraded',
    '3' => 'yellowWarning',
    '4' => 'blueAttention',
    '5' => 'greenInformation',
    '6' => 'greenGood',
  },
  LibraryState => {
    '0' => 'unknown',
    '1' => 'ready',
    '2' => 'notReady',
    '3' => 'becomingReady',
  },
  LibraryMagazineStatus => {
    '0' => 'unknown',
    '1' => 'allPresent',
    '2' => 'notAllPresent',
  },
  ControlPathType => {
    '0' => 'unknown',
    '1' => 'none',
    '2' => 'cpActive',
    '3' => 'cpStandby',
  },
  PSStatus => {
    '0' => 'unknown',
    '1' => 'good',
    '2' => 'failed',
    '3' => 'missing',
  },
  SensorStatus => {
    '0' => 'unknown',
    '1' => 'normal',
    '2' => 'warning',
    '3' => 'critical',
  },
  DeviceState => {
    '0' => 'unknown',
    '1' => 'variedOn',
    '2' => 'variedOff',
    '3' => 'notReady',
    '4' => 'notInstalled',
  },
  IEAreaStatus => {
    '0' => 'unknown',
    '1' => 'insertedClosed',
    '2' => 'ejectedOpen',
  },
  InterfaceType => {
    '0' => 'unknown',
    '1' => 'scsi',
    '2' => 'fc',
    '3' => 'sas',
    '4' => 'iscsi',
  },
  DisabledEnabled => {
    '0' => 'disabled',
    '1' => 'enabled',
  },
  DeviceMode => {
    '0' => 'unknown',
    '1' => 'online',
    '2' => 'offline',
  },
  CleaningStatus => {
    '0' => 'unknown',
    '1' => 'notNeeded',
    '2' => 'recommended',
    '3' => 'required',
  },
  RedundancyConfiguration => {
    '0' => 'unknown',
    '1' => 'noRedundancy',
    '2' => 'multiPath',
    '3' => 'basicPathFailover',
    '4' => 'advancedPathFailover',
  },
  PartitionType => {
    '0' => 'unknown',
    '1' => 'standard',
    '2' => 'libraryManaged',
    '3' => 'libraryManagedEDLM',
    '4' => 'libraryManagedAMP',
    '5' => 'libraryManagedVault',
  },
};
