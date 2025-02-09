use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name		=> 'String::Equivalence::Amharic',
	dist_version_from	=> 'lib/String/Equivalence/Amharic.pm',
	dist_author		=> 'Daniel Yacob <dyacob\@cpan.org>',
	dist_abstract		=> "Normalization Utilities for Amharic.",
	release_status		=> 'stable',
	configure_requires	=> { 'Module::Build' => 0.42 },
	requires 		=> {
		'perl'			=> '5.6.1',
		'Regexp::Ethiopic'	=> '0.15'
	},
	license			=> 'perl',
	add_to_cleanup		=> [ 'String-*' ],
	create_makefile_pl	=> 0,  # change to 1 if desired.
	meta_merge		=> {
        	resources => {
			bugtracker => 'https://github.com/dyacob/String-Equivalence-Amharic/issues',
			repository => 'https://github.com/dyacob/String-Equivalence-Amharic.git',
			homepage => 'https://github.com/dyacob/String-Equivalence-Amharic'
		},
		x_authority	=> 'cpan:dyacob'
	}
);

$builder->create_build_script();
