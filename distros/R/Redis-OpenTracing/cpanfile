requires                "Moo";
requires                "OpenTracing::AutoScope",               '>= v0.107.3';
suggests                "Redis::Fast";
requires                "Scalar::Util";
requires                "Syntax::Feature::Maybe";
requires                "Types::Standard";

on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

on 'test' => sub {
    requires            "OpenTracing::Implementation",          '>= v0.31.0';
    requires            "Test::Builder";
    requires            "Test::Deep";
    requires            "Test::MockObject";
    requires            "Test::Mock::Redis";
    requires            "Test::Most";
    requires            "Test::OpenTracing::Integration",       '>= v0.102.1';
};
