use ExtUtils::MakeMaker;
use 5.006;

my %opts = (
    NAME         => 'Pipe',
    VERSION_FROM => 'lib/Pipe.pm',
    ABSTRACT_FROM => 'lib/Pipe.pm',
    AUTHOR       => 'Gabor Szabo <gabor@szabgab.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Want'                => '0.21',
        'Test::More'          => '0.98',
        'Test::NoWarnings'    => '1.04',
        'File::Find::Rule'    => '0.33',
        'File::Temp'          => 0,
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
                 url  => 'https://github.com/szabgab/Pipe.git',
                 web  => 'https://github.com/szabgab/Pipe',
             },
             bugtracker => {
                 web => 'https://github.com/szabgab/Pipe/issues'
             },
         },
    },
);

WriteMakefile( %opts );
