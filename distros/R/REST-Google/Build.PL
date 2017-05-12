use Module::Build;

use strict;

my $build = Module::Build->new(
	module_name => 'REST::Google',
	license => 'perl',
	requires => {
		'perl' => '5.6.1',
		'version' => '0.50',
		'Test::More' => '0.47',
		'Class::Accessor' => '0.31',
		'Class::Data::Inheritable' => '0.06',
		'JSON::Any' => '1.16',
		'LWP::UserAgent' => '2.033',
		'URI' => '1.35',
	},
	dist_author => 'Eugen Sobchenko <ejs@cpan.org>',
	add_to_cleanup => [
		'META.yml', '*.gz', 'Makefile.PL',
	],
);

$build->create_build_script;
