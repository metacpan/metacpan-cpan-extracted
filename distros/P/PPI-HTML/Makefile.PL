use inc::Module::Install;

name           'PPI-HTML';
all_from       'lib/PPI/HTML.pm';
requires       'CSS::Tiny'    => '1.10';
requires       'PPI'          => '0.990';
requires       'Params::Util' => '0.05';
test_requires 'File::Spec'   => '0.80';
test_requires 'Test::More'   => '0.47';
install_script 'bin/ppi2html';

WriteAll;
