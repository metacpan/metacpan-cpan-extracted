use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Nagios::Plugin::SNMP',
    VERSION_FROM      => 'lib/Nagios/Plugin/SNMP.pm',
    PREREQ_PM         => {
        'Exporter' => '0',
        'Net::SNMP' => '0',
        'Nagios::Plugin' => '0'
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Nagios/Plugin/SNMP.pm', # retrieve abstract from module
       AUTHOR         => 'Max Schubert <perldork@webwizarddesign.com>') : ()),
);
