use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'OpenTracing::Interface',
    'AUTHOR'        => [
        'Theo van Hoesel (VANHOESEL) <tvanhoesel@perceptyx.com'
    ],
    'VERSION'       => 'v0.204.0',
    'ABSTRACT_FROM' => 'lib/OpenTracing/Interface.pod',
    'LICENSE'       => 'artistic2',
    'MAN3PODS'      => {
        'lib/OpenTracing/Interface.pod'
            => 'blib/man3/OpenTracing::Interface.3',
        'lib/OpenTracing/Types.pm'
            => 'blib/man3/OpenTracing::types.3',
        'lib/OpenTracing/Interface/ContextReference.pod'
            => 'blib/man3/OpenTracing::Interface::ContextReference.3',
        'lib/OpenTracing/Interface/Scope.pod'
            => 'blib/man3/OpenTracing::Interface::Scope.3',
        'lib/OpenTracing/Interface/ScopeManager.pod'
            => 'blib/man3/OpenTracing::Interface::ScopeManager.3',
        'lib/OpenTracing/Interface/Span.pod'
            => 'blib/man3/OpenTracing::Interface::Span.3',
        'lib/OpenTracing/Interface/SpanContext.pod'
            => 'blib/man3/OpenTracing::Interface::SpanContext.3',
        'lib/OpenTracing/Interface/Tracer.pod'
            => 'blib/man3/OpenTracing::Interface::Tracer.3',
    },
    'META_MERGE'    => {
        provides        => {
            'OpenTracing::Interface'
                => { version => 'v0.204.0', file => 'lib/OpenTracing/Interface.pm' },
            'OpenTracing::Interface::ContextReference'
                => { version => 'v0.204.0', file => 'lib/OpenTracing/Interface/ContextReference.pm' },
            'OpenTracing::Interface::Scope'
                => { version => 'v0.204.0', file => 'lib/OpenTracing/Interface/Scope.pm' },
            'OpenTracing::Interface::ScopeManager'
                => { version => 'v0.204.0', file => 'lib/OpenTracing/Interface/ScopeManager.pm' },
            'OpenTracing::Interface::Span'
                => { version => 'v0.204.0', file => 'lib/OpenTracing/Interface/Span.pm' },
            'OpenTracing::Interface::SpanContext'
                => { version => 'v0.204.0', file => 'lib/OpenTracing/Interface/SpanContext.pm' },
            'OpenTracing::Interface::Tracer'
                => { version => 'v0.204.0', file => 'lib/OpenTracing/Interface/Tracer.pm' },
            'OpenTracing::Types'
                => { version => 'v0.204.0', file => 'lib/OpenTracing/Types.pm' },
        },
        description => '`OpenTracing::Interface` describes the OpenTracing API'
              . '  ' . 'for the Perl5 programming language.'
              . '  ' . 'It provides a set of roles that can be consumed to do'
              . '  ' .  'thorough type checks.'
              . '  ' . 'For convenience, `OpenTracing::Types` allows for \'Duck'
              . '  ' . 'Type\' checks',
        keywords        => [
            'OpenTracing',
            'Distributed Tracing',
            'Context Reference',
            'Scope',
            'Scope Manager',
            'Span',
            'Span Context',
            'Tracer',
            'Micro Service',
            'Observabillity',
            'APM',
        ],
    },
    test => {
        'TESTS'         => 't/*.t t/Interface/*/*.t t/Interface/*.t t/Types/*.t',
    },
    
);