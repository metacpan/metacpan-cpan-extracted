package Monitoring::GLPlugin::SNMP::MibsAndOids::CISCOSBHWENVIROMENT;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'CISCOSB-HWENVIROMENT'} = {
  url => '',
  name => 'CISCOSB-HWENVIROMENT',
};

#$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'CISCOSB-HWENVIROMENT'} = 

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCOSB-HWENVIROMENT'} = {
  rlEnv => '1.3.6.1.4.1.9.6.1.101.83',
  rlEnvPhysicalDescription => '1.3.6.1.4.1.9.6.1.101.83.1',
  rlEnvMonFanStatusTable => '1.3.6.1.4.1.9.6.1.101.83.1.1',
  rlEnvMonFanStatusEntry => '1.3.6.1.4.1.9.6.1.101.83.1.1.1',
  rlEnvMonFanStatusIndex => '1.3.6.1.4.1.9.6.1.101.83.1.1.1.1',
  rlEnvMonFanStatusDescr => '1.3.6.1.4.1.9.6.1.101.83.1.1.1.2',
  rlEnvMonFanState => '1.3.6.1.4.1.9.6.1.101.83.1.1.1.3',
  rlEnvMonFanStateDefinition => 'CISCOSB-HWENVIROMENT::RlEnvMonState',
  rlEnvMonSupplyStatusTable => '1.3.6.1.4.1.9.6.1.101.83.1.2',
  rlEnvMonSupplyStatusEntry => '1.3.6.1.4.1.9.6.1.101.83.1.2.1',
  rlEnvMonSupplyStatusIndex => '1.3.6.1.4.1.9.6.1.101.83.1.2.1.1',
  rlEnvMonSupplyStatusDescr => '1.3.6.1.4.1.9.6.1.101.83.1.2.1.2',
  rlEnvMonSupplyState => '1.3.6.1.4.1.9.6.1.101.83.1.2.1.3',
  rlEnvMonSupplyStateDefinition => 'CISCOSB-HWENVIROMENT::RlEnvMonState',
  rlEnvMonSupplySource => '1.3.6.1.4.1.9.6.1.101.83.1.2.1.4',
  rlEnvMonSupplySourceDefinition => 'CISCOSB-HWENVIROMENT::rlEnvMonSupplySource',
  rlEnvMonSupplyFanDirection => '1.3.6.1.4.1.9.6.1.101.83.1.2.1.5',
  rlEnvMonSupplyFanDirectionDefinition => 'CISCOSB-HWENVIROMENT::RlEnvMonDirection',
  rlEnvFanData => '1.3.6.1.4.1.9.6.1.101.83.5',
  rlEnvFanDataTable => '1.3.6.1.4.1.9.6.1.101.83.5.1',
  rlEnvFanDataEntry => '1.3.6.1.4.1.9.6.1.101.83.5.1.1',
  rlEnvFanDataStackUnit => '1.3.6.1.4.1.9.6.1.101.83.5.1.1.1',
  rlEnvFanDataTemp => '1.3.6.1.4.1.9.6.1.101.83.5.1.1.2',
  rlEnvFanDataSpeed => '1.3.6.1.4.1.9.6.1.101.83.5.1.1.3',
  rlEnvFanDataOperLevel => '1.3.6.1.4.1.9.6.1.101.83.5.1.1.4',
  rlEnvFanDataAdminLevel => '1.3.6.1.4.1.9.6.1.101.83.5.1.1.5',
  rlEnvFanDataDirection => '1.3.6.1.4.1.9.6.1.101.83.5.1.1.6',
  rlEnvFanDataDirectionDefinition => 'CISCOSB-HWENVIROMENT::RlEnvMonDirection',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCOSB-HWENVIROMENT'} = {
  rlEnvMonSupplySource => {
    '1' => 'unknown',
    '2' => 'ac',
    '3' => 'dc',
    '4' => 'externalPowerSupply',
    '5' => 'internalRedundant',
  },
  RlEnvMonDirection => {
    '1' => 'unKnown',
    '2' => 'frontToBack',
    '3' => 'backToFront',
    '4' => 'clockwise',
    '5' => 'unClockwise',
    '6' => 'insideOut',
    '7' => 'outsideIn',
    '8' => 'rightToLeft',
    '9' => 'leftToRight',
  },
  RlEnvMonState => {
    '1' => 'normal',
    '2' => 'warning',
    '3' => 'critical',
    '4' => 'shutdown',
    '5' => 'notPresent',
    '6' => 'notFunctioning',
  },
};
