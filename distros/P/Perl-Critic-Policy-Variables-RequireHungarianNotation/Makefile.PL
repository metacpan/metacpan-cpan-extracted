use 5.10.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Perl::Critic::Policy::Variables::RequireHungarianNotation',
    AUTHOR             => q{Mario Zieschang <mziescha@cpan.org>},
    VERSION_FROM       => 'lib/Perl/Critic/Policy/Variables/RequireHungarianNotation.pm',
    ABSTRACT_FROM      => '',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.10.0,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => { 'Test::More' => 0, },
    PREREQ_PM          => { 'Perl::Critic::Policy' => 0, 'Perl::Critic::Utils' => 0, },
    TEST_REQUIRES      => { 'Test::Perl::Critic' => 0, 'Perl::Critic::TestUtils' => 0, },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/mziescha/Perl-Critic-Policy-Variables-RequireHungarianNotation.git',
                web  => 'https://gitlab.com/mziescha/Perl-Critic-Policy-Variables-RequireHungarianNotation',
            },
        }
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Perl-Critic-Policy-Variables-RequireHungarianNotation-*' },
);
