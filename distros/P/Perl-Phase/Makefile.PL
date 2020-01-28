use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME               => 'Perl::Phase',
    DISTNAME           => "Perl-Phase",
    AUTHOR             => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM       => 'lib/Perl/Phase.pm',
    ABSTRACT_FROM      => 'lib/Perl/Phase.pm',
    PREREQ_PM          => {},
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 0 },
    TEST_REQUIRES      => {
        "Devel::Peek"         => 0,
        "ExtUtils::MakeMaker" => 0,
        "File::Spec"          => 0,
        "Test::Spec"          => 0
    },
    MIN_PERL_VERSION => "5.014",
    PL_FILES         => {},
    PREREQ_PM        => {
        XSLoader => 0,
    },
    META_MERGE => {
        resources => {
            repository => q[https://github.com/drmuey/p5-Perl-Phase.git],
            bugtracker => q[https://github.com/drmuey/p5-Perl-Phase/issues],
            keywords   => [ 'perl', 'global', 'phase', ],
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Perl-Phase-*' },
);

my %FallbackPrereqs = (
    "Devel::Peek"         => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec"          => 0,
    "Test::Spec"          => 0,
    XSLoader              => 0,
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    delete $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{BUILD_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
