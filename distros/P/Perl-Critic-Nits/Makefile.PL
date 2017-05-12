use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Perl::Critic::Nits',
    AUTHOR              => 'Kent Cowgill <kent@c2group.net>',
    VERSION_FROM        => 'lib/Perl/Critic/Nits.pm',
    ABSTRACT_FROM       => 'lib/Perl/Critic/Nits.pm',
    ( $ExtUtils::MakeMaker::VERSION > 6.31 ? ( LICENSE => 'perl' ) : () ),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Perl::Critic' => 1.07,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Perl-Critic-Nits-*' },
);
