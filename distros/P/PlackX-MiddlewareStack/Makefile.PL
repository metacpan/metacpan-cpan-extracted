use inc::Module::Install;
name 'PlackX-MiddlewareStack';
all_from 'lib/PlackX/MiddlewareStack.pm';

requires( 'Tie::LLHash' => 0, );
test_requires(
    'Plack'                => 0,
    'Test::More'           => 0,
    'Test::LoadAllModules' => 0,
);
use_test_base;
auto_include;
WriteAll;
