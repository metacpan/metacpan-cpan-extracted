use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'Redis::OpenTracing',
    'AUTHOR'        => 'Theo van Hoesel <tvanhoesel@perceptyx.com',
    'VERSION_FROM'  => 'lib/Redis/OpenTracing.pm',
    'ABSTRACT_FROM' => 'lib/Redis/OpenTracing.pod',
    'LICENSE'       => 'perl',
    test            => {
        TESTS       => 't/*.t',
    },
);
