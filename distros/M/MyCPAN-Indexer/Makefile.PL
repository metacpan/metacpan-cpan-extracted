package MyCPAN::Indexer;
use strict;
use warnings;

=encoding utf8

=head1 The build file for MyCPAN::Indexer

This build file is a modulino; it works as both a build script and
a module.

To build the distribution, run this file normally:

	% perl Makefile.PL

But, it's more interesting than that. You can load it with C<require>
and call C<arguments> to get the data structure it passes to
C<WriteMakefile>:

	my $package = require '/path/to/Makefile.PL';
	my $arguments = $package->arguments;

Note that C<require>-ing a file makes an entry in C<%INC> for exactly
that name. If you try to C<require> another file with the same name,
even from a different path, C<require> thinks it has already loaded
the file. As such, I recommend you always require the full path to the
file.

The return value of the C<require> is a package name (in this case,
the name of the main module. Use that to call the C<arguments> method.

Even if this distribution needs a higher version of Perl, this bit
only needs v5.8. You can play with the data structure with a primitive
Perl.

=cut

my %optional = (
	Curses  => {
		'lib/MyCPAN/Indexer/Interface/Curses.pm' => '$(INST_LIBDIR)/Indexer/Interface/Curses.pm',

		},
	Tk      => {
		'lib/MyCPAN/Indexer/Interface/Tk.pm' => '$(INST_LIBDIR)/Indexer/Interface/Tk.pm',
		},
	);

foreach my $module ( keys %optional ) {
	my $available = eval "require $module; 1";

	unless( $available ) {
		print <<"HERE";
$module not available. Skipping optional modules that use it.
If you later want to use it, you'll have to reinstall MyCPAN.
HERE

		delete $optional{ $module };
		}
	}

use File::Spec::Functions qw(catfile);

my $module    = __PACKAGE__;
( my $dist = $module ) =~ s/::/-/g;

my $github    = 'https://github.com/briandfoy/mycpan-indexer';
my $main_file = catfile( 'lib', split /::/, "$module.pm" );

my %WriteMakefile = (
	'MIN_PERL_VERSION' => '5.014002',

	'NAME'	        => $module,
	'ABSTRACT_FROM' => $main_file,
	'VERSION_FROM'  => $main_file,
	'LICENSE'       => 'artistic_2',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',

	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker'   => '6.64',
		'File::Spec::Functions' => '0',
		},

	'BUILD_REQUIRES' => {
		},

	'TEST_REQUIRES' => {
		'Test::More'   => '1',
		'Test::Output' => '0.13',
		},

	'PREREQ_PM'    => {
		'Archive::Zip'                     => '0',
		'Archive::Extract::Libarchive'     => '0',
		'ConfigReader::Simple'             => '0',
		'CPAN::Checksums'                  => '0',
		'CPAN::PackageDetails'             => '0.21',
		'Data::Structure::Util'            => '0',
		'Data::UUID'                       => '0',
		'Digest::MD5'                      => '0',
		'Distribution::Guess::BuildSystem' => '0.11',
		'ExtUtils::MakeMaker'              => '6.48',
		'File::Find::Closures'             => '0',
		'File::Find'                       => '0',
		'File::Which'                      => '0',
		'List::Util'                       => '0',
		'Log::Log4perl'                    => '0',
		'Module::Extract::Namespaces'      => '0.14',
		'Module::Extract::Use'             => '0.13',
		'Module::Extract::VERSION'         => '0.13',
		'Parallel::ForkManager'            => '0',
		'Probe::Perl'                      => '0',
		'Proc::ProcessTable'               => '0',
		'YAML::Syck'                       => '0',
		'YAML::XS'                         => '0',
		'YAML'                             => '0',
		},

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => "$github.git",
				web  => $github,
				},
			bugtracker => {
				web    => "$github/issues",
				},
			homepage => $github,
			},
		no_index => {
			directory => [ qw(t inc corpus test-corpus) ],
			},
		},

	clean => { FILES => "$dist-*" },
	);

sub arguments { \%WriteMakefile }

do_it() unless caller;
sub do_it {
	require File::Spec;
	my $MM ='ExtUtils::MakeMaker';
	my $MM_version =
		eval{ "$MM " . $WriteMakefile{'CONFIGURE_REQUIRES'}{'ExtUtils::MakeMaker'} }
			||
		"$MM 6.64";
	eval "use $MM_version; 1" or die "Could not load $MM_version: $@";
	eval "use Test::Manifest 1.21"
		if -e File::Spec->catfile( qw(t test_manifest) );

	my $arguments = arguments();
	my $minimum_perl = $arguments->{MIN_PERL_VERSION} || '5.008';
	eval "require $minimum_perl;" or die $@;

	WriteMakefile( %$arguments );
	}


no warnings;
__PACKAGE__;
