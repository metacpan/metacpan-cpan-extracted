requires            "OpenTracing::GlobalTracer";
requires            "Carp";
requires            "Module::Load";
requires            "Role::Declare::Should";
requires            "Types::Standard";

on 'develop' => sub {
    requires            "ExtUtils::MakeMaker::CPANfile";
};



on 'test' => sub {
    requires            "OpenTracing::Interface::Tracer";
    requires            "Role::Tiny::With";
    requires            "Test::Most";
    requires            "Module::Loaded";
};
