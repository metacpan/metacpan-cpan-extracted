use strict;
use warnings;
use Module::Build;

#
# This file contains information distilled from lib/Net/Wire10.pm into
# a much more concise form by an automated tool.  From here, you can
# use Module::Build to create additional files containing secondary,
# tertiary and quaternary versions of the exact same information.
#
# First, create the Build script and _build cache:
#
# $ perl Build.PL
#
# (Notice that above, a script named "Build.PL" is used, while
#  below a different script named "Build" is used.)
#
# Then choose an action from this list:
#
# $ perl Build help
#
# Common actions are "help", "test" and "install".
#
# Notice that the install action does not take care of dependencies.
# Use the CPAN module installer for that.
#
# Other common actions are "manifest" for creating a dumb list of files
# and "distmeta" for duplicating the contents of the build cache into
# yet another mimeographic labor-phlebotomiser of a file format :-).
#

my $builder = Module::Build->new(
	module_name             => 'Net::Wire10',
	license                 => 'perl',
	dist_version_from       => 'lib/Net/Wire10.pm',
	build_requires => {
		'Test::More'             => 0.0,
	},
	requires => {
		'Digest::SHA::PurePerl'  => 0.0,
		'Encode'                 => 0.0,
		'Exporter'               => 0.0,
		'IO::Socket'             => 0.0,
		'IO::Select'             => 0.0,
		'utf8'                   => 0.0,
	},
	recommends => {
		'Digest::SHA1'           => 0.0,
	},
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
