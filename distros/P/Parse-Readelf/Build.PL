use strict;
use warnings;

use Module::Build;

# perldoc Module::Build::Cookbook, Module::Build::Authoring and
# Module::Build::API for details of how to influence the contents of
# the generated files.

my $build = Module::Build->new
    (
     module_name => 'Parse::Readelf',
     # finds $VERSION, abstract in "=head1 NAME", should also find
     # author in "=head1 AUTHOR":
     dist_version_from => 'lib/Parse/Readelf.pm',
     dist_author => 'Thomas Dorner, E<lt>dorner (AT) cpan.orgE<gt>',
     license => 'perl',
     create_readme => 0,
     create_makefile_pl => 'traditional',
     requires => { 'perl' => '5.6.1',
		   'Carp' => 0,
		   'File::Spec' => 0,
		   'Test::More' => 0
		 },
     auto_configure_requires => 0,
     # FIXME: add dependency to readelf!
     recommends => { 'File::Temp' => 0,
		     'Test::Pod' => 0,
		     'Test::Pod::Coverage' => 0
		   },
     # FIXME: add "example dependency" to gcc!
    );

$build->create_build_script;
