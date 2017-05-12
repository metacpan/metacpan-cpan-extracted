use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup     => [qw/ Template-Provider-DBIC-* /],
    build_requires     => {
        'DBD::SQLite' => '1.11',
        'DBIx::Class' => '0',
        'Test::More'  => '0',
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    dist_version_from  => 'lib/Template/Provider/DBIC.pm',
    license            => 'perl',
    module_name        => 'Template::Provider::DBIC',
    requires           => {
        'Date::Parse'        => '0',
        'File::Path'         => '0',
        'File::Spec'         => '0',
        'Template::Provider' => '0',
    },
);

$builder->create_build_script();
