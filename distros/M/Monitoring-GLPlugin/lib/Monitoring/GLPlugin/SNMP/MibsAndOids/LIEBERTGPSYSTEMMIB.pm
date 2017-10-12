package Monitoring::GLPlugin::SNMP::MibsAndOids::LIEBERTGPSYSTEMMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'LIEBERT-GP-SYSTEM-MIB'} = {
  url => '',
  name => 'LIEBERT-GP-SYSTEM-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'LIEBERT-GP-SYSTEM-MIB'} =
  '1.3.6.1.4.1.476.1.42.3.7';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'LIEBERT-GP-SYSTEM-MIB'} = {
  liebertSystemModule => '1.3.6.1.4.1.476.1.42.1.8.1',
  lgpSysStatistics => '1.3.6.1.4.1.476.1.42.3.7.1',
  lgpSysStatisticsRunHrs => '1.3.6.1.4.1.476.1.42.3.7.1.1',
  lgpSysStatus => '1.3.6.1.4.1.476.1.42.3.7.2',
  lgpSysSelfTestResult => '1.3.6.1.4.1.476.1.42.3.7.2.1',
  lgpSysSelfTestResultDefinition => 'LIEBERT-GP-SYSTEM-MIB::lgpSysSelfTestResult',
  lgpSysState => '1.3.6.1.4.1.476.1.42.3.7.2.2',
  lgpSysStateDefinition => 'LIEBERT-GP-SYSTEM-MIB::lgpSysState',
  lgpSysSettings => '1.3.6.1.4.1.476.1.42.3.7.3',
  lgpSysAudibleAlarm => '1.3.6.1.4.1.476.1.42.3.7.3.1',
  lgpSysAudibleAlarmDefinition => 'LIEBERT-GP-SYSTEM-MIB::lgpSysAudibleAlarm',
  lgpSysControl => '1.3.6.1.4.1.476.1.42.3.7.4',
  lgpSysSelfTest => '1.3.6.1.4.1.476.1.42.3.7.4.1',
  lgpSysControlOperationOnOff => '1.3.6.1.4.1.476.1.42.3.7.4.2',
  lgpSysControlOperationOnOffDefinition => 'LIEBERT-GP-SYSTEM-MIB::lgpSysControlOperationOnOff',
  lgpSysTime => '1.3.6.1.4.1.476.1.42.3.7.5',
  lgpSysTimeEpoch => '1.3.6.1.4.1.476.1.42.3.7.5.1',
  lgpSysMaintenance => '1.3.6.1.4.1.476.1.42.3.7.6',
  lgpSysMaintenanceCapacity => '1.3.6.1.4.1.476.1.42.3.7.6.1',
  lgpSysMaintenanceYear => '1.3.6.1.4.1.476.1.42.3.7.6.2',
  lgpSysMaintenanceMonth => '1.3.6.1.4.1.476.1.42.3.7.6.3',
  lgpSysEventDescription => '1.3.6.1.4.1.476.1.42.3.7.7',
  lgpSysEventNotifications => '1.3.6.1.4.1.476.1.42.3.7.8',
  lgpSysDeviceComponentGroup => '1.3.6.1.4.1.476.1.42.3.7.9',
  lgpSysDeviceComponentTable => '1.3.6.1.4.1.476.1.42.3.7.9.1',
  lgpSysDeviceComponentEntry => '1.3.6.1.4.1.476.1.42.3.7.9.1.1',
  lgpSysDeviceComponentIndex => '1.3.6.1.4.1.476.1.42.3.7.9.1.1.1',
  lgpSysDeviceComponentDescr => '1.3.6.1.4.1.476.1.42.3.7.9.1.1.2',
  lgpSysDeviceComponentSerialNum => '1.3.6.1.4.1.476.1.42.3.7.9.1.1.3',
  lgpSysDeviceComponentModelNum => '1.3.6.1.4.1.476.1.42.3.7.9.1.1.4',
  lgpSysDeviceComponentWellknown => '1.3.6.1.4.1.476.1.42.3.7.9.5',
  lgpSysDeviceBatCabinet => '1.3.6.1.4.1.476.1.42.3.7.9.5.5',
  lgpSysDeviceParallelCabinet => '1.3.6.1.4.1.476.1.42.3.7.9.5.6',
  lgpSysDeviceMaintBypass => '1.3.6.1.4.1.476.1.42.3.7.9.5.7',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'LIEBERT-GP-SYSTEM-MIB'} = {
  lgpSysControlOperationOnOff => {
    '1' => 'on',
    '2' => 'off',
  },
  lgpSysAudibleAlarm => {
    '1' => 'on',
    '2' => 'off',
  },
  lgpSysSelfTestResult => {
    '1' => 'unknown',
    '2' => 'passed',
    '3' => 'failed',
    '4' => 'inProgress',
    '5' => 'sysFailure',
    '6' => 'inhibited',
  },
  lgpSysState => {
    '1' => 'normalOperation',
    '2' => 'startUp',
    '3' => 'normalWithWarning',
    '4' => 'normalWithAlarm',
    '5' => 'abnormalOperation',
  },
};
