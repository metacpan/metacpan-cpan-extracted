use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::Debian',
    VERSION_FROM      => 'lib/Test/Debian.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/Debian.pm', # retrieve abstract from module
       AUTHOR         => 'Dmitry E. Oboukhov <unera@debian.org>') : ()),
    LICENSE           => 'perl',
    META_MERGE => {
        resources => {
            homepage    => 'https://github.com/dr-co/test-debian-perl',
            repository  => 'https://github.com/dr-co/test-debian-perl',
            bugtracker  => 'https://github.com/dr-co/test-debian-perl/issues'
        }
    }
);
