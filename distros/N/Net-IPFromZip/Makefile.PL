use 5.018002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::IPFromZip',
    VERSION_FROM      => 'lib/Net/IPFromZip.pm', # finds $VERSION
    PREREQ_PM         => {"Text::CSV_XS" => 1.13}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/IPFromZip.pm', # retrieve abstract from module
       AUTHOR         => 'John Kennedy <jgk@cpan.org>') : ()),
);
