requires 'Mojolicious', '>= 9.34';
requires 'IPC::SharedMem';

on configure => sub {
    requires 'Module::Build';
    requires 'perl', '5.016';
};

on test => sub {
    requires 'Test::More';
    requires 'Test::Exception';
    requires 'Test::Pod';
};

feature 'ci' => sub {
    requires 'Minilla';
    requires 'Devel::Cover';
    requires 'Devel::Cover::Report::Codecovbash';
    requires 'TAP::Formatter::GitHubActions';
    requires 'Test::Pod::Coverage';
};
