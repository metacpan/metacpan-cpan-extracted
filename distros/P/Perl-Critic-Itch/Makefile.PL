use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Perl::Critic::Itch',
    AUTHOR        => 'Marcelo Rodrigues <marcelo@cpan.org>',
    VERSION_FROM  => 'lib/Perl/Critic/Itch.pm',
    ABSTRACT      => 'Perl::Critic::Itch - A collection of Policies to solve some Itches',
    PL_FILES      => {},
    PREREQ_PM     => {
                      'Test::More'              => 0,
                      'Perl::Critic'            => '1.052',
                      'Perl::Critic::Utils'     => 1.052,
                      'Perl::Critic::Violation' => 1.052,
                      'Perl::Critic::TestUtils' => 1.052,
                    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES    => 'Perl-Critic-Itch-*' },
);
