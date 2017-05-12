use inc::Module::Install;
name 'Plack-Middleware-Test-StashWarnings';
all_from 'lib/Plack/Middleware/Test/StashWarnings.pm';
readme_from 'lib/Plack/Middleware/Test/StashWarnings.pm';
repository 'http://github.com/bestpractical/plack-middleware-test-stashwarnings';

requires 'Storable';
requires 'Plack';

test_requires 'Test::More';
test_requires 'Plack::Test';
test_requires 'Plack::Request';
test_requires 'HTTP::Request::Common';
test_requires 'Scalar::Util';

author_tests('xt');

WriteAll;
