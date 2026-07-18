use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Perl::Critic::Policy::ErrorHandling::RequireReturnFromEval',
    AUTHOR           => 'Blaine Motsinger <blaine@renderorange.com>',
    VERSION_FROM     => 'lib/Perl/Critic/Policy/ErrorHandling/RequireReturnFromEval.pm',
    ABSTRACT_FROM    => 'lib/Perl/Critic/Policy/ErrorHandling/RequireReturnFromEval.pm',
    LICENSE          => 'gpl_2',
    MIN_PERL_VERSION => '5.10.1',

    PREREQ_PM => {
        'Perl::Critic'     => '1.126',
        'Perl::Critic::Utils' => 0,
        'parent'           => 0,
        'strict'           => 0,
        'warnings'         => 0,
    },

    TEST_REQUIRES => {
        'Test::More'       => '0.98',
        'Perl::Critic'     => '1.126',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/renderorange/perl-critic-policy-errorhandling-requirereturnfromeval.git',
                web  => 'https://github.com/renderorange/perl-critic-policy-errorhandling-requirereturnfromeval',
            },
            bugtracker => {
                web => 'https://github.com/renderorange/perl-critic-policy-errorhandling-requirereturnfromeval/issues',
            },
        },
    },

    test => { TESTS => 't/*.t' },
);
