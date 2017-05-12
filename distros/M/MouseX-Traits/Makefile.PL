use inc::Module::Install;

all_from 'lib/MouseX/Traits.pm';

requires 'Mouse' => 0.81;

test_requires 'Test::Exception';
test_requires 'Test::More';
test_requires 'ok';

WriteAll(check_nmake => 0);
