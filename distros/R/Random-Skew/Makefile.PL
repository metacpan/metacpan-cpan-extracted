use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Random::Skew',
    VERSION_FROM      => 'lib/Random/Skew.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Random/Skew.pm', # retrieve abstract from module
    AUTHOR            => 'Will Trillich <will@serensoft.com>',
    LICENSE           => 'perl',
    test              => { TESTS => 't/*.t' },
    (MM->can('signature_target') ? ( SIGN => 1 ) : ()),
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    MIN_PERL_VERSION  => 5.010,
);
