use strict;
use warnings;
use Test::More tests => 1;
use Module::CoreList::DBSchema;

my $tests = {
 'cl_versions' => [
   'perl_ver VARCHAR(20) NOT NULL',
   'mod_name VARCHAR(300) NOT NULL',
   'mod_vers VARCHAR(30)',
   'deprecated BOOL'
 ],
 'cl_bugtracker' => [
   'mod_name VARCHAR(300) NOT NULL',
   'url TEXT'
 ],
 'cl_perls' => [
   'perl_ver VARCHAR(20) NOT NULL',
   'released VARCHAR(10)'
 ],
 'cl_upstream' => [
   'mod_name VARCHAR(300) NOT NULL',
   'upstream VARCHAR(20)'
 ],
 'cl_families' => [
   'perl_ver VARCHAR(20) NOT NULL',
   'family VARCHAR(20) NOT NULL'
 ]
};

my $mcdbs = Module::CoreList::DBSchema->new();
my %tables = $mcdbs->tables;
is_deeply( \%tables, $tests, 'Table structure looks okay' );
