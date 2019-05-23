requires 'perl', '5.008005';

requires 'Carp::Always';
requires 'HTTP::Request::Common';
requires 'JSON';
requires 'LWP::UserAgent';
requires 'SMS::Send::Driver';
requires 'URL::Encode';
requires 'XML::Hash::LX';

on test => sub {
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::CPAN::Meta';
    requires 'Test::DistManifest';
    requires 'Test::Exception';
    requires 'Test::HasVersion';
    requires 'Test::Kwalitee';
    requires 'Test::More';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod::Coverage';
    requires 'Test::Warn';
    requires 'Test::Warn';
    requires 'Test::UseAllModules';
};

on 'develop' => sub {
    recommends 'Devel::NYTProf';
    requires 'App::CISetup';
    requires 'App::Software::License';
    requires 'Dist::Milla';
    requires 'Dist::Zilla::App::Command::cover';
};
