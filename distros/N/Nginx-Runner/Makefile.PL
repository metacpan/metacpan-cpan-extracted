use inc::Module::Install;

name 'Nginx-Runner';
all_from 'lib/Nginx/Runner.pm';

requires 'File::Temp';
requires 'IPC::Open3';

test_requires 'Test::Spec';
test_requires 'LWP::UserAgent';
test_requires 'LWP::Protocol::https';
test_requires 'IO::Socket::INET';

tests 't/*.t';

resources
  bugtracker => 'https://github.com/und3f/nginx-runner/issues',
  repository => 'http://github.com/und3f/nginx-runner';

WriteAll;
