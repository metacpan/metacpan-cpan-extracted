package Monitoring::GLPlugin::SNMP::MibsAndOids::CISCOHSRPMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'CISCO-HSRP-MIB'} = {
  url => '',
  name => 'CISCO-HSRP-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::requirements->{'CISCO-HSRP-MIB'} = [
  'SNMPv2-TC-v1-MIB',
];

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-HSRP-MIB'} = {
  'cHsrpGrpTable' => '1.3.6.1.4.1.9.9.106.1.2.1',
  'cHsrpGrpEntry' => '1.3.6.1.4.1.9.9.106.1.2.1.1',
  'cHsrpGrpNumber' => '1.3.6.1.4.1.9.9.106.1.2.1.1.1',
  'cHsrpGrpAuth' => '1.3.6.1.4.1.9.9.106.1.2.1.1.2',
  'cHsrpGrpPriority' => '1.3.6.1.4.1.9.9.106.1.2.1.1.3',
  'cHsrpGrpPreempt' => '1.3.6.1.4.1.9.9.106.1.2.1.1.4',
  'cHsrpGrpPreemptDelay' => '1.3.6.1.4.1.9.9.106.1.2.1.1.5',
  'cHsrpGrpUseConfiguredTimers' => '1.3.6.1.4.1.9.9.106.1.2.1.1.6',
  'cHsrpGrpConfiguredHelloTime' => '1.3.6.1.4.1.9.9.106.1.2.1.1.7',
  'cHsrpGrpConfiguredHoldTime' => '1.3.6.1.4.1.9.9.106.1.2.1.1.8',
  'cHsrpGrpLearnedHelloTime' => '1.3.6.1.4.1.9.9.106.1.2.1.1.9',
  'cHsrpGrpLearnedHoldTime' => '1.3.6.1.4.1.9.9.106.1.2.1.1.10',
  'cHsrpGrpVirtualIpAddr' => '1.3.6.1.4.1.9.9.106.1.2.1.1.11',
  'cHsrpGrpUseConfigVirtualIpAddr' => '1.3.6.1.4.1.9.9.106.1.2.1.1.12',
  'cHsrpGrpActiveRouter' => '1.3.6.1.4.1.9.9.106.1.2.1.1.13',
  'cHsrpGrpStandbyRouter' => '1.3.6.1.4.1.9.9.106.1.2.1.1.14',
  'cHsrpGrpStandbyState' => '1.3.6.1.4.1.9.9.106.1.2.1.1.15',
  'cHsrpGrpStandbyStateDefinition' => 'CISCO-HSRP-MIB::HsrpState',
  'cHsrpGrpVirtualMacAddr' => '1.3.6.1.4.1.9.9.106.1.2.1.1.16',
  'cHsrpGrpEntryRowStatus' => '1.3.6.1.4.1.9.9.106.1.2.1.1.17',
  'cHsrpGrpEntryRowStatusDefinition' => 'SNMPv2-TC-v1-MIB::RowStatus',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCO-HSRP-MIB'} = {
  'HsrpState' => {
    '1' => 'initial',
    '2' => 'learn',
    '3' => 'listen',
    '4' => 'speak',
    '5' => 'standby',
    '6' => 'active',
  },
};

1;

__END__
