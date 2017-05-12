use strict;
use warnings;
use Module::Build;

my %builder_args = (
    module_name         => 'Probe::MachineInfo',
    license             => 'perl',
    dist_author         => 'Sagar R. Shah <sagarshah@softhome.net>',
    dist_version_from   => 'lib/Probe/MachineInfo.pm',
    requires => {
			  'Linux::Distribution' => 0.11,
			  'Proc::Reliable'   => 0,
				'POSIX'            => 0,
        'Test::More'       => 0,
				'Unix::Processors' => 0,
    },
		create_readme       => 1, 
    add_to_cleanup       => [ '*.tar.gz', 'Build', '_build' ],
);

# Windows only modules
if($^O ne 'MSWin') {
	# TODO: Other OSes to exclude?
	$builder_args{requires}{'Unix::Processors'} = 0;
}

my $builder = Module::Build->new(%builder_args);
$builder->create_build_script();
