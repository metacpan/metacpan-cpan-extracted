use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Perl::Critic::Storable',
    'VERSION_FROM'  => 'lib/Perl/Critic/Storable.pm',
    'PREREQ_PM'     => {
        'Perl::Critic' => 0,
        'Test::More'   => 0,
    },
    ( $] >= 5.005 ? (
        'AUTHOR' => 'Matt Dainty <matt@bodgit-n-scarper.com>',
    ) : () ),
);
