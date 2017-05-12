use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Seeder',
    AUTHOR              => 'François Fauteux <ffauteux@cpan.org>',
    VERSION_FROM        => 'lib/Seeder.pm',
    ABSTRACT_FROM       => 'lib/Seeder.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'         => 0,
        'Carp'               => 0,
        'List::Util'         => 0,
        'List::MoreUtils'    => 0,
        'Bio::Perl'          => 0,
        'Bio::SeqIO'         => 0,
        'Bio::LiveSeq::DNA'  => 0,
        'Bio::LiveSeq::SeqI' => 0,
        'Algorithm::Loops'   => 0,
        'Math::Spline'       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Seeder-*' },
);