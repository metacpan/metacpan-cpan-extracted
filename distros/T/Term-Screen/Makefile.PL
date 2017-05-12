use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    'NAME'		=> 'Term::Screen',
    'VERSION_FROM'	=> 'lib/Term/Screen.pm', 
    'PREREQ_PM'      => {
        'Term::Cap'  => 0,
        'Test::More' => 0,
    },
    'LICENSE'  => 'perl',
    'AUTHOR'   => ['Jonathan Stowe <jns@gellyfish.co.uk>'],
    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),
    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/jonathanstowe/Term-Screen',
                    url  => 'https://github.com/jonathanstowe/Term-Screen.git',
                },
            },
          })
    ),
);
