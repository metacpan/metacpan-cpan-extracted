use inc::Module::Install;

name        'RDF-Helper-Properties';
all_from    'lib/RDF/Helper/Properties.pm';
readme_from 'lib/RDF/Helper/Properties.pm';
author      q{Kjetil Kjernsmo <kjetilk@cpan.org>};
license     'perl';

test_requires 'Test::More';
test_requires 'FindBin';

requires 'Moo'                   => 1.006001;
requires 'Types::Standard'       => 0;
requires 'namespace::autoclean'  => 0.13;
requires 'RDF::Trine'            => 0.135;

recommends 'CHI';
recommends 'Moose';

#author_tests('xt');

#auto_set_repository;

resources
  bugtracker    => "https://github.com/kjetilk/RDF-Helper-Properties/issues";

rdf_metadata;

write_doap_changes;

sign;

WriteAll;

