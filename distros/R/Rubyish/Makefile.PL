use inc::Module::Install;

name 'Rubyish';

all_from 'lib/Rubyish.pm';
abstract 'Perl programming, the rubyish way.';

requires
    'autobox'        => 2.55,
    'UNIVERSAL::isa' => 1.01,
    'Devel::Declare' => '0.003004',
    'Rubyish::Attribute' => '1.0',
    'YAML' => 0.68,
    'Data::Dumper' => 2.121,
    'Class::Inspector' => 1.23,
    'Clone' => 0.31,
    'Sub::Exporter' => 0.982;

auto_set_repository;
WriteAll;
