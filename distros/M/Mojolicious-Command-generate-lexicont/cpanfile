requires 'Config::PL';
requires 'Encode';
requires 'Module::Load';
requires 'Mojo::Base';
requires 'perl', '5.008005';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'JSON';
    requires 'Mojolicious';
    requires 'Test::Exception';
    requires 'Test::More';
    requires 'Test::Warn';
};
