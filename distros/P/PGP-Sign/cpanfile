# -*- perl -*-

on 'configure' => sub {
    requires 'Module::Build', '0.28';
};

requires 'IPC::Run';

on 'test' => sub {
    suggests 'Devel::Cover';
    suggests 'Perl::Critic::Freenode';
    suggests 'Test::MinimumVersion';
    suggests 'Test::Perl::Critic';
    suggests 'Test::Pod';
    suggests 'Test::Pod::Coverage';
    suggests 'Test::Spelling';
    suggests 'Test::Strict';
    suggests 'Test::Synopsis';
};
