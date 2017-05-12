requires 'Encode';
requires 'Plack';
requires 'Plack::App::Directory';
requires 'Plack::App::File';
requires 'Plack::Util';
requires 'Plack::Util::Accessor';
requires 'Text::Xslate';
requires 'parent';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'HTTP::Request';
    requires 'Plack::Test';
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
