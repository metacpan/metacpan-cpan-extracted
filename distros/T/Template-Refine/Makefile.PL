use inc::Module::Install;

name 'Template-Refine';
all_from 'lib/Template/Refine.pm';

requires 'HTML::Selector::XPath';
requires 'List::Util';
requires 'Moose';
requires 'Path::Class';
requires 'Sub::Exporter';
requires 'XML::LibXML';
requires 'namespace::clean';
build_requires 'Directory::Scratch';
build_requires 'Test::Exception';
build_requires 'Test::More';
build_requires 'ok';

WriteAll();
