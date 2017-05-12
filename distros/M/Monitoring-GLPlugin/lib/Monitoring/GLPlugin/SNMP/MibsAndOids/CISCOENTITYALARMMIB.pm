package Monitoring::GLPlugin::SNMP::MibsAndOids::CISCOENTITYALARMMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'CISCO-ENTITY-ALARM-MIB'} = {
  url => '',
  name => 'CISCO-ENTITY-ALARM-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'CISCO-ENTITY-ALARM-MIB'} = 
  '1.3.6.1.4.1.9.9.138.1';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-ENTITY-ALARM-MIB'} = {
  'ciscoEntityAlarmMIBObjects' => '1.3.6.1.4.1.9.9.138.1',
  'ceAlarmDescription' => '1.3.6.1.4.1.9.9.138.1.1',
  'ceAlarmDescrMapTable' => '1.3.6.1.4.1.9.9.138.1.1.1',
  'ceAlarmDescrMapEntry' => '1.3.6.1.4.1.9.9.138.1.1.1.1',
  'ceAlarmDescrIndex' => '1.3.6.1.4.1.9.9.138.1.1.1.1.1',
  'ceAlarmDescrVendorType' => '1.3.6.1.4.1.9.9.138.1.1.1.1.2',
  'ceAlarmDescrTable' => '1.3.6.1.4.1.9.9.138.1.1.2',
  'ceAlarmDescrEntry' => '1.3.6.1.4.1.9.9.138.1.1.2.1',
  'ceAlarmDescrAlarmType' => '1.3.6.1.4.1.9.9.138.1.1.2.1.1',
  'ceAlarmDescrSeverity' => '1.3.6.1.4.1.9.9.138.1.1.2.1.2',
  'ceAlarmDescrSeverityDefinition' => 'CISCO-ENTITY-ALARM-MIB::AlarmSeverityOrZero',
  'ceAlarmDescrText' => '1.3.6.1.4.1.9.9.138.1.1.2.1.3',
  'ceAlarmMonitoring' => '1.3.6.1.4.1.9.9.138.1.2',
  'ceAlarmCriticalCount' => '1.3.6.1.4.1.9.9.138.1.2.1.0',
  'ceAlarmMajorCount' => '1.3.6.1.4.1.9.9.138.1.2.2.0',
  'ceAlarmMinorCount' => '1.3.6.1.4.1.9.9.138.1.2.3.0',
  'ceAlarmCutOff' => '1.3.6.1.4.1.9.9.138.1.2.4.0',
  'ceAlarmTable' => '1.3.6.1.4.1.9.9.138.1.2.5',
  'ceAlarmEntry' => '1.3.6.1.4.1.9.9.138.1.2.5.1',
  'ceAlarmFilterProfile' => '1.3.6.1.4.1.9.9.138.1.2.5.1.1',
  'ceAlarmSeverity' => '1.3.6.1.4.1.9.9.138.1.2.5.1.2',
  'ceAlarmSeverityDefinition' => 'CISCO-ENTITY-ALARM-MIB::AlarmSeverityOrZero',
  'ceAlarmList' => '1.3.6.1.4.1.9.9.138.1.2.5.1.3',
  'ceAlarmHistory' => '1.3.6.1.4.1.9.9.138.1.3',
  'ceAlarmHistTableSize' => '1.3.6.1.4.1.9.9.138.1.3.1.0',
  'ceAlarmHistLastIndex' => '1.3.6.1.4.1.9.9.138.1.3.2.0',
  'ceAlarmHistTable' => '1.3.6.1.4.1.9.9.138.1.3.3',
  'ceAlarmHistEntry' => '1.3.6.1.4.1.9.9.138.1.3.3.1',
  'ceAlarmHistIndex' => '1.3.6.1.4.1.9.9.138.1.3.3.1.1',
  'ceAlarmHistType' => '1.3.6.1.4.1.9.9.138.1.3.3.1.2',
  'ceAlarmHistTypeDefinition' => {
    '1' => 'asserted',
    '2' => 'cleared',
  },
  'ceAlarmHistEntPhysicalIndex' => '1.3.6.1.4.1.9.9.138.1.3.3.1.3',
  'ceAlarmHistAlarmType' => '1.3.6.1.4.1.9.9.138.1.3.3.1.4',
  'ceAlarmHistSeverity' => '1.3.6.1.4.1.9.9.138.1.3.3.1.5',
  'ceAlarmHistSeverityDefinition' => 'CISCO-ENTITY-ALARM-MIB::AlarmSeverityOrZero',
  'ceAlarmHistTimeStamp' => '1.3.6.1.4.1.9.9.138.1.3.3.1.6',
  'ceAlarmFiltering' => '1.3.6.1.4.1.9.9.138.1.4',
  'ceAlarmNotifiesEnable' => '1.3.6.1.4.1.9.9.138.1.4.1.0',
  'ceAlarmSyslogEnable' => '1.3.6.1.4.1.9.9.138.1.4.2.0',
  'ceAlarmFilterProfileIndexNext' => '1.3.6.1.4.1.9.9.138.1.4.3.0',
  'ceAlarmFilterProfileTable' => '1.3.6.1.4.1.9.9.138.1.4.4',
  'ceAlarmFilterProfileEntry' => '1.3.6.1.4.1.9.9.138.1.4.4.1',
  'ceAlarmFilterIndex' => '1.3.6.1.4.1.9.9.138.1.4.4.1.1',
  'ceAlarmFilterStatus' => '1.3.6.1.4.1.9.9.138.1.4.4.1.2',
  'ceAlarmFilterAlias' => '1.3.6.1.4.1.9.9.138.1.4.4.1.3',
  'ceAlarmFilterAlarmsEnabled' => '1.3.6.1.4.1.9.9.138.1.4.4.1.4',
  'ceAlarmFilterNotifiesEnabled' => '1.3.6.1.4.1.9.9.138.1.4.4.1.5',
  'ceAlarmFilterSyslogEnabled' => '1.3.6.1.4.1.9.9.138.1.4.4.1.6',
  'ciscoEntityAlarmMIBNotificationsPrefix' => '1.3.6.1.4.1.9.9.138.2',
  'ciscoEntityAlarmMIBNotifications' => '1.3.6.1.4.1.9.9.138.2.0',
  'ceAlarmAsserted' => '1.3.6.1.4.1.9.9.138.2.0.1',
  'ceAlarmCleared' => '1.3.6.1.4.1.9.9.138.2.0.2',
  'ciscoEntityAlarmMIBConformance' => '1.3.6.1.4.1.9.9.138.3',
  'ciscoEntityAlarmMIBCompliances' => '1.3.6.1.4.1.9.9.138.3.1',
  'ciscoEntityAlarmMIBGroups' => '1.3.6.1.4.1.9.9.138.3.2',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCO-ENTITY-ALARM-MIB'} = {
  'AlarmSeverity' => {
    '1' => 'critical',
    '2' => 'major',
    '3' => 'minor',
    '4' => 'info',
  },
  'AlarmSeverityOrZero' => {
    '0' => 'none',
    '1' => 'critical',
    '2' => 'major',
    '3' => 'minor',
    '4' => 'info',
  },
};

1;

__END__
