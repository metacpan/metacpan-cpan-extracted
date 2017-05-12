use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'SOOT::App',
    VERSION_FROM      => 'lib/SOOT/App.pm', # finds $VERSION
    PREREQ_PM         => {
      'SOOT'             => '0.16',
      'Devel::REPL'      => '1.003000',
      'Capture::Tiny'    => '0',
      'Term::ANSIColor'  => '0',
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/SOOT/App.pm', # retrieve abstract from module
    AUTHOR            => 'Steffen Mueller <smueller@cpan.org>',
    EXE_FILES         => [qw(bin/soot)],
);

