use inc::Module::Install;

name 'Sub-Auto';
license 'perl';
all_from 'lib/Sub/Auto.pm';

requires 'Class::AutoloadCAN' => 0;
requires 'Devel::Declare'     => 0.002;
requires 'Scope::Guard'       => 0;
requires 'Sub::Name'          => 0;

auto_install;
WriteAll;
