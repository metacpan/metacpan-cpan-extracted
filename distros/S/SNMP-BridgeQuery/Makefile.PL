use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'SNMP::BridgeQuery',
    'VERSION_FROM' => 'BridgeQuery.pm', # finds $VERSION
    'PREREQ_PM'    => {
       'Net::SNMP'	=> '0',
    }
);
