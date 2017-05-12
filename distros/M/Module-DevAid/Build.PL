use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Module::DevAid',
    license             => 'perl',
    dist_author         => 'Kathryn Andersen',
    dist_version_from   => 'lib/Module/DevAid.pm',
	requires            => {
	     'Getopt::Long' => 2.34,
	     'Getopt::ArgvFile' => 1.10,
	     'File::Basename' => 0,
	     'Pod::Usage' => 0,
	     'Data::Dumper' => 0,
	     'Pod::Select' => 0,
	     'Pod::Text' => 0,
	     'IO::String' => 0,
	},
    build_requires => {
        'Test::More' => 0,
    },
    script_files      => [ 'scripts/moddevaid' ],
    #add_to_cleanup      => [ 'Module-DevAid-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
