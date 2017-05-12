use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Report::Generator',
    license           => 'perl',
    dist_author       => q{Jens Rehsack <rehsack@cpan.org>},
    dist_version_from => 'lib/Report/Generator.pm',
    build_requires    => {
	'Clone'                 => '0.30',
	'DBD::CSV'              => '0.30',
	'DBD::Sys'              => '0.102',
	'File::Copy'            => 0,
	'File::Path'            => 0,
	'Template'              => '2.00',
	'Template::Plugin::CSV' => '0',
	'Template::Plugin::DBI' => '2.65',
	'Test::More'            => '0.90',
	'YAML::Any'             => 0,
    },
    requires => {
	'Carp'         => 0,
	'Config::Any'  => 0,
	'Params::Util' => '1.00',
    },
    share_dir          => { dist => [ 'share', ], },
    add_to_cleanup     => ['Report-Generator-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
