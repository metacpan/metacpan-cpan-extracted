use inc::Module::Install;
name 'MouseX-Object-Pluggable';
all_from 'lib/MouseX/Object/Pluggable.pm';

requires(
    'Class::Method::Modifiers'  => '1.01',
    'Mouse'                     => '0.17',
    'Module::Pluggable::Object' => '3.6',
);

test_requires(
    'Test::More'                   => 0,
    'Module::Pluggable::Object'    => 0,
    'Module::Install::AuthorTests' => 0,
);

use_test_base;
auto_include;
WriteAll;
