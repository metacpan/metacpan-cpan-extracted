use inc::Module::Install 0.75;

all_from      'lib/Template/Plugin/Cycle.pm';
requires      'File::Spec'   => '0.82';
requires      'Params::Util' => '0.20';
requires      'Template'     => '2.10';
test_requires 'Test::More'   => '0.47';

WriteAll;
