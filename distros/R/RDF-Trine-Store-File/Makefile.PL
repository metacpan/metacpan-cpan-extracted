use inc::Module::Install;

name     'RDF-Trine-Store-File';
all_from 'lib/RDF/Trine/Store/File.pm';
readme_from 'lib/RDF/Trine/Store/File.pm';
author   q{Kjetil Kjernsmo <kjetilk@cpan.org>};
license  'perl';

test_requires 'Test::More';
test_requires 'Test::RDF::Trine::Store' => '0.137';
test_requires 'Test::RDF' => 0.24;

build_requires 'URI::Escape';

requires 'RDF::Trine';
requires 'File::Temp';
requires 'File::Util';
requires 'File::Data';
requires 'Scalar::Util';
requires 'Carp';
requires 'Log::Log4perl';
requires 'Digest::MD5';


author_tests('xt');

auto_set_repository;
auto_set_bugtracker;

write_doap_changes;

sign;

WriteAll;

