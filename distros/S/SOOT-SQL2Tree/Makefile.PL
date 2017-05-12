use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'SOOT::SQL2Tree',
    VERSION_FROM      => 'lib/SOOT/SQL2Tree.pm', # finds $VERSION
    PREREQ_PM         => {
      'SOOT' => '0.13',
      'DBI' => '0',
      'File::Temp' => '0',
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/SOOT/SQL2Tree.pm', # retrieve abstract from module
    AUTHOR            => 'Steffen Mueller <smueller@cpan.org>',
    #EXE_FILES         => [qw(bin/soot)],
);

