use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'OpenTracing::Implementation::DataDog',
    'VERSION_FROM'  => 'lib/OpenTracing/Implementation/DataDog.pm',
    'LICENSE'       => 'perl',
    test            => {
        TESTS       => 't/OpenTracing/Implementation/DataDog/*.t t/OpenTracing/Implementation/DataDog/*/*.t',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/Perceptyx/perl-opentracing-implementation-datadog.git',
                 web  => 'https://github.com/Perceptyx/perl-opentracing-implementation-datadog',
             },
             bugtracker => {
                 web => 'https://github.com/Perceptyx/perl-opentracing-implementation-datadog/issues'
             },
         },
    },
);
