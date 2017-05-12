package Monitoring::GLPlugin::SNMP::MibsAndOids::CISCOETHERNETFABRICEXTENDERMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'CISCO-ETHERNET-FABRIC-EXTENDER-MIB'} = {
  url => '',
  name => 'CISCO-ETHERNET-FABRIC-EXTENDER-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::requirements->{'CISCO-ETHERNET-FABRIC-EXTENDER-MIB'} = [
  'SNMPv2-TC-v1-MIB',
];

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-ETHERNET-FABRIC-EXTENDER-MIB'} = {
  'enterprises' => '1.3.6.1.4.1',
  'cisco' => '1.3.6.1.4.1.9',
  'ciscoEthernetFabricExtenderMIB' => '1.3.6.1.4.1.9.9.691',
  'ciscoEthernetFabricExtenderMIBNotifs' => '1.3.6.1.4.1.9.9.691.0',
  'ciscoEthernetFabricExtenderObjects' => '1.3.6.1.4.1.9.9.691.1',
  'cefexConfig' => '1.3.6.1.4.1.9.9.691.1.1',
  'cefexConfigDefinition' => {
    '1' => 'static',
  },
  'cefexBindingTable' => '1.3.6.1.4.1.9.9.691.1.1.1',
  'cefexBindingEntry' => '1.3.6.1.4.1.9.9.691.1.1.1.1',
  'cefexBindingInterfaceOnCoreSwitch' => '1.3.6.1.4.1.9.9.691.1.1.1.1.1',
  'cefexBindingExtenderIndex' => '1.3.6.1.4.1.9.9.691.1.1.1.1.2',
  'cefexBindingCreationTime' => '1.3.6.1.4.1.9.9.691.1.1.1.1.3',
  'cefexBindingRowStatus' => '1.3.6.1.4.1.9.9.691.1.1.1.1.4',
  'cefexBindingRowStatusDefinition' => 'SNMPv2-TC-v1-MIB::RowStatus',
  'cefexConfigTable' => '1.3.6.1.4.1.9.9.691.1.1.2',
  'cefexConfigEntry' => '1.3.6.1.4.1.9.9.691.1.1.2.1',
  'cefexConfigExtenderName' => '1.3.6.1.4.1.9.9.691.1.1.2.1.1',
  'cefexConfigSerialNumCheck' => '1.3.6.1.4.1.9.9.691.1.1.2.1.2',
  'cefexConfigSerialNum' => '1.3.6.1.4.1.9.9.691.1.1.2.1.3',
  'cefexConfigPinningFailOverMode' => '1.3.6.1.4.1.9.9.691.1.1.2.1.4',
  'cefexConfigPinningFailOverModeDefinition' => 'CISCO-ETHERNET-FABRIC-EXTENDER-MIB::CiscoPortPinningMode',
  'cefexConfigPinningMaxLinks' => '1.3.6.1.4.1.9.9.691.1.1.2.1.5',
  'cefexConfigCreationTime' => '1.3.6.1.4.1.9.9.691.1.1.2.1.6',
  'cefexConfigRowStatus' => '1.3.6.1.4.1.9.9.691.1.1.2.1.7',
  'cefexConfigRowStatusDefinition' => 'SNMPv2-TC-v1-MIB::RowStatus',
  'ciscoEthernetFabricExtenderMIBConformance' => '1.3.6.1.4.1.9.9.691.2',
  'cEthernetFabricExtenderMIBCompliances' => '1.3.6.1.4.1.9.9.691.2.1',
  'cEthernetFabricExtenderMIBGroups' => '1.3.6.1.4.1.9.9.691.2.1.1.1',
  'hardware' => '1.3.6.1.4.1.3764.1.1.200',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCO-ETHERNET-FABRIC-EXTENDER-MIB'} = {
  'CiscoPortPinningMode' => {
    '1' => 'static',
  },
};

1;

__END__
