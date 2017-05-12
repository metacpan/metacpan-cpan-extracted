requires 'perl', '5.010001';

requires 'Mojo::Base';
requires 'Mojo::UserAgent';
requires 'Mojo::Util';
requires 'Mojolicious', '7.13';
requires 'Sub::Throttler', 'v0.2.0';
requires 'Sub::Util', '1.40';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'Sub::Throttler::Limit';
    requires 'Test::More';
    requires 'ojo';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
