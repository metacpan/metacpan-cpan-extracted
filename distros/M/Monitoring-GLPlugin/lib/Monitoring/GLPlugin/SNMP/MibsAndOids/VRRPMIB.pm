package Monitoring::GLPlugin::SNMP::MibsAndOids::VRRPMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'VRRP-MIB'} = {
  url => 'ftp://ftp.cisco.com/pub/mibs/v2/VRRP-MIB.my',
  name => 'VRRP-MIB'
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::requirements->{'VRRP-MIB'} = [
  'SNMPv2-TC-v1-MIB',
];

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'VRRP-MIB'} = {
  vrrpMIB => '.1.3.6.1.2.1.68',
  vrrpNotifications => '.1.3.6.1.2.1.68.0',
  vrrpTrapNewMaster => '.1.3.6.1.2.1.68.0.1',
  vrrpTrapAuthFailure => '.1.3.6.1.2.1.68.0.2',
  vrrpOperations => '.1.3.6.1.2.1.68.1',
  vrrpNodeVersion => '.1.3.6.1.2.1.68.1.1',
  vrrpNotificationCntl => '.1.3.6.1.2.1.68.1.2',
  vrrpOperTable => '.1.3.6.1.2.1.68.1.3',
  vrrpOperEntry => '.1.3.6.1.2.1.68.1.3.1',
  vrrpOperVrId => '.1.3.6.1.2.1.68.1.3.1.1',
  vrrpOperAuthKey => '.1.3.6.1.2.1.68.1.3.1.10',
  vrrpOperAdvertisementInterval => '.1.3.6.1.2.1.68.1.3.1.11',
  vrrpOperPreemptMode => '.1.3.6.1.2.1.68.1.3.1.12',
  vrrpOperVirtualRouterUpTime => '.1.3.6.1.2.1.68.1.3.1.13',
  vrrpOperProtocol => '.1.3.6.1.2.1.68.1.3.1.14',
  vrrpOperProtocolDefinition => 'VRRP-MIB::vrrpOperProtocol',
  vrrpOperRowStatus => '.1.3.6.1.2.1.68.1.3.1.15',
  vrrpOperRowStatusDefinition => 'SNMPv2-TC-v1-MIB::RowStatus',
  vrrpOperVirtualMacAddr => '.1.3.6.1.2.1.68.1.3.1.2',
  vrrpOperState => '.1.3.6.1.2.1.68.1.3.1.3',
  vrrpOperStateDefinition => 'VRRP-MIB::vrrpOperState',
  vrrpOperAdminState => '.1.3.6.1.2.1.68.1.3.1.4',
  vrrpOperAdminStateDefinition => 'VRRP-MIB::vrrpOperAdminState',
  vrrpOperPriority => '.1.3.6.1.2.1.68.1.3.1.5',
  vrrpOperIpAddrCount => '.1.3.6.1.2.1.68.1.3.1.6',
  vrrpOperMasterIpAddr => '.1.3.6.1.2.1.68.1.3.1.7',
  vrrpOperPrimaryIpAddr => '.1.3.6.1.2.1.68.1.3.1.8',
  vrrpOperAuthType => '.1.3.6.1.2.1.68.1.3.1.9',
  vrrpOperAuthTypeDefinition => 'VRRP-MIB::vrrpOperAuthType',
  vrrpAssoIpAddrTable => '.1.3.6.1.2.1.68.1.4',
  vrrpAssoIpAddrEntry => '.1.3.6.1.2.1.68.1.4.1',
  vrrpAssoIpAddr => '.1.3.6.1.2.1.68.1.4.1.1',
  vrrpAssoIpAddrRowStatus => '.1.3.6.1.2.1.68.1.4.1.2',
  vrrpAssoIpAddrRowStatusDefinition => 'SNMPv2-TC-v1-MIB::RowStatus',
  vrrpTrapPacketSrc => '.1.3.6.1.2.1.68.1.5',
  vrrpTrapAuthErrorType => '.1.3.6.1.2.1.68.1.6',
  vrrpTrapAuthErrorTypeDefinition => 'VRRP-MIB::vrrpTrapAuthErrorType',
  vrrpStatistics => '.1.3.6.1.2.1.68.2',
  vrrpRouterChecksumErrors => '.1.3.6.1.2.1.68.2.1',
  vrrpRouterVersionErrors => '.1.3.6.1.2.1.68.2.2',
  vrrpRouterVrIdErrors => '.1.3.6.1.2.1.68.2.3',
  vrrpRouterStatsTable => '.1.3.6.1.2.1.68.2.4',
  vrrpRouterStatsEntry => '.1.3.6.1.2.1.68.2.4.1',
  vrrpStatsBecomeMaster => '.1.3.6.1.2.1.68.2.4.1.1',
  vrrpStatsInvalidAuthType => '.1.3.6.1.2.1.68.2.4.1.10',
  vrrpStatsAuthTypeMismatch => '.1.3.6.1.2.1.68.2.4.1.11',
  vrrpStatsPacketLengthErrors => '.1.3.6.1.2.1.68.2.4.1.12',
  vrrpStatsAdvertiseRcvd => '.1.3.6.1.2.1.68.2.4.1.2',
  vrrpStatsAdvertiseIntervalErrors => '.1.3.6.1.2.1.68.2.4.1.3',
  vrrpStatsAuthFailures => '.1.3.6.1.2.1.68.2.4.1.4',
  vrrpStatsIpTtlErrors => '.1.3.6.1.2.1.68.2.4.1.5',
  vrrpStatsPriorityZeroPktsRcvd => '.1.3.6.1.2.1.68.2.4.1.6',
  vrrpStatsPriorityZeroPktsSent => '.1.3.6.1.2.1.68.2.4.1.7',
  vrrpStatsInvalidTypePktsRcvd => '.1.3.6.1.2.1.68.2.4.1.8',
  vrrpStatsAddressListErrors => '.1.3.6.1.2.1.68.2.4.1.9',
  vrrpConformance => '.1.3.6.1.2.1.68.3',
  vrrpMIBCompliances => '.1.3.6.1.2.1.68.3.1',
  vrrpMIBCompliance => '.1.3.6.1.2.1.68.3.1.1',
  vrrpMIBGroups => '.1.3.6.1.2.1.68.3.2',
  vrrpOperGroup => '.1.3.6.1.2.1.68.3.2.1',
  vrrpStatsGroup => '.1.3.6.1.2.1.68.3.2.2',
  vrrpTrapGroup => '.1.3.6.1.2.1.68.3.2.3',
  vrrpNotificationGroup => '.1.3.6.1.2.1.68.3.2.4'
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'VRRP-MIB'} = {
  vrrpOperAdminState => {
    '1' => 'up',
    '2' => 'down'
  },
  vrrpOperAuthType => {
    '1' => 'noAuthentication',
    '2' => 'simpleTextPassword',
    '3' => 'ipAuthenticationHeader'
  },
  vrrpOperProtocol => {
    '1' => 'ip',
    '2' => 'bridge',
    '3' => 'decnet',
    '4' => 'other'
  },
  vrrpOperState => {
    '1' => 'initialize',
    '2' => 'backup',
    '3' => 'master'
  },
  vrrpTrapAuthErrorType => {
    '1' => 'invalidAuthType',
    '2' => 'authTypeMismatch',
    '3' => 'authFailure'
  }
};

1;
