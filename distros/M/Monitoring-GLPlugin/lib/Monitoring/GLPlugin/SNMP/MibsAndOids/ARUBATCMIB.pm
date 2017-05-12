package Monitoring::GLPlugin::SNMP::MibsAndOids::ARUBATCMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'ARUBA-TC-MIB'} = {
  url => 'http://www.circitor.fr/Mibs/Files/ARUBA-TC.mib',
  name => 'ARUBA-TC-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'ARUBA-TC-MIB'} = {
  'ArubaSwitchRole' => {
    1 => 'master',
    2 => 'local',
    3 => 'backupmaster',
  },
  'ArubaActiveState' => {
    1 => 'active',
    2 => 'inactive',
  },
};

1;

__END__

