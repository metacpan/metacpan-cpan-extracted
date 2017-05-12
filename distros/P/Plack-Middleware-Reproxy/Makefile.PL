use inc::Module::Install;

name 'Plack-Middleware-Reproxy';
all_from 'lib/Plack/Middleware/Reproxy.pm';

requires 'Plack';
requires 'URI';

recommends 'Furl';

test_requires 'HTTP::Request::Common';
test_requires 'Test::TCP';

auto_set_repository;

WriteAll;