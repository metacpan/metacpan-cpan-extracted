requires 'perl', '5.008001';

requires 'Plack', '0.9920';

recommends 'IO::Socket::IP';
recommends 'Time::HiRes';

suggests 'IO::Socket::SSL';
suggests 'Net::SSLeay', '1.49';

if ($^O eq 'cygwin') {
    recommends 'Win32::Process';
}

on configure => sub {
    requires 'Module::Build';
    requires 'Module::CPANfile';
    requires 'Software::License';
};

on test => sub {
    requires 'LWP';
    requires 'Test::More', '0.88';
    requires 'Test::TCP', '0.15';

    suggests 'LWP::Protocol::https';
};

feature examples => sub {
    recommends 'Mojolicious';
};

on develop => sub {
    requires 'Devel::Cover';
    requires 'Devel::NYTProf';
    requires 'File::Slurp';
    requires 'Module::Build';
    requires 'Module::Build::Version';
    requires 'Module::Signature';
    requires 'Perl::Critic';
    requires 'Perl::Critic::Community';
    requires 'Perl::Tidy';
    requires 'Pod::Markdown';
    requires 'Pod::Readme';
    requires 'Readonly';
    requires 'Software::License';
    requires 'Test::CheckChanges';
    requires 'Test::CPAN::Changes';
    requires 'Test::CPAN::Meta';
    requires 'Test::DistManifest';
    requires 'Test::Distribution';
    requires 'Test::EOL';
    requires 'Test::Kwalitee';
    requires 'Test::MinimumVersion';
    requires 'Test::More';
    requires 'Test::NoTabs';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::PPPort';
    requires 'Test::Signature';
    requires 'Test::Spelling';
};
