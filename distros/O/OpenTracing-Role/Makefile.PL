use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'OpenTracing::Role',
    'VERSION_FROM'  => 'lib/OpenTracing/Role.pm',
    'LICENSE'       => 'perl',
    test            => {
        TESTS       => 't/*.t t/*/*.t',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/Perceptyx/perl-opentracing-roles.git',
                 web  => 'https://github.com/Perceptyx/perl-opentracing-roles',
             },
             bugtracker => {
                 web => 'https://github.com/Perceptyx/perl-opentracing-roles/issues'
             },
         },
    },
);
