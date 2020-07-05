# -*- perl -*-

on 'configure' => sub {
    requires 'Module::Build', '0.28';
};

requires 'IPC::Run';

on 'test' => sub {
    requires 'Devel::Cover';
    requires 'Test::MinimumVersion';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Spelling';
    requires 'Test::Strict';
    requires 'Test::Synopsis';
};
