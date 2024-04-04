
requires 'perl', '5.020';

requires 'Carp';
requires 'DateTime', '1.57';
requires 'JSON', '4.00';
requires 'List::MoreUtils', '0.418';
requires 'Log::Any', '1.704';
requires 'LWP::Protocol::https', '6.04';
requires 'LWP::UserAgent', '6.05';
requires 'Moo', '2.005005';
requires 'MooX::Types::MooseLike::Base', '0.26';
requires 'namespace::clean', '0.25';
requires 'Scalar::Util';
requires 'Storable';
requires 'Throwable', '0.200012';
requires 'Try::Tiny', '0.22';

suggests 'DateTime::Span';

on 'test' => sub {
    requires 'Cwd';
    requires 'DateTime::Span';
    requires 'Test::Class', '0.50';
    requires 'Test::MockObject';
    requires 'Test::MockObject::Extends';
    requires 'Test::Most', '0.35';
};

on 'develop' => sub {
    requires 'Dist::Zilla::App::Command::cover';
    requires 'Dist::Zilla::Plugin::ContributorsFromGit';
    requires 'Dist::Zilla::Plugin::Generate::ManifestSkip';
    requires 'Dist::Zilla::Plugin::InstallGuide';
    requires 'Dist::Zilla::Plugin::OurPkgVersion';
    requires 'Dist::Zilla::Plugin::Test::Pod::Coverage::Configurable';
    requires 'Pod::Weaver::Section::Bugs', '4.003';
    requires 'Pod::Weaver::Section::Contributors';
    requires 'Pod::Weaver::Section::Template', '0.04';

    suggests 'App::Prove::Watch';
};
