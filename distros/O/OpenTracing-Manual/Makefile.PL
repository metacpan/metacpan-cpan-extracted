use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'OpenTracing::Manual',
    'AUTHOR'        => [
        'Theo van Hoesel (VANHOESEL) <tvanhoesel@perceptyx.com'
    ],
    'VERSION'       => '0.02',
    'ABSTRACT_FROM' => 'lib/OpenTracing/Manual.pod',
    'LICENSE'       => 'artistic2',
    'MAN3PODS'      => {
        'lib/OpenTracing/Manual.pod'
            => 'blib/man3/OpenTracing::Manual.3',
    },
    'META_MERGE'    => {
        description => 'This Manual is a quick overview of what is available in'
              . '  ' . 'Perl related to the OpenTracing API related Interface'
              . '  ' . 'Definition.',
        keywords        => [
            'OpenTracing',
            'Distributed Tracing',
            'Manual',
            'Tracing',
            'Developer',
            'Implementation',
            'Integration',
            'Framwork',
            'Micro Service',
            'Observabillity',
            'APM',
        ],
    },
    
);