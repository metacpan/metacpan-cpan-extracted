package Monitoring::GLPlugin::SNMP::MibsAndOids::ENTITYSTATEMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'ENTITY-STATE-MIB'} = {
  url => '',
  name => 'ENTITY-STATE-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'ENTITY-STATE-MIB'} =
    '1.3.6.1.2.1.131';

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'ENTITY-STATE-MIB'} =
{
  entityStateMIB => '1.3.6.1.2.1.131',
  entStateNotifications => '1.3.6.1.2.1.131.0',
  entStateObjects => '1.3.6.1.2.1.131.1',
  entStateTable => '1.3.6.1.2.1.131.1.1',
  entStateEntry => '1.3.6.1.2.1.131.1.1.1',
  entStateLastChanged => '1.3.6.1.2.1.131.1.1.1.1',
  entStateAdmin => '1.3.6.1.2.1.131.1.1.1.2',
  entStateAdminDefinition => 'ENTITY-STATE-TC-MIB::EntityAdminState',
  entStateOper => '1.3.6.1.2.1.131.1.1.1.3',
  entStateOperDefinition => 'ENTITY-STATE-TC-MIB::EntityOperState',
  entStateUsage => '1.3.6.1.2.1.131.1.1.1.4',
  entStateUsageDefinition => 'ENTITY-STATE-TC-MIB::EntityUsageState',
  entStateAlarm => '1.3.6.1.2.1.131.1.1.1.5',
  entStateAlarmDefinition => 'ENTITY-STATE-TC-MIB::EntityAlarmStatus',
  entStateStandby => '1.3.6.1.2.1.131.1.1.1.6',
  entStateStandbyDefinition => 'ENTITY-STATE-TC-MIB::EntityStandbyStatus',
  entStateConformance => '1.3.6.1.2.1.131.2',
  entStateCompliances => '1.3.6.1.2.1.131.2.1',
  entStateGroups => '1.3.6.1.2.1.131.2.2',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'ENTITY-STATE-TC-MIB'} = {
  EntityAdminState => {
    1 => 'unknown',
    2 => 'locked',
    3 => 'shuttingDown',
    4 => 'unlocked',
  },
  EntityOperState => {
    1 => 'unknown',
    2 => 'disabled',
    3 => 'enabled',
    4 => 'testing',
  },
  EntityUsageState => {
    1 => 'unknown',
    2 => 'idle',
    3 => 'active',
    4 => 'busy',
  },
  EntityAlarmStatus => sub {
    my $val = shift;
    # einstweilen wurscht, muss noch genauer angeschaut werden
    my $dec = unpack("B*", $val);
    return {
    0 => 'unknown',
    1 => 'underRepair',
    2 => 'critical',
    3 => 'major',
    4 => 'minor',
    5 => 'warning',
    6 => 'indeterminate',
    }->{$dec};
  },
  EntityStandbyStatus => {
    1 => 'unknown',
    2 => 'hotStandby',
    3 => 'coldStandby',
    4 => 'providingService',
  },
};

