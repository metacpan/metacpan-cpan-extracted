requires            'B::Hooks::OP::Check::LeaveEval', 'v0.0.3';
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
    requires            "Capture::Tiny";
    requires            "Test::Most";
    requires            "Test::OpenTracing::Integration", 'v0.102.1';
};
