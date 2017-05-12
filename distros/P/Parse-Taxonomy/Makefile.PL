use ExtUtils::MakeMaker;
require 5.008;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile(
    NAME            => 'Parse::Taxonomy',
    VERSION_FROM    => 'lib/Parse/Taxonomy.pm',
    ABSTRACT_FROM   => 'lib/Parse/Taxonomy.pm',
    AUTHOR          => 'James E Keenan (jkeenan@cpan.org>)',
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' )
                    =>  {
                            'Test::Simple' => 0.10,
                        },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/Parse-Taxonomy/',
            repository => {
                url => 'https://github.com/jkeenan/parse-taxonomy.git',
                web => 'https://github.com/jkeenan/parse-taxonomy',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-Taxonomy',
            },
        },
    })),
    PREREQ_PM    => {
                     'Text::CSV_XS' => 1.10,
                     'Carp'         => 0,
                     'Scalar::Util' => 0,
    },
);
