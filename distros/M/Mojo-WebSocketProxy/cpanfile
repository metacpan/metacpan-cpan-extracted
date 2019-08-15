requires 'Class::Method::Modifiers';
requires 'Future', '>= 0.36';
requires 'Future::Mojo', '>= 0.004';
requires 'indirect';
requires 'curry', '>= 1.001';
requires 'JSON::MaybeUTF8';
requires 'MojoX::JSON::RPC';
requires 'Mojolicious', '>= 7.29';
requires 'IO::Async::Loop::Mojo';
requires 'Scalar::Util';
requires 'Unicode::Normalize', '>= 1.25';
requires 'DataDog::DogStatsd::Helper', '>= 0.05';
requires 'perl', '5.014';

requires 'Job::Async', 0;

on configure => sub {
    requires 'ExtUtils::MakeMaker', '7.1101';
};

on test => sub {
    requires 'Path::Tiny';
    requires 'Test::Mojo';
    requires 'Test::Simple', '0.44';
    requires 'Test::Fatal';
    requires 'Test::MockModule';
    requires 'Test::MockObject';
    requires 'Test::More', '0.98';
    requires 'Test::TCP';
};
