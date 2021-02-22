requires 'perl', '5.010001';

requires 'JSON::RPC2', 'v1.0.0';
requires 'JSON::RPC2::Client';
requires 'JSON::XS';
requires 'Mojo::Base';
requires 'Mojo::UserAgent';
requires 'Mojolicious', '8.67';
requires 'Scalar::Util';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'JSON::RPC2::Server';
    requires 'Mojolicious::Lite';
    requires 'Mojolicious::Plugin::JSONRPC2', 'v1.1.1';
    requires 'Test::Exception';
    requires 'Test::Mojo';
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
