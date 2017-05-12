use inc::Module::Install;

name('Module-Install-Any-Moose');

all_from('lib/Module/Install/Any/Moose.pm');

requires 'Module::Install', '0.72';
auto_include_deps;

WriteAll;