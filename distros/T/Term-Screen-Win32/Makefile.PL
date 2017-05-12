use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $PreReq = {'Win32::Console::ANSI' => 1.00,
              'Carp'                 => 0,
              'Win32::Console'       => 0.191,
              'Tie::Hash'            => 0,
             };

WriteMakefile(
    NAME              => 'Term::Screen::Win32',
    VERSION_FROM      => 'lib/Term/Screen/Win32.pm', # finds $VERSION
    PREREQ_PM         => $PreReq, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Term/Screen/Win32.pm', # retrieve abstract from module
       AUTHOR         => 'Daniel Podolsky <tpaba@cpan.org>') : ()),
);
