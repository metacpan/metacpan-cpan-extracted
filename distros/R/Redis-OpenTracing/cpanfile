requires                "Carp";
requires                "Moo";
requires                "OpenTracing::GlobalTracer";
requires                "Scalar::Util";
requires                "Syntax::Feature::Maybe";
requires                "syntax";
requires                "Types::Standard";

suggests                "Redis::Fast";

on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

on 'test' => sub {
    requires            "OpenTracing::AutoScope",               '>= v0.107.3';
    requires            "OpenTracing::Implementation::Test";
    requires            "OpenTracing::Implementation",          '>= v0.31.0';
    requires            "Test::Builder";
    requires            "Test::Deep";
    requires            "Test::Exception";
    requires            "Test::Mock::Redis";
    requires            "Test::More";
    requires            "Test::Most";
    requires            "Test::OpenTracing::Integration",       '>= v0.104.1';
};
