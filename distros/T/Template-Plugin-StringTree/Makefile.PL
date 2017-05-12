use strict;
use inc::Module::Install;

name           'Template-Plugin-StringTree';
all_from       'lib/Template/Plugin/StringTree.pm';
requires       'File::Spec'   => '0.80';
requires       'List::Util'   => '1.11';
requires       'Scalar::Util' => 0;
requires       'Template'     => 0;
build_requires 'Test::More'   => '0.42';

WriteAll;
