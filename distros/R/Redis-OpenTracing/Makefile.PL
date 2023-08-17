use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'Redis::OpenTracing',
    'AUTHOR'        => 'Theo van Hoesel <tvanhoesel@perceptyx.com',
    'VERSION_FROM'  => 'lib/Redis/OpenTracing.pm',
    'ABSTRACT_FROM' => 'lib/Redis/OpenTracing.pod',
    'LICENSE'       => 'perl',
    test            => {
        TESTS       => 't/Redis/OpenTracing.t t/Redis/OpenTracing/*.t',
    },
    'META_MERGE'	=> {
        "meta-spec" => { version => 2 },
        resources       => {
            repository      => {
                type            => 'git',
                url             => 'https://github.com/Perceptyx/perl-redis-opentracing.git',
                web             => 'https://github.com/Perceptyx/perl-redis-opentracing',
            },
            bugtracker      => {
                web             => 'https://github.com/Perceptyx/perl-redis-opentracing/issues',
            },
        },
    },
);
