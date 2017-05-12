package Monitoring::GLPlugin::SNMP::MibsAndOids::CISCOL2L3INTERFACECONFIGMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'CISCO-L2L3-INTERFACE-CONFIG-MIB'} = {
  url => '',
  name => 'CISCO-L2L3-INTERFACE-CONFIG-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-L2L3-INTERFACE-CONFIG-MIB'} = {
  'cL2L3IfTable' => '1.3.6.1.4.1.9.9.151.1.1.1',
  'cL2L3IfEntry' => '1.3.6.1.4.1.9.9.151.1.1.1.1',
  'cL2L3IfModeAdmin' => '1.3.6.1.4.1.9.9.151.1.1.1.1.1',
  'cL2L3IfModeAdminDefinition' => 'CISCO-L2L3-INTERFACE-CONFIG-MIB::CL2L3InterfaceMode',
  'cL2L3IfModeOper' => '1.3.6.1.4.1.9.9.151.1.1.1.1.2',
  'cL2L3IfModeOperDefinition' => 'CISCO-L2L3-INTERFACE-CONFIG-MIB::CL2L3InterfaceMode',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCO-L2L3-INTERFACE-CONFIG-MIB'} = {
  'CL2L3InterfaceMode' => {
    '1' => 'routed',
    '2' => 'switchport',
  },
};

1;

__END__
