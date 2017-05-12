use inc::Module::Install;
all_from 'lib/Plack/Middleware/REPL.pm';
readme_from('lib/Plack/Middleware/REPL.pm');
requires 'Plack', 0.9977;
requires 'Carp::REPL', 0.15;
build_requires 'Test::More', 0.88;
test_requires 'Test::Requires';
auto_set_repository();
WriteAll;
