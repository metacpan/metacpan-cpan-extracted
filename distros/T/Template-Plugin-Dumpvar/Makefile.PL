use inc::Module::Install;

name          'Template-Plugin-Dumpvar';
all_from      'lib/Template/Plugin/Dumpvar.pm';
requires      'Template'       => '2.10';
requires      'Devel::Dumpvar' => '0.02';
test_requires 'Test::More'     => '0.47';
test_requires 'File::Spec'     => '0.82';

WriteAll;
