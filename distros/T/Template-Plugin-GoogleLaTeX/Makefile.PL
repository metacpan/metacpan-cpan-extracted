use inc::Module::Install;

name     'Template-Plugin-GoogleLaTeX';
all_from 'lib/Template/Plugin/GoogleLaTeX.pm';
author   q{A. Sinan Unur <nanis@cpan.org>};
license  'perl';

build_requires 'Test::More';
requires 'Template::Plugin::Filter' => 0;
requires 'URI::Escape' => 0;

auto_install;

WriteAll;

