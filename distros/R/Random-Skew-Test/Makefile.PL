#use 5.028001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Random::Skew::Test',
    VERSION_FROM      => 'lib/Random/Skew/Test.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
                    'Random::Skew' => 0.01,
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Random/Skew/Test.pm', # retrieve abstract from module
    AUTHOR            => 'Will Trillich <will@serensoft.com>',
    test              => { TESTS => 't/*.t' },
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
