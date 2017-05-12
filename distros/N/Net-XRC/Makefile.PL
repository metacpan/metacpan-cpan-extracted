use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::XRC',
    VERSION_FROM      => 'lib/Net/XRC.pm', # finds $VERSION
    PREREQ_PM         => { # e.g., Module::Name => 1.1
                           'LWP'           => 0,
                           'Crypt::SSLeay' => 0,
                           'Data::Dumper'  => 0,
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/XRC.pm', # retrieve abstract from module
       AUTHOR         => 'Ivan Kohler <ivan-xrc@420.am>') : ()),
);
