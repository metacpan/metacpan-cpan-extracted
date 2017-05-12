use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name => 'SQL::Stash',
	license => 'mit',
	configure_requires => {
		'version' => '>=0.77',
		'Module::Build' => '',
	},
	build_requires => {
		'DBD::Mock' => '',
		'DBI' => '',
		'File::Spec' => '',
		'FindBin' => '',
		'Test::BDD::Cucumber' => '',
		'Test::Exception' => '',
		'Test::MockModule' => '',
		'Test::More' => '',
	},
	requires => {
		'perl' => '>=5.006',
		'version' => '>=0.77',
	},
	add_to_cleanup => ['SQL-Stash-*'],
	create_readme => 1,
	recursive_test_files => 1,
);

$builder->create_build_script();

