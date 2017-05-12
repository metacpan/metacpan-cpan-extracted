use inc::Module::Install 0.75;

all_from      'lib/Template/Parser/LocalizeNewlines.pm';
requires      'Template' => '2.00';
test_requires 'Test::More' => '0.47';

WriteAll;
