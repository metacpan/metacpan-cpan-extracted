use strict;
use warnings;
use Module::Build;
my $build = Module::Build->new(
	module_name => 'Net::GNUDBSearch',
	license => 'perl',
	dist_author => 'MacGyveR <dumb@cpan.org>',
	dist_abstract => 'Search interface to GNUDB database',
	requires => {
		'WWW::Mechanize' => 0,
		'URI::Encode' => 0,
		'XML::Simple' => 0,
		'Data::Dumper' => 0,
		'Carp' => 0,
		'Net::FreeDB2' => 0
	},
	build_requires => {
		"Test::More" => 0
	},
	create_makefile_pl => 'traditional',
	meta_merge => {
		resources => {
			repository => 'https://github.com/thedumbterminal/Net-GNUDBSearch'
		}
	}
);
$build->create_build_script;
