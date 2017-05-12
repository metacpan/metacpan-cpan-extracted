use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Appliance::Logical',
    VERSION_FROM      => 'lib/Net/Appliance/Logical.pm', # finds $VERSION
    PREREQ_PM         => {  'Class::Data::Inheritable' => 0,
                            'Net::SNMP'                => 0,
                            'LWP::UserAgent'           => 0,
                            'Class::Date'              => 0,
                            'Regexp::Common'           => 0
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Appliance/Logical.pm', # retrieve abstract from module
       AUTHOR         => 'Christopher Heschong <chris@wiw.org>') : ()),
);
