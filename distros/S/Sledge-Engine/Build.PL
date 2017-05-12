use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Sledge::Engine',
    license             => 'perl',
    dist_author         => 'Tomohiro IKEBE <ikebe@shebang.jp>',
    dist_version_from   => 'lib/Sledge/Engine.pm',
    requires => {
        'Test::More' => 0,
        'Sledge::Hammer' => '1.0',
        'Module::Pluggable' => '3.1',
        'Class::Inspector' => '1.16',
        'Sledge::Utils' => '0.02',
        'String::CamelCase' => '0.01',
    },
    add_to_cleanup      => [ 'Sledge-Engine-*' ],
);

$builder->create_build_script();
