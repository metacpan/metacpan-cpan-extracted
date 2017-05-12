use 5.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::SMS::2Way',
    VERSION_FROM      => 'lib/Net/SMS/2Way.pm', # finds $VERSION
    PREREQ_PM         => { LWP::UserAgent => 2.031, HTTP::Request => 1.40},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/SMS/2Way.pm', # retrieve abstract from module
       AUTHOR         => 'Lee S. Engel <lee@kode.co.za>') : ()),
);
