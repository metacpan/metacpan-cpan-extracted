package Monitoring::GLPlugin::SNMP::MibsAndOids::CISCOFEATURECONTROLMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'CISCO-FEATURE-CONTROL-MIB'} = {
  url => '',
  name => 'CISCO-FEATURE-CONTROL-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-FEATURE-CONTROL-MIB'} = {
  'cfcFeatureCtrlOpStatus' => 'CISCO-FEATURE-CONTROL-MIB::CiscoFeatureStatus',
  'cfcFeatureCtrlLastActionResult' => 'CISCO-FEATURE-CONTROL-MIB::CiscoFeatureActionResult',
  'cfcFeatureCtrlAction' => 'CISCO-FEATURE-CONTROL-MIB::CiscoFeatureAction',
  'cfcFeatureCtrlIndex' => 'CISCO-FEATURE-CONTROL-MIB::CiscoOptionalFeature',
  'cfcFeatureCtrlLastAction' => 'CISCO-FEATURE-CONTROL-MIB::CiscoFeatureAction',
  'cfcFeatureCtrlTable' => '1.3.6.1.4.1.9.9.377.1.1.1',
  'cfcFeatureCtrlEntry' => '1.3.6.1.4.1.9.9.377.1.1.1.1',
  'cfcFeatureCtrlName' => '1.3.6.1.4.1.9.9.377.1.1.1.1.2',
  'cfcFeatureCtrlLastFailureReason' => '1.3.6.1.4.1.9.9.377.1.1.1.1.6',
  'cfcFeatureCtrlOpStatusReason' => '1.3.6.1.4.1.9.9.377.1.1.1.1.8',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCO-FEATURE-CONTROL-MIB'} = {
  'CiscoOptionalFeature' => {
    '1' => 'ivr',
    '2' => 'fcip',
    '3' => 'fcsp',
    '4' => 'ficon',
    '5' => 'iscsi',
    '6' => 'tacacs',
    '7' => 'qosManager',
    '8' => 'portSecurity',
    '9' => 'fabricBinding',
    '10' => 'iscsiInterfaceVsanMembership',
    '11' => 'ike',
    '12' => 'isns',
    '13' => 'ipSec',
    '14' => 'portTracker',
    '15' => 'scheduler',
    '16' => 'npiv',
    '17' => 'sanExtTuner',
    '18' => 'dpvm',
    '19' => 'extenedCredit',
  },
  'CiscoFeatureStatus' => {
    '1' => 'unknown',
    '2' => 'enabled',
    '3' => 'disabled',
  },
  'CiscoFeatureActionResult' => {
    '1' => 'none',
    '2' => 'actionSuccess',
    '3' => 'actionFailed',
    '4' => 'actionInProgress',
  },
  'CiscoFeatureAction' => {
    '1' => 'noOp',
    '2' => 'enable',
    '3' => 'disable',
  },
};

1;

__END__
