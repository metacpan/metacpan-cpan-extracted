requires 'HTML::Escape';
requires 'HTML::Lint';
requires 'HTML::Lint::Pluggable';
requires 'Plack::Builder';
requires 'Plack::Middleware';
requires 'Plack::Util';
requires 'Plack::Util::Accessor';
requires 'parent';
requires 'perl', '5.008_001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'HTTP::Request';
    requires 'Plack::Test';
    requires 'Test::More';
    requires 'Test::Requires';
};
