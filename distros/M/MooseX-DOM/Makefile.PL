use strict;
use inc::Module::Install;

name('MooseX-DOM');
all_from('lib/MooseX/DOM.pm');

requires 'Class::Inspector';
requires 'Moose';
requires 'XML::LibXML', 1.63;
requires 'XML::LibXML::XPathContext';

test_requires 'Test::More';
test_requires 'Test::UseAllModules';

auto_include;
WriteAll;