use ExtUtils::MakeMaker;

my %opts = (
    NAME	     => 'Pipe::Tube::Csv',
    VERSION_FROM => 'lib/Pipe/Tube/Csv.pm',
    AUTHOR       => 'Gabor Szabo <gabor@szabgab.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Pipe'                => '0.03',
        'Test::More'          => '0.47',
        'Text::CSV'           => '1.21',
    },
    BUILD_REQUIRES => {
        'Test::Pod'           => '1.00',
        'Test::Pod::Coverage' => '1.00',
        'Test::Perl::Critic'  => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/szabgab/Pipe-Tube-Csv.git',
                 web  => 'https://github.com/szabgab/Pipe-Tube-Csv',
             },
             bugtracker => {
                 web => 'https://github.com/szabgab/Pipe-Tube-Csv/issues'
             },
         },
    },
);

WriteMakefile( %opts );
