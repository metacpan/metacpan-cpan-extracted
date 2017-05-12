use inc::Module::Install;

name           'Template-Plugin-Textile';
all_from       'lib/Template/Plugin/Textile.pm';

requires       'Template'       => 2.00;
requires       'Text::Textile'  => 2.12;

license 'perl';
githubmeta;
author_tests('xt');

WriteAll;
