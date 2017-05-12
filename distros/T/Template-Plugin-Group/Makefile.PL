use inc::Module::Install 0.77;

all_from       'lib/Template/Plugin/Group.pm';
requires       'Template'     => '2.10';
requires       'Params::Util' => '0.25';
build_requires 'Test::More'   => '0.47';
build_requires 'File::Spec'   => '0.82';

WriteAll;
