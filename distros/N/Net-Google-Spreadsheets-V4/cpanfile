# -*- mode: cperl -*-

requires 'perl', '5.010000';

requires 'Class::Accessor::Lite';
requires 'Data::Validator';
requires 'Log::Minimal';
requires 'Carp';
requires 'Net::Google::DataAPI::Auth::OAuth2';
requires 'Net::OAuth2::AccessToken';
requires 'Text::CSV';
requires 'Furl';
requires 'JSON';
requires 'Sub::Retry';

on configure => sub {
    requires 'Module::Build::Tiny', '0.039';
};

on develop => sub {
    requires 'App::scan_prereqs_cpanfile', '0.09';
    requires 'Pod::Wordlist';
    requires 'Test::Fixme';
    requires 'Test::Spelling', '0.12';
    requires 'Test::Kwalitee', '1.23';
    requires 'Test::Kwalitee::Extra';
    requires 'Test::More', '0.96';
    requires 'Test::Pod', '1.41';
    requires 'Test::Vars';
    requires 'Config::Pit';
};

on test => sub {
    requires 'Test::More', '0.88';
};
