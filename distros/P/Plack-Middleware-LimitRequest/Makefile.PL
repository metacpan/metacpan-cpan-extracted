use inc::Module::Install;
name 'Plack-Middleware-LimitRequest';
all_from 'lib/Plack/Middleware/LimitRequest.pm';

requires 'Plack::Middleware';
requires 'Plack::Util::Accessor';
build_requires 'Test::More';
build_requires 'HTTP::Request::Common';
build_requires 'Plack::Builder';
build_requires 'Plack::Test';
use_test_base;
auto_include;
repository 'https://github.com/nipotan/Plack-Middleware-LimitRequest';
WriteAll;
