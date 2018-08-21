requires 'perl', '5.010001';

requires 'List::MoreUtils', '0.34';
requires 'Mojo::Base';
requires 'Mojolicious', '7.75';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'Mojolicious::Lite';
    requires 'Test::Mojo';
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
