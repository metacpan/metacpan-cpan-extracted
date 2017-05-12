package Monitoring::GLPlugin::SNMP::MibsAndOids::SERVERVIEWSTATUSMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'SERVERVIEW-STATUS-MIB'} = {
  url => '',
  name => 'SERVERVIEW-STATUS-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'SERVERVIEW-STATUS-MIB'} = 
  '1.3.6.1.4.1.231.2.10.2.11';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'SERVERVIEW-STATUS-MIB'} = {
  'sieStAgentInfo' => '1.3.6.1.4.1.231.2.10.2.11.1',
  'sieStAgentId' => '1.3.6.1.4.1.231.2.10.2.11.1.1',
  'sieStSystemStatus' => '1.3.6.1.4.1.231.2.10.2.11.2',
  'sieStSystemStatusValue' => '1.3.6.1.4.1.231.2.10.2.11.2.1',
  'sieStSystemStatusValueDefinition' => {
    '1' => 'ok',
    '2' => 'warning',
    '3' => 'error',
    '5' => 'unknown',
  },
  'sieStSystemLastErrorMessage' => '1.3.6.1.4.1.231.2.10.2.11.2.2',
  'sieStSubsystemList' => '1.3.6.1.4.1.231.2.10.2.11.2.3',
  'sieStSystemIdentify' => '1.3.6.1.4.1.231.2.10.2.11.2.4',
  'sieStSubsystemStatus' => '1.3.6.1.4.1.231.2.10.2.11.3',
  'sieStSubsystemTable' => '1.3.6.1.4.1.231.2.10.2.11.3.1',
  'sieStSubsystemEntry' => '1.3.6.1.4.1.231.2.10.2.11.3.1.1',
  'sieStSubsystems' => '1.3.6.1.4.1.231.2.10.2.11.3.1.1',
  'sieStSubsystemNumber' => '1.3.6.1.4.1.231.2.10.2.11.3.1.1.1',
  'sieStSubsystemName' => '1.3.6.1.4.1.231.2.10.2.11.3.1.1.2',
  'sieStSubsystemStatusValue' => '1.3.6.1.4.1.231.2.10.2.11.3.1.1.3',
  'sieStSubsystemStatusValueDefinition' => {
    '1' => 'ok',
    '2' => 'warning',
    '3' => 'error',
    '5' => 'unknown',
  },
  'sieStSubsystemLastErrorMessage' => '1.3.6.1.4.1.231.2.10.2.11.3.1.1.4',
  'sieStSubsystemComponents' => '1.3.6.1.4.1.231.2.10.2.11.3.1.1.5',
  'sieStSubsystemDisplayName' => '1.3.6.1.4.1.231.2.10.2.11.3.1.1.6',
  'sieStNumberSubsystems' => '1.3.6.1.4.1.231.2.10.2.11.3.2',
  'sieStComponentStatus' => '1.3.6.1.4.1.231.2.10.2.11.4',
  'sieStComponentTable' => '1.3.6.1.4.1.231.2.10.2.11.4.1',
  'sieStComponentEntry' => '1.3.6.1.4.1.231.2.10.2.11.4.1.1',
  'sieStComponents' => '1.3.6.1.4.1.231.2.10.2.11.4.1.1',
  'sieStComponentNumber' => '1.3.6.1.4.1.231.2.10.2.11.4.1.1.1',
  'sieStComponentName' => '1.3.6.1.4.1.231.2.10.2.11.4.1.1.2',
  'sieStComponentStatusValue' => '1.3.6.1.4.1.231.2.10.2.11.4.1.1.3',
  'sieStComponentStatusValueDefinition' => {
    '1' => 'ok',
    '2' => 'warning',
    '3' => 'error',
    '5' => 'unknown',
    '6' => 'unknown',
  },
  'sieStComponentLastErrorMessage' => '1.3.6.1.4.1.231.2.10.2.11.4.1.1.4',
  'sieStComponentDisplayName' => '1.3.6.1.4.1.231.2.10.2.11.4.1.1.5',
  'sieStComponentConfirmFailure' => '1.3.6.1.4.1.231.2.10.2.11.4.1.1.6',
  'sieStNumberComponents' => '1.3.6.1.4.1.231.2.10.2.11.4.2',
  'sieStAgentParameters' => '1.3.6.1.4.1.231.2.10.2.11.5',
  'sieStAgentType' => '1.3.6.1.4.1.231.2.10.2.11.5.1',
  'sieStTrapParameters' => '1.3.6.1.4.1.231.2.10.2.11.10',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'SERVERVIEW-STATUS-MIB'} = {
};

1;

__END__
