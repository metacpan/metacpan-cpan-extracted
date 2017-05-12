# -*- mode: cperl -*-

requires 'perl', '5.008005';

requires 'DBI';

on configure => sub {
    requires 'Module::Build::Tiny', '0.039';
};

on develop => sub {
    requires 'App::scan_prereqs_cpanfile', '0.09';
    requires 'Pod::Wordlist';
    requires 'Test::Fixme';
    requires 'Test::Kwalitee';
    requires 'Test::Kwalitee::Extra';
    requires 'Test::Spelling', '0.12';
    requires 'Test::More', '0.96';
    requires 'Test::Pod';
    requires 'Test::Vars';
};

on test => sub {
    requires 'Test::More', '0.96';
};
