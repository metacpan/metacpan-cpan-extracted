use strict;
use warnings;
use FindBin qw/$Bin/;
use local::lib "$Bin/local";
use Module::Build::Pluggable (
	'CPANfile'
);
my $build = Module::Build::Pluggable->new(
	module_name => 'Plack::App::WebMySQL',
	license => 'perl',
	dist_author => 'MacGyveR <dumb@cpan.org>',
	dist_abstract => 'WebMySQL web application',
	create_makefile_pl => 'traditional',
	share_dir => 'share',
	meta_merge => {
		resources => {
			repository => 'https://github.com/thedumbterminal/Plack-App-WebMySQL'
		}
	}
);
$build->create_build_script;
