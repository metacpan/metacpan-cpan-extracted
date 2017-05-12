use inc::Module::Install;

name       'Path-Dispatcher-Declarative';
all_from   'lib/Path/Dispatcher/Declarative.pm';
repository 'http://github.com/bestpractical/path-dispatcher-declarative';

requires 'Path::Dispatcher' => '1.02';

requires 'Any::Moose';
requires 'Sub::Exporter';

WriteAll;

