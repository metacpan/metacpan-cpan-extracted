use ExtUtils::MakeMaker;


WriteMakefile(
    NAME            => 'Template::Filters::LazyLoader',
    AUTHOR          => 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>',
    VERSION_FROM    => 'lib/Template/Filters/LazyLoader.pm',
    PREREQ_PM       => {
        'Class::Accessor::Fast'         => 0,
        'Module::Recursive::Require'    => 0.04,
        'UNIVERSAL::require'            => 0,
        'Template'                      => 0,
        'Test::Differences'             => 0,
        'Test::Exception'               => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Filters-LazyLoader-*' },

);
