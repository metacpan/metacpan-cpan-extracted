use strict;
use inc::Module::Install;

name('Template-Plugin-DateTime');
all_from('lib/Template/Plugin/DateTime.pm');
requires 'DateTime';
requires 'Template';
requires 'DateTime::Format::Strptime';

auto_include;
WriteAll;