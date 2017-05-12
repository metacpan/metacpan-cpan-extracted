use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME             => 'Sub::Apply',
    VERSION_FROM     => 'lib/Sub/Apply.pm',
    PREREQ_PM        => { 'parent' => 0 },
    ABSTRACT_FROM    => 'lib/Sub/Apply.pm',
    MIN_PERL_VERSION => 5.008008,
    AUTHOR           => 'Yoshihiro Sasaki <ysasaki at cpan.org>',
    LICENSE          => 'perl',
    META_MERGE       => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            bugtracker => 'https://github.com/ysasaki/p5-sub-apply/issues',
            repository => 'git://github.com/ysasaki/p5-sub-apply.git',
        },
    },
);
