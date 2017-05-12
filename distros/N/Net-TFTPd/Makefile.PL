use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::TFTPd',
    VERSION_FROM      => 'lib/Net/TFTPd.pm', # finds $VERSION
    ($ExtUtils::MakeMaker::VERSION >= 6.3002) ? ('LICENSE'  => 'perl', ) : (),
    EXE_FILES         => ['bin/tftpd-simple.pl',
                          'bin/simpleTFTPd.pl'],
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/TFTPd.pm', # retrieve abstract from module
       AUTHOR         => 'Luigino Masarati <lmasarati@hotmail.com>') : ()),
);
