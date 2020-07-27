requires            'B::Hooks::EndOfScope';
requires            'List::MoreUtils';
requires            'OpenTracing::GlobalTracer';
requires            'OpenTracing::Implementation::NoOp';
requires            'Sub::Info';
requires            'PerlX::Maybe';
requires            'YAML::XS';
requires            'PPI';
requires            'Perl::Critic::Utils::McCabe';

requires            'Scope::Context';

on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

on 'test' => sub {
    requires            "Test::Most";
    requires            "Test::OpenTracing::Integration", 'v0.101.2';
};
