use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Artera',
    VERSION_FROM      => 'lib/Net/Artera.pm', # finds $VERSION
    PREREQ_PM         => {
                           'LWP::UserAgent'  => 0,
                           'Crypt::SSLeay'   => 0,
                           'XML::Simple'     => 0,
                           'Data::Dumper'    => 0,
                           'Locale::Country' => 0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Artera.pm', # retrieve abstract from module
       AUTHOR         => 'Ivan Kohler <ivan-net-artera@420.am>') : ()),
);
