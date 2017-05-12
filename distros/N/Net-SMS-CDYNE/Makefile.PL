sub author_tests  { }
sub readme_from   { }
sub auto_set_repository { }

use inc::Module::Install;
name 'Net-SMS-CDYNE';
all_from 'lib/Net/SMS/CDYNE.pm';
readme_from 'lib/Net/SMS/CDYNE.pm';
build_requires 'Test::More';
test_requires 'Test::Requires';

requires 'REST::Client';
requires 'XML::Simple';
requires 'Any::Moose';
requires 'MouseX::NonMoose';

auto_include_deps;
auto_set_repository;
WriteAll;
