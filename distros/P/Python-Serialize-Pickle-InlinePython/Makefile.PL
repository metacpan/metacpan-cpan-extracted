use inc::Module::Install;
name 'Python-Serialize-Pickle-InlinePython';
all_from 'lib/Python/Serialize/Pickle/InlinePython.pm';

requires 'Inline::Python' => 0.28;

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_include;
WriteAll;
