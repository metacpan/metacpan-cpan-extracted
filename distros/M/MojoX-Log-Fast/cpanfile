requires 'perl', '5.010001';

requires 'Log::Fast';
requires 'Mojo::Base';
requires 'Mojolicious';

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
