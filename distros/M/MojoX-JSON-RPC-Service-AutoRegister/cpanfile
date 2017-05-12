requires 'Mojo::Base';
requires 'MojoX::JSON::RPC::Service';
requires 'perl', '5.008_005';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Mojolicious::Lite';
    requires 'Test::Mojo';
    requires 'Test::More', '0.98';
};
