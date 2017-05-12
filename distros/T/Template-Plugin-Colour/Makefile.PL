use ExtUtils::MakeMaker;

my %opts = (
    NAME         => 'Template::Plugin::Colour',
    VERSION_FROM => 'lib/Template/Colour.pm',
    PMLIBDIRS    => [ 'lib' ],
    PREREQ_PM    => { 
        Badger   => 0.09,
        Template => 2.20,
    },
    dist         => {
        PREOP    => 'pod2text lib/Template/Plugin/Colour.pm > README',
        COMPRESS => 'gzip',
        SUFFIX   => 'gz',
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR   } = 'Andy Wardley <abw@cpan.org>';
    $opts{ ABSTRACT } = 'Template modules for colour manipulation',
}

if ($ExtUtils::MakeMaker::VERSION ge '6.30_00') {
    $opts{'LICENSE' } = 'perl';
}

WriteMakefile( %opts );

