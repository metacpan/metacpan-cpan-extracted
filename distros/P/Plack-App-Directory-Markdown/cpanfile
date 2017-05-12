requires 'Data::Section::Simple';
requires 'HTTP::Date';
requires 'Path::Iterator::Rule';
requires 'Plack::App::Directory';
requires 'Plack::Middleware::Bootstrap';
requires 'Text::Markdown';
requires 'Text::Xslate';
requires 'URI';
requires 'parent';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'HTTP::Message';
    requires 'Plack::Test';
    requires 'Test::More', "0.98";
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
