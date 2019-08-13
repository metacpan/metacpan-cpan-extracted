use utf8;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Perl::Critic::PolicyBundle::SNEZ',
    VERSION_FROM     => 'lib/Perl/Critic/PolicyBundle/SNEZ.pm',
    ABSTRACT_FROM    => 'lib/Perl/Critic/PolicyBundle/SNEZ.pm',
    AUTHOR           => 'Szymon Nieznański',
    MIN_PERL_VERSION => '5.10.1',
    LICENSE          => 'perl_5',
    PREREQ_PM        => {
        'strict'          => 0,
        'warnings'        => 0,
        'parent'          => 0,
        'Perl::Critic'    => 0,
        'List::MoreUtils' => 0,
        'Data::Alias'     => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Path::Tiny' => 0,
    },
    test => { TESTS => 't/*.t' },
    eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (
        META_MERGE => {
            'meta-spec' => { version => 2 },
            resources   => {
                repository => {
                    type => 'git',
                    url  => 'https://github.com/s-nez/perl-critic-bundle.git',
                    web  => 'https://github.com/s-nez/perl-critic-bundle',
                },
            }
        }
    ) : ()
);
