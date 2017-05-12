#! perl

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SugarSync::API',
    license             => 'perl',
    dist_author         => 'Johan Vromans <jv@cpan.org>',
    dist_version_from   => 'lib/SugarSync/API.pm',
    requires => {
        'Config::Tiny' => 0,
	'XML::Simple' => 0,
	'LWP::UserAgent' => 0,
	'Carp' => 0,
	'Data::Dumper' => 0,
	'File::Basename' => 0,
	'File::Path' => 0,
	'Time::Local' => 0,
	'Getopt::Long' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'SugarSync-API-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
