requires 'perl', '5.010001';

requires 'Mojo::Base';
requires 'MojoX::Log::Fast';
requires 'Mojolicious', '6';
requires 'Narada';
requires 'Narada::Config';
requires 'Narada::Lock';
requires 'Scalar::Util';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
