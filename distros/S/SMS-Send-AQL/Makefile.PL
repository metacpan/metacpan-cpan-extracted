use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SMS::Send::AQL',
    VERSION_FROM      => 'lib/SMS/Send/AQL.pm',
    PREREQ_PM         => { SMS::AQL => 0, SMS::Send::Driver => 0 },
    NO_META           => 1,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SMS/Send/AQL.pm',
       AUTHOR         => 'David Precious <davidp@preshweb.co.uk>') : ()),
);

# $Id: Makefile.PL 280 2008-03-09 01:53:31Z davidp $
