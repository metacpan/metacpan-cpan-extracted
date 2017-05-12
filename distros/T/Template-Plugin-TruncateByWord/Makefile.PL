use inc::Module::Install;
name 'Template-Plugin-TruncateByWord';
perl_version '5.008';
all_from 'lib/Template/Plugin/TruncateByWord.pm';

requires 'Template';
requires 'Encode';

auto_include;
WriteAll;
