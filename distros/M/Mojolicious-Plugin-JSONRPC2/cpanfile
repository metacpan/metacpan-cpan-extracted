requires 'perl', '5.010001';

requires 'JSON::RPC2', 'v0.4.0';
requires 'JSON::RPC2::Server', 'v0.4.0';
requires 'JSON::XS';
requires 'Mojo::Base';
requires 'Mojolicious', '5.11';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'JSON::RPC2::Client';
    requires 'Mojolicious::Lite';
    requires 'Test::Exception';
    requires 'Test::Mojo';
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
