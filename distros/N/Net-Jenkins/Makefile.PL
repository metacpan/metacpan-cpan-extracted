use inc::Module::Install;
name 'Net-Jenkins';
all_from 'lib/Net/Jenkins.pm';

requires 'Moose';
requires 'methods';
requires 'Net::HTTP';
requires 'LWP::UserAgent';
requires 'URI';
requires 'JSON';
requires 'DateTime';

readme_markdown_from_pod 'lib/Net/Jenkins.pm';

tests 't/*.t';

# author_tests 'xt';
# test_requires 'Test::More';
# auto_set_repository;
auto_include;
WriteAll;
