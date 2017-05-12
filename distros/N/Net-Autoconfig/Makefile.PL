use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Autoconfig',
    VERSION_FROM      => 'lib/Net/Autoconfig.pm', # finds $VERSION
    PREREQ_PM         => {
                            'Cwd'                   =>  3.12,
                            'Data::Dumper'          =>  2.121,
                            'Expect'                =>  1.21,
                            'Log::Log4perl'         =>  1.15,
                            'Log::Dispatch::Screen' =>  1.17,
                            'version'               =>  0.74,
                            'Net::Ping'             =>  2.31,
                            'Net::SNMP'             =>  5.002_00,
                        },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Autoconfig.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin Ehlers <kevin@uoregon.edu>') : ()),
);
