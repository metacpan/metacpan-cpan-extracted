use inc::Module::Install;
name 'Module-Changes';
all_from 'lib/Module/Changes.pm';
perl_version '5.006';

requires 'Class::Accessor::Complex';
requires 'Class::Accessor::Constructor';
requires 'Class::Factory::Enhanced';
requires 'DateTime';
requires 'DateTime::Format::DateParse';
requires 'DateTime::Format::Mail';
requires 'DateTime::Format::W3CDTF';
requires 'Getopt::Attribute';
requires 'Kwalify';
requires 'Perl::Version';
requires 'YAML';

build_requires 'Test::Differences';
build_requires 'Test::More' => '0.70';

use_standard_tests(without => 'pod_coverage');
auto_include;
WriteAll;
