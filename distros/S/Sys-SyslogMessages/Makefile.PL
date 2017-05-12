use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sys::SyslogMessages',
    VERSION_FROM      => 'lib/Sys/SyslogMessages.pm', # finds $VERSION
    PREREQ_PM         => { 'DateTime' => '0'}, # e.g., Module::Name => 1.1
    PREREQ_FATAL      => '1',
    ($] >= 5.005 ?     ## I am not actually sure about this version
      (ABSTRACT_FROM  => 'lib/Sys/SyslogMessages.pm', # retrieve abstract from module
       AUTHOR         => 'Judith Lebzelter <judith@osdl.org>') : ()),
);
