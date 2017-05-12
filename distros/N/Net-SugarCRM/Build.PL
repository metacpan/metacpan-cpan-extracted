use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::SugarCRM',
    license             => 'gpl',
    dist_author         => q{Nito Martinez <Nito@Qindel.ES>},
    dist_version_from   => 'lib/Net/SugarCRM.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
	'Log::Log4perl' => 0,
	'File::Spec' => 0,
	'Moose' => 0,
	'JSON' => 0,
	'LWP::UserAgent' => 0,
	'Readonly' => 0,
	'Try::Tiny' => 0,
	'DateTime' => 0,
	'DBI' => 0,
    },
    add_to_cleanup      => [ 'Net-SugarCRM-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
