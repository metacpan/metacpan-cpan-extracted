use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Syslogd',
    VERSION_FROM      => 'lib/Net/Syslogd.pm', # finds $VERSION
    ($ExtUtils::MakeMaker::VERSION >= 6.3002) ? ('LICENSE'  => 'perl', ) : (),
    EXE_FILES         => ['bin/syslogd-simple.pl',
                          'bin/syslogd-sendtest.pl'],
    PREREQ_PM         => {Test::Simple => 0,
                          Socket => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Syslogd.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Vincent <vin at vinsworld dot com>') : ()),
);
