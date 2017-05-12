use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'OSDial',
    VERSION_FROM      => 'lib/OSDial.pm', # finds $VERSION
    INSTALLDIRS       => 'vendor',
    PREREQ_PM         => {'DBI' => 0, 'DBD::mysql' => 0, 'Asterisk::AGI' => 0, 'Digest::MD5' => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/OSDial.pm', # retrieve abstract from module
       AUTHOR         => 'Lott Caskey <lottcaskey@gmail.com>') : ()),
);
