use inc::Module::Install;
name 'PAD';
all_from 'lib/PAD.pm';

requires 'Plack::Runner';
requires 'Plack::App::Directory';
requires 'Plack::App::File';
requires 'Plack::Request';
requires 'Text::Markdown';
requires 'Pod::Usage';
test_requires 'Plack::Request';
test_requires 'Test::Requires';

tests 't/*.t';
author_tests 'xt';

auto_set_repository;
auto_include;

install_script 'script/pad';

WriteAll;
