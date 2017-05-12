use ExtUtils::MakeMaker;
use 5.006;

my %opts = (
    NAME	     => 'Pipe',
    VERSION_FROM => 'lib/Pipe.pm',
    AUTHOR       => 'Gabor Szabo <gabor@szabgab.com>',
    ABSTRACT     => 'Framework for creating pipes using iterators',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Want'                => '0.21',
        'Test::More'          => '0.98',
        'Test::NoWarnings'    => '1.04',
        'File::Find::Rule'    => '0.33',
        'File::Temp'          => 0,
    },
    META_MERGE        => {
       resources => {
           repository  =>  'https://github.com/szabgab/Pipe',
       },
	},
);

WriteMakefile( %opts );
