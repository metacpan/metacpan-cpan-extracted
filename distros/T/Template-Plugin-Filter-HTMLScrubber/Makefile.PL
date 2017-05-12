use inc::Module::Install;

name('Template-Plugin-Filter-HTMLScrubber');
author('Yu Isobe <yupug@cpan.org>');
version_from('lib/Template/Plugin/Filter/HTMLScrubber.pm');
abstract('TT Filter using HTML::Scrubber');
license('perl');

requires('Carp');
requires('HTML::Scrubber');
requires('Template');
requires('Template::Plugin::Filter');

build_requires('Test::Pod');
build_requires('Test::Pod::Coverage');
build_requires('Test::Perl::Critic');

use_test_base;

auto_include;
auto_install;

WriteAll;
