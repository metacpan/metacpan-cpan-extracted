package Perl::Dist::Inno;

=pod

=head1 NAME

Perl::Dist::Inno - 3rd Generation Distribution Builder using Inno Setup

=head1 SYNOPSIS

Creating a custom distribution

  package My::Perl::Dist;
  
  use strict;
  use base 'Perl::Dist::Strawberry';
  
  1;

Building that distribution...

  > perldist --cpan "file://c|/minicpan/" Strawberry

=head1 DESCRIPTION

B<Perl::Dist::Inno> is a Win32 Perl distribution builder that targets
the Inno Setup 5 installer creation program.

It provides a rich set of functionality that allows a distribution
developer to specify either Perl 5.8.8 or Perl 5.10.0, specify
additional C libraries and CPAN modules to be installed, and then
set start menu entries to websites and programs as needed.

A distribution directory and a matching .iss script is
generated, which is then handed off to Inno Setup 5 to create the
final distribution .exe installer.

Alternatively, B<Perl::Dist::Inno> can generate a .zip file for
the distribution without the installer.

Because the API for B<Perl::Dist::Inno> is extremely rich and fairly
complex (and a moving target) the documentation is unfortunately
a bit less complete than it should be.

As parts of the API solidify I hope to document them better.

=head2 API Structure

The L<Perl::Dist::Inno> API is separated into 2 layers, and a series
of objects.

L<Perl::Dist::Inno::Script> provides the direct mapping to the Inno
Setup 5 .iss script, and has no logical understand of Perl Distribution.

It stores the values that will ultimately be written into the .iss
files as attributes, and contains a series of collections of
L<Perl::Dist::Inno::File>, L<Perl::Dist::Inno::Registry> and
L>Perl::Dist::Inno::Icon> objects, which map directly to entries
in the .iss script's [Files], [Icons] and [Registry] sections.

To the extent that it does interact with actual distributions, it is
only to the extent of validating some directories exist, and
triggering the actual execution of the Inno Setup 5 compiler.

B<Perl::Dist::Inno> (this class) is a sub-class of
L<Perl::Dist::Inno::Script> and represents the layer at which
the understanding of the Perl distribution itself is implemented.

L<Perl::Dist::Asset> and its various subclasses provides the internal
representation of the logical elements of a Perl distribution.

These assets are mostly transient and are destroyed once the asset
has been added to the distribution (this may change).

In the process of adding the asset to the distribution, various
files may be created and objects added to the script object that
will result in .iss keys being created where the installer builder
needs to know about that asset explicitly.

L<Perl::Dist::Inno> itself provides both many levels of abstraction
with sensible default implementations of high level concept methods,
as well as multiple levels of submethods.

Strong separation of concerns in this manner allows people creating
distribution sub-classes to add hooks to the build process in many
places, for maximum customisability.

The main Perl::Dist::Inno B<run> method implements the basic flow
for the creation of a Perl distribution. The order is rougly as
follows:

=over 4

=item 1. Install a C toolchain

=item 2. Install additional C libraries

=item 3. Install Perl itself

=item 4. Install/Upgrade the CPAN toolchain

=item 5. Install additional CPAN modules

=item 6. Optionally install Portability support

=item 7. Install Win32-specific things such as start menu entries

=item 8. Remove any files we don't need in the final distribution

=item 9. Generate the zip, exe or msi files.

=back

=head2 Creating Your Own Distribution

Rather than building directly on top of Perl::Dist::Inno, it is probably
better to build on top of a particular distribution, probably Strawberry.

For more information, see the L<Perl::Dist::Strawberry> documentation
which details how to sub-class the distribution.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;
use Carp                            ();
use Archive::Tar               1.42 ();
use Archive::Zip               1.26 ();
use File::Temp                 0.21 ();
use File::Spec                 3.29 ();
use File::Spec::Unix                ();
use File::Spec::Win32               ();
use File::Copy                      ();
use File::Copy::Recursive      0.38 ();
use File::Path                 2.07 ();
use File::PathList             1.04 ();
use File::pushd                1.00 ();
use File::Remove               1.42 ();
use File::HomeDir              0.82 ();
use File::Basename                  ();
use File::ShareDir             1.00 ();
use File::Find::Rule           0.30 ();
use IPC::Run3                 0.042 ();
use YAML::Tiny                 1.36 ();
use IO::Capture                0.05 ();
use Params::Util               0.35 ();
use HTTP::Status              5.817 ();
use LWP::UserAgent            5.823 ();
use LWP::UserAgent::WithCache  0.06 ();
use LWP::Online                1.07 ();
use Module::CoreList           2.17 ();
use Template                   2.20 ();
use PAR::Dist                  0.42 ();
use Portable::Dist             0.02 ();
use Storable                   2.17 ();
use URI::file                  1.37 ();
use Probe::Perl                0.01 ();
use Process                    0.25 ();
use Process::Storable          0.25 ();
use Process::Delegatable       0.25 ();
use Perl::Dist::Asset               ();
use Perl::Dist::Asset::Binary       ();
use Perl::Dist::Asset::Library      ();
use Perl::Dist::Asset::Perl         ();
use Perl::Dist::Asset::Distribution ();
use Perl::Dist::Asset::Module       ();
use Perl::Dist::Asset::PAR          ();
use Perl::Dist::Asset::File         ();
use Perl::Dist::Asset::Website      ();
use Perl::Dist::Asset::Launcher     ();
use Perl::Dist::Inno::Script        ();
use Perl::Dist::Util::Toolchain     ();

use vars qw{$VERSION @ISA};
BEGIN {
        $VERSION  = '1.16';
	@ISA      = 'Perl::Dist::Inno::Script';
}

use Object::Tiny 1.06 qw{
	perl_version
	portable
	archlib
	exe
	zip
	binary_root
	offline
	temp_dir
	download_dir
	image_dir
	modules_dir
	license_dir
	build_dir
	checkpoint_dir
	iss_file
	bin_perl
	bin_make
	bin_pexports
	bin_dlltool
	env_path
	debug_stdout
	debug_stderr
	output_file
	perl_version_corelist
	cpan
	force
	checkpoint_before
	checkpoint_after
};





#####################################################################
# Upstream Binary Packages (Mirrored)

my %PACKAGES = (
	'dmake'         => 'dmake-4.8-20070327-SHAY.zip',
	'gcc-core'      => 'gcc-core-3.4.5-20060117-3.tar.gz',
	'gcc-g++'       => 'gcc-g++-3.4.5-20060117-3.tar.gz',
	'mingw-make'    => 'mingw32-make-3.81-2.tar.gz',
	'binutils'      => 'binutils-2.17.50-20060824-1.tar.gz',
	'mingw-runtime' => 'mingw-runtime-3.13.tar.gz',
	'w32api'        => 'w32api-3.10.tar.gz',
	'libiconv-dep'  => 'libiconv-1.9.2-1-dep.zip',
	'libiconv-lib'  => 'libiconv-1.9.2-1-lib.zip',
	'libiconv-bin'  => 'libiconv-1.9.2-1-bin.zip',
	'expat'         => 'expat-2.0.1-vanilla.zip',
	'gmp'           => 'gmp-4.2.1-vanilla.zip',
);

sub binary_file {
	unless ( $PACKAGES{$_[1]} ) {
		Carp::croak("Unknown package '$_[1]'");
	}
	return $PACKAGES{$_[1]};
}

sub binary_url {
	my $self = shift;
	my $file = shift;
	unless ( $file =~ /\.(zip|gz|tgz)$/i ) {
		# Shorthand, map to full file name
		$file = $self->binary_file($file, @_);
	}
	return $self->binary_root . '/' . $file;
}





#####################################################################
# Constructor

=pod

=head2 new

The B<new> method creates a new Perl Distribution build as an object.

Each object is used to create a single distribution, and then should be
discarded.

Although there are about 30 potential constructor arguments that can be
provided, most of them are automatically resolved and exist for overloading
puposes only, or they revert to sensible default and generally never need
to be modified.

The following is an example of the most likely attributes that will be
specified.

  my $build = Perl::Dist::Inno->new(
      image_dir => 'C:\vanilla',
      temp_dir  => 'C:\tmp\vp',
      cpan      => 'file://C|/minicpan/',
  );

=over 4

=item image_dir

Perl::Dist::Inno distributions can only be installed to fixed paths.

To facilitate a correctly working CPAN setup, the files that will
ultimately end up in the installer must also be assembled under the
same path on the author's machine.

The C<image_dir> method specifies the location of the Perl install,
both on the author's and end-user's host.

Please note that this directory will be automatically deleted if it
already exists at object creation time. Trying to build a Perl
distribution on the SAME distribution can thus have devestating
results.

=item temp_dir

B<Perl::Dist::Inno> needs a series of temporary directories while
it is running the build, including places to cache downloaded files,
somewhere to expand tarballs to build things, and somewhere to put
debugging output and the final installer zip and exe files.

The C<temp_dir> param specifies the root path for where these
temporary directories should be created.

For convenience it is best to make these short paths with simple
names, near the root.

=item cpan

The C<cpan> param provides a path to a CPAN or minicpan mirror that
the installer can use to fetch any needed files during the build
process.

The param should be a L<URI> object to the root of the CPAN repository,
including trailing newline.

If you are online and no C<cpan> param is provided, the value will
default to the L<http://cpan.strawberryperl.com> repository as a
convenience.

=item portable

The optional boolean C<portable> param is used to indicate that the
distribution is intended for installation on a portable storable
device.

=item exe

The optional boolean C<zip> param is used to indicate that a zip
distribution package should be created.

=item zip

The optional boolean C<exe> param is used to indicate that an
InnoSetup executable installer should be created.

=back

The C<new> constructor returns a B<Perl::Dist> object, which you
should then call C<run> on to generate the distribution.

=cut

sub new {
	my $class  = shift;
	my %params = @_;

	# Apply some defaults
	unless ( defined $params{binary_root} ) {
		$params{binary_root} = 'http://strawberryperl.com/package';
	}
	if ( defined $params{image_dir} and ! defined $params{default_dir_name} ) {
		$params{default_dir_name} = $params{image_dir};
	}
	unless ( defined $params{temp_dir} ) {
		$params{temp_dir} = File::Spec->catdir(
			File::Spec->tmpdir, 'perldist',
		);
	}
	unless ( defined $params{download_dir} ) {
		$params{download_dir} = File::Spec->catdir(
			$params{temp_dir}, 'download',
		);
		File::Path::mkpath($params{download_dir});
	}
	unless ( defined $params{build_dir} ) {
		$params{build_dir} = File::Spec->catdir(
			$params{temp_dir}, 'build',
		);
		$class->remake_path( $params{build_dir} );
	}
	unless ( defined $params{output_dir} ) {
		$params{output_dir} = File::Spec->catdir(
			$params{temp_dir}, 'output',
		);
		$class->remake_path( $params{output_dir} );
	}
	if ( defined $params{image_dir} ) {
		$class->remake_path( $params{image_dir} );
	}
	unless ( defined $params{perl_version} ) {
		$params{perl_version} = '5100';
	}

	# Hand off to the parent class
	my $self = $class->SUPER::new(%params);

	# Check the version of Perl to build
	unless ( $self->perl_version_literal ) {
		Carp::croak "Failed to resolve perl_version_literal";
	}
	unless ( $self->perl_version_human ) {
		Carp::croak "Failed to resolve perl_version_human";
	}
	unless ( $self->can('install_perl_' . $self->perl_version) ) {
		Carp::croak("$class does not support Perl " . $self->perl_version);
	}

	# Find the core list
	my $corelist_version = $self->perl_version_literal+0;
	$self->{perl_version_corelist} = $Module::CoreList::version{$corelist_version};
	unless ( Params::Util::_HASH($self->{perl_version_corelist}) ) {
		Carp::croak("Failed to resolve Module::CoreList hash for " . $self->perl_version_human);
	}

        # Apply more defaults
	unless ( defined $self->{force} ) {
		$self->{force} = 0;
	}
	unless ( defined $self->{trace} ) {
		$self->{trace} = 1;
	}
	unless ( defined $self->debug_stdout ) {
		$self->{debug_stdout} = File::Spec->catfile(
			$self->output_dir,
			'debug.out',
		);
	}
	unless ( defined $self->debug_stderr ) {
		$self->{debug_stderr} = File::Spec->catfile(
			$self->output_dir,
			'debug.err',
		);
	}

	# Auto-detect online-ness if needed
	unless ( defined $self->offline ) {
		$self->{offline} = LWP::Online::offline();
	}
	unless ( defined $self->exe ) {
		$self->{exe} = 1;
	}
	unless ( defined $self->zip ) {
		$self->{zip} = $self->portable ? 1 : 0;
	}
	unless ( defined $self->checkpoint_before ) {
		$self->{checkpoint_before} = 0;
	}
	unless ( defined $self->checkpoint_after ) {
		$self->{checkpoint_after} = 0;
	}

	# Normalize some params
	$self->{offline}      = !! $self->offline;
	$self->{trace}        = !! $self->{trace};
	$self->{force}        = !! $self->force;
	$self->{portable}     = !! $self->portable;
	$self->{exe}          = !! $self->exe;
	$self->{zip}          = !! $self->zip;
	$self->{archlib}      = !! $self->archlib;

	# Handle portable special cases
	if ( $self->portable ) {
		$self->{exe} = 0;
	}

	# If we are online and don't have a cpan repository,
	# use cpan.strawberryperl.com as a default.
	if ( ! $self->offline and ! $self->cpan ) {
		$self->{cpan} = URI->new('http://cpan.strawberryperl.com/');
	}

	# Check params
	unless ( Params::Util::_STRING($self->download_dir) ) {
		Carp::croak("Missing or invalid download_dir param");
	}
	unless ( defined $self->modules_dir ) {
		$self->{modules_dir} = File::Spec->catdir( $self->download_dir, 'modules' );
	}
	unless ( Params::Util::_STRING($self->modules_dir) ) {
		Carp::croak("Invalid modules_dir param");
	}
	unless ( Params::Util::_STRING($self->image_dir) ) {
		Carp::croak("Missing or invalid image_dir param");
	}
	if ( $self->image_dir =~ /\s/ ) {
		Carp::croak("Spaces are not allowed in image_dir");
	}
	unless ( defined $self->license_dir ) {
		$self->{license_dir} = File::Spec->catdir( $self->image_dir, 'licenses' );
	}
	unless ( Params::Util::_STRING($self->license_dir) ) {
		Carp::croak("Invalid license_dir param");
	}
	unless ( Params::Util::_STRING($self->build_dir) ) {
		Carp::croak("Missing or invalid build_dir param");
	}
	if ( $self->build_dir =~ /\s/ ) {
		Carp::croak("Spaces are not allowed in build_dir");
	}
	unless ( Params::Util::_INSTANCE($self->user_agent, 'LWP::UserAgent') ) {
		Carp::croak("Missing or invalid user_agent param");
	}
	unless ( Params::Util::_INSTANCE($self->cpan, 'URI') ) {
		Carp::croak("Missing or invalid cpan param");
	}
	unless ( $self->cpan->as_string =~ /\/$/ ) {
		Carp::croak("Missing trailing slash in cpan param");
	}
	unless ( defined $self->iss_file ) {
		$self->{iss_file} = File::Spec->catfile(
			$self->output_dir, $self->app_id . '.iss'
		);
	}

	# Clear the previous build
	if ( -d $self->image_dir ) {
		$self->trace("Removing previous " . $self->image_dir . "\n");
		File::Remove::remove( \1, $self->image_dir );
	} else {
		$self->trace("No previous " . $self->image_dir . " found\n");
	}

	# Initialize the build
	for my $d (
		$self->download_dir,
		$self->image_dir,
		$self->modules_dir,
		$self->license_dir,
	) {
		next if -d $d;
		File::Path::mkpath($d);
	}

	# More details on the tracing
	if ( $self->{trace} ) {
		$self->{stdout} = undef;
		$self->{stderr} = undef;
	} else {
		$self->{stdout} = \undef;
		$self->{stderr} = \undef;
	}

	# Inno-Setup Initialization
	$self->{env_path}    = [];
	$self->add_dir('c');
	$self->add_dir('perl');
	$self->add_dir('licenses');
	$self->add_uninstall;

	# Set some common environment variables
	$self->add_env( TERM        => 'dumb' );
	$self->add_env( FTP_PASSIVE => 1      );

	# Initialize the output valuse
	$self->{output_file} = [];

        return $self;
}

=pod

=head2 offline

The B<Perl::Dist> module has limited ability to build offline, if all
packages have already been downloaded and cached.

The connectedness of the Perl::Dist object is checked automatically
be default using L<LWP::Online>. It can be overidden by providing an
offline param to the constructor.

The C<offline> accessor returns true if no connection to "the internet"
is available and the object will run in offline mode, or false
otherwise.

=head2 download_dir

The C<download_dir> accessor returns the path to the directory that
packages of various types will be downloaded and cached to.

An explicit value can be provided via a C<download_dir> param to the
constructor. Otherwise the value is derived from C<temp_dir>.

=head2 image_dir

The C<image_dir> accessor returns the path to the built distribution
image. That is, the directory in which the build C/Perl code and
modules will be installed on the build server.

At the present time, this is also the path to which Perl will be
installed on the user's machine via the C<source_dir> accessor,
which is an alias to the L<Perl::Dist::Inno::Script> method
C<source_dir>. (although theoretically they can be different,
this is likely to break the user's Perl install)

=cut





#####################################################################
# Checkpoint Support

sub checkpoint_task {
	my $self = shift;
	my $task = shift;
	my $step = shift;

	# Are we loading at this step?
	if ( $self->checkpoint_before == $step ) {
		$self->checkpoint_load;
	}

	# Skip if we are loading later on
	unless ( $self->checkpoint_before > $step ) {
		my $t = time;
		$self->$task();
		$self->trace("Completed $task in " . (time - $t) . " seconds\n");
	}

	# Are we saving at this step
	if ( $self->checkpoint_after == $step ) {
		$self->checkpoint_save;
	}

	return $self;
}

sub checkpoint_file {
	File::Spec->catfile( $_[0]->checkpoint_dir, 'self.dat' );
}

sub checkpoint_self {
	die "CODE INCOMPLETE";
}

sub checkpoint_save {
	my $self = shift;
	unless ( $self->temp_dir ) {
		die "Checkpoints require a temp_dir to be set";
	}

	# Clear out any existing checkpoint
	$self->trace("Removing old checkpoint\n");
	$self->{checkpoint_dir} = File::Spec->catfile(
		$self->temp_dir, 'checkpoint',
	);
	$self->remake_path( $self->checkpoint_dir );

	# Copy the paths into the checkpoint directory
	$self->trace("Copying checkpoint directories...\n");
	foreach my $dir ( qw{ build_dir download_dir image_dir output_dir } ) {
		my $from = $self->$dir();
		my $to   = File::Spec->catdir( $self->checkpoint_dir, $dir );
		$self->_copy( $from => $to );
	}

	# Store the main object.
	# Blank the checkpoint values to prevent load/save loops, and remove
	# things we can recreate later.
	my $copy = {
		%$self,
		checkpoint_before => 0,
		checkpoint_after  => 0,
		user_agent        => undef,
	};
	Storable::nstore( $copy, $self->checkpoint_file );

	return 1;
}

sub checkpoint_load {
	my $self = shift;
	unless ( $self->temp_dir ) {
		die "Checkpoints require a temp_dir to be set";
	}

	# Does the checkpoint exist
	$self->trace("Removing old checkpoint\n");
	$self->{checkpoint_dir} = File::Spec->catfile(
		$self->temp_dir, 'checkpoint',
	);
	unless ( -d $self->checkpoint_dir ) {
		die "Failed to find checkpoint directory";
	}

	# Load the stored hash over our object
	my $stored = Storable::retrieve( $self->checkpoint_file );
	%$self = %$stored;

	# Pull all the directories out of the storage
	$self->trace("Restoring checkpoint directories...\n");
	foreach my $dir ( qw{ build_dir download_dir image_dir output_dir } ) {
		my $from = File::Spec->catdir( $self->checkpoint_dir, $dir );
		my $to   = $self->$dir();
		File::Remove::remove( $to );
		$self->_copy( $from => $to );
	}

	return 1;
}





#####################################################################
# Perl::Dist::Inno::Script Methods

sub source_dir {
	$_[0]->image_dir;
}

# Default the versioned name to an unversioned name
sub app_ver_name {
	my $self = shift;
	if ( $self->{app_ver_name} ) {
		return $self->{app_ver_name};
	}
	return $self->app_name . ' ' . $self->perl_version_human;
}

# Default the output filename to the id plus the current date
sub output_base_filename {
	my $self = shift;
	if ( $self->{output_base_filename} ) {
		return $self->{output_base_filename};
	}
	return $self->app_id
	     . '-' . $self->perl_version_human
	     . '-' . $self->output_date_string;
}





#####################################################################
# Perl::Dist::Inno Main Methods

=pod

=head2 perl_version

The C<perl_version> accessor returns the shorthand perl version
as a string (consisting of the three-part version with dots
removed).

Thus Perl 5.8.8 will be "588" and Perl 5.10.0 will return "5100".

=head2 perl_version_literal

The C<perl_version_literal> method returns the literal numeric Perl
version for the distribution.

For Perl 5.8.8 this will be '5.008008', Perl 5.8.9 will be '5.008009',
and for Perl 5.10.0 this will be '5.010000'.

=cut

sub perl_version_literal {
	return {
		588  => '5.008008',
		589  => '5.008009',
		5100 => '5.010000',
	}->{$_[0]->perl_version} || 0;
}

=pod

=head2 perl_version_human

The C<perl_version_human> method returns the "marketing" form
of the Perl version.

This will be either '5.8.8', '5.8.9' or '5.10.0'.

=cut

sub perl_version_human {
	return {
		588  => '5.8.8',
		589  => '5.8.9',
		5100 => '5.10.0',
	}->{$_[0]->perl_version} || 0;
}





#####################################################################
# Top Level Process Methods

sub prepare { 1 }

=pod

=head1 run

The C<run> method is the main method for the class.

It does a complete build of a product, spitting out an installer.

Returns true, or throws an exception on error.

This method may take an hour or more to run.

=cut

sub run {
	my $self  = shift;
	my $start = time;

	unless ( $self->exe or $self->zip ) {
		$self->trace("No exe or zip target, nothing to do");
		return 1;
	}

	# Don't buffer
	$| = 1;

	# Install the core C toolchain
	$self->checkpoint_task( install_c_toolchain  => 1 );

	# Install any additional C libraries
	$self->checkpoint_task( install_c_libraries  => 2 );

	# Install the Perl binary
	$self->checkpoint_task( install_perl         => 3 );

	# Install additional Perl modules
	$self->checkpoint_task( install_perl_modules => 4 );

	# Install the Win32 extras
	$self->checkpoint_task( install_win32_extras => 5 );

	# Apply optional portability support
	$self->checkpoint_task( install_portable     => 6 ) if $self->portable;

	# Remove waste and temporary files
	$self->checkpoint_task( remove_waste         => 7 );

	# Install any extra custom non-Perl software on top of Perl.
	# This is primarily added for the benefit of Parrot.
	$self->checkpoint_task( install_custom       => 8 );

	# Write out the distributions
	$self->checkpoint_task( write                => 9 );

	# Finished
	$self->trace(
		"Distribution generation completed in "
		. (time - $start)
		. " seconds\n"
	);
	foreach my $file ( @{$self->output_file} ) {
		$self->trace("Created distribution $file\n");
	}

	return 1;
}

=pod

=head2 install_custom

The C<install_custom> method is an empty install stub provided
to allow sub-classed distributions to add B<vastly> different
additional packages on top of Strawberry Perl.

For example, this class is used by the Parrot distribution builder
(which needs to sit on a full Strawberry install).

Notably, the C<install_custom> method AFTER C<remove_waste>, so that the
file deletion logic in C<remove_waste> won't accidntally delete files that
may result in a vastly more damaging effect on the custom software.

Returns true, or throws an error on exception.

=cut

sub install_custom {
	return 1;
}

=pod

=head2 install_c_toolchain

The C<install_c_toolchain> method is used by C<run> to install various
binary packages to provide a working C development environment.

By default, the C toolchain consists of dmake, gcc (C/C++), binutils,
pexports, the mingw runtime environment, and the win32api C package.

Although dmake is the "standard" make for Perl::Dist distributions,
it will also install...

TO BE CONTINUED

=cut

# Install the required toolchain elements.
# We use separate methods for each tool to make
# it easier for individual distributions to customize
# the versions of tools they incorporate.
sub install_c_toolchain {
	my $self = shift;

	# The primary make
	$self->install_dmake;

	# Core compiler
	$self->install_gcc;

	# C Utilities
	$self->install_mingw_make;
	$self->install_binutils;
	$self->install_pexports;

	# Install support libraries
	$self->install_mingw_runtime;
	$self->install_win32api;

	# Set up the environment variables for the binaries
	$self->add_env_path( 'c', 'bin' );

	return 1;
}

# No additional modules by default
sub install_c_libraries {
	my $class = shift;
	if ( $class eq __PACKAGE__ ) {
		$class->trace("install_c_libraries: Nothing to do\n");
	}
	return 1;
}

# Install Perl 5.10.0 by default.
# Just hand off to the larger set of Perl install methods.
sub install_perl {
	my $self = shift;
	my $install_perl_method = "install_perl_" . $self->perl_version;
	unless ( $self->can($install_perl_method) ) {
		Carp::croak("Cannot generate perl, missing $install_perl_method method in " . ref($self));
	}
	$self->$install_perl_method(@_);
}

sub install_perl_toolchain {
	my $self      = shift;
	my $toolchain = @_
		? Params::Util::_INSTANCE($_[0], 'Perl::Dist::Util::Toolchain')
		: Perl::Dist::Util::Toolchain->new(
			perl_version => $self->perl_version_literal,
		);
	unless ( $toolchain ) {
		die("Did not provide a toolchain resolver");
	}

	# Get the regular Perl to generate the list.
	# Run it in a separate process so we don't hold
	# any permanent CPAN.pm locks.
	$toolchain->delegate;
	if ( $toolchain->{errstr} ) {
		die("Failed to generate toolchain distributions");
	}

	# Install the toolchain dists
	foreach my $dist ( @{$toolchain->{dists}} ) {
		my $automated_testing = 0;
		my $release_testing   = 0;
		my $force             = $self->force;
		if ( $dist =~ /Scalar-List-Util/ ) {
			# Does something weird with tainting
			$force = 1;
		}
		if ( $dist =~ /URI-/ ) {
			# Can't rely on t/heuristic.t not finding a www.perl.bv
			# because some ISP's use DNS redirectors for unfindable
			# sites.
			$force = 1;
 	 	}
		if ( $dist =~ /Term-ReadLine-Perl/ ) {
			# Does evil things when testing, and
			# so testing cannot be automated.
			$automated_testing = 1;
		}
		$self->install_distribution(
			name              => $dist,
			force             => $force,
			automated_testing => $automated_testing,
			release_testing   => $release_testing,
		);
	}

	return 1;
}

sub install_cpan_upgrades {
	my $self = shift;
	unless ( $self->bin_perl ) {
		Carp::croak("Cannot install CPAN modules yet, perl is not installed");
	}

	# Generate the CPAN installation script
	my $cpan_string = <<"END_PERL";
print "Loading CPAN...\\n";
use CPAN;
CPAN::HandleConfig->load unless \$CPAN::Config_loaded++;
print "Upgrading all out of date CPAN modules...\\n";
print "\\\$ENV{PATH} = '\$ENV{PATH}'\\n";
CPAN::Shell->upgrade;
print "Completed upgrade of all modules\\n";
exit(0);
END_PERL

	# Dump the CPAN script to a temp file and execute
	$self->trace("Running upgrade of all modules\n");
	my $cpan_file = File::Spec->catfile(
		$self->build_dir,
		'cpan_string.pl',
	);
	SCOPE: {
		open( CPAN_FILE, '>', $cpan_file )  or die "open: $!";
		print CPAN_FILE $cpan_string        or die "print: $!";
		close( CPAN_FILE )                  or die "close: $!";
	}
	local $ENV{PERL_MM_USE_DEFAULT} = 1;
	local $ENV{AUTOMATED_TESTING}   = '';
	local $ENV{RELEASE_TESTING}     = '';
	$self->_run3( $self->bin_perl, $cpan_file ) or die "perl failed";
	die "Failure detected during cpan upgrade, stopping" if $?;

	return 1;
}

# No additional modules by default
sub install_perl_modules {
	my $self = shift;

	# Upgrade anything out of date,
	# but don't install anything extra.
	$self->install_cpan_upgrades;

	return 1;
}

# Portability support must be added after modules
sub install_portable {
	my $self = shift;

	# Install the regular parts of Portability
	$self->install_module(
		name => 'Portable',
	);

	# Create the portability object
	$self->trace("Creating Portable::Dist\n");
	$self->{portable_dist} = Portable::Dist->new(
		perl_root => File::Spec->catdir(
			$self->image_dir => 'perl',
		),
	);
	$self->trace("Running Portable::Dist\n");
	$self->{portable_dist}->run;
	$self->trace("Completed Portable::Dist\n");

	# Install the file that turns on Portability last
	$self->install_file(
		share      => 'Perl-Dist portable.perl',
		install_to => 'portable.perl',
	);

	return 1;
}

# Install links and launchers and so on
sub install_win32_extras {
	my $self = shift;

	$self->install_launcher(
		name => 'CPAN Client',
		bin  => 'cpan',
	);
	$self->install_website(
		name => 'CPAN Search',
		url  => 'http://search.cpan.org/',
	);

	if ( $self->perl_version_human eq '5.8.8' ) {
		$self->install_website(
			name => 'Perl 5.8.8 Documentation',
			url  => 'http://perldoc.perl.org/5.8.8/',
		);
	}
	if ( $self->perl_version_human eq '5.8.9' ) {
		$self->install_website(
			name => 'Perl 5.8.9 Documentation',
			url  => 'http://perldoc.perl.org/5.8.9/',
		);
	}
	if ( $self->perl_version_human eq '5.10.0' ) {
		$self->install_website(
			name => 'Perl 5.10.0 Documentation',
			url  => 'http://perldoc.perl.org/',
		);
	}

	$self->install_website(
		name => 'Win32 Perl Wiki',
		url  => 'http://win32.perl.org/',
	);

	return 1;
}

# Delete various stuff we won't be needing
sub remove_waste {
	my $self = shift;

	$self->trace("Removing doc, man, info and html documentation...\n");
	$self->remove_dir(qw{ perl man       });
	$self->remove_dir(qw{ perl html      });
	$self->remove_dir(qw{ c    man       });
	$self->remove_dir(qw{ c    doc       });
	$self->remove_dir(qw{ c    info      });
	$self->remove_dir(qw{ c    contrib   });
	$self->remove_dir(qw{ c    html      });

	$self->trace("Removing C examples, manifests...\n");
	$self->remove_dir(qw{ c    examples  });
	$self->remove_dir(qw{ c    manifest  });

	$self->trace("Removing redundant license files...\n");
	$self->remove_file(qw{ c COPYING     });
	$self->remove_file(qw{ c COPYING.LIB });

	$self->trace("Removing CPAN build directories and download caches...\n");
	$self->remove_dir(qw{ cpan sources  });
	$self->remove_dir(qw{ cpan build    });

	return 1;
}

sub remove_dir {
	my $self = shift;
	my $dir  = $self->dir( @_ );
	File::Remove::remove( \1, $dir ) if -e $dir;
	return 1;
}

sub remove_file {
	my $self = shift;
	my $file = $self->file( @_ );
	File::Remove::remove( \1, $file ) if -e $file;
	return 1;
}
		




#####################################################################
# Perl 5.8.8 Support

sub install_perl_588 {
	my $self = shift;

	# Prefetch and predelegate the toolchain so that it
	# fails early if there's a problem
	$self->trace("Pregenerating toolchain...\n");
	my $toolchain = Perl::Dist::Util::Toolchain->new(
		perl_version => $self->perl_version_literal,
	) or die("Failed to resolve toolchain modules");
	$toolchain->delegate;
	if ( $toolchain->{errstr} ) {
		die("Failed to generate toolchain distributions");
	}

	# Install the main perl distributions
	$self->install_perl_588_bin(
		name       => 'perl',
		url        => 'http://strawberryperl.com/package/perl-5.8.8.tar.gz',
		unpack_to  => 'perl',
		install_to => 'perl',
		patch      => [ qw{
			lib/ExtUtils/Install.pm
			lib/ExtUtils/Installed.pm
			lib/ExtUtils/Packlist.pm
			lib/ExtUtils/t/Install.t
			lib/ExtUtils/t/Installed.t
			lib/ExtUtils/t/Installapi2.t
			lib/ExtUtils/t/Packlist.t
			lib/ExtUtils/t/basic.t
			lib/ExtUtils/t/can_write_dir.t
			lib/CPAN/Config.pm
		} ],
		license    => {
			'perl-5.8.8/Readme'   => 'perl/Readme',
			'perl-5.8.8/Artistic' => 'perl/Artistic',
			'perl-5.8.8/Copying'  => 'perl/Copying',
		},
	);

	# Upgrade the toolchain modules
	$self->install_perl_toolchain( $toolchain );

	return 1;
}

sub install_perl_588_bin {
	my $self = shift;
	my $perl = Perl::Dist::Asset::Perl->new(
		parent => $self,
		force  => $self->force,
		@_,
	);
	unless ( $self->bin_make ) {
		Carp::croak("Cannot build Perl yet, no bin_make defined");
	}

	# Download the file
	my $tgz = $self->_mirror( 
		$perl->url,
		$self->download_dir,
	);

	# Unpack to the build directory
	my $unpack_to = File::Spec->catdir( $self->build_dir, $perl->unpack_to );
	if ( -d $unpack_to ) {
		$self->trace("Removing previous $unpack_to\n");
		File::Remove::remove( \1, $unpack_to );
	}
	$self->_extract( $tgz => $unpack_to );

	# Get the versioned name of the directory
	(my $perlsrc = $tgz) =~ s{\.tar\.gz\z|\.tgz\z}{};
	$perlsrc = File::Basename::basename($perlsrc);

	# Pre-copy updated files over the top of the source
	my $patch = $perl->patch;
	if ( $patch ) {
		# Overwrite the appropriate files
		foreach my $file ( @$patch ) {
			$self->patch_file( "perl-5.8.8/$file" => $unpack_to );
		}
	}

	# Copy in licenses
	if ( ref $perl->license eq 'HASH' ) {
		my $license_dir = File::Spec->catdir( $self->image_dir, 'licenses' );
		$self->_extract_filemap( $tgz, $perl->license, $license_dir, 1 );
	}

	# Build win32 perl
	SCOPE: {
		my $wd = $self->_pushd($unpack_to, $perlsrc , "win32" );

		# Prepare to patch
		my $image_dir  = $self->image_dir;
		my $INST_TOP   = File::Spec->catdir( $self->image_dir, $perl->install_to );
		my ($INST_DRV) = File::Spec->splitpath( $INST_TOP, 1 );

		$self->trace("Patching makefile.mk\n");
		$self->patch_file( 'perl-5.8.8/win32/makefile.mk' => $unpack_to, {
			dist     => $self,
			INST_DRV => $INST_DRV,
			INST_TOP => $INST_TOP,
		} );

		$self->trace("Building perl...\n");
		$self->_make;

		unless ( $perl->force ) {
			local $ENV{PERL_SKIP_TTY_TEST} = 1;
			$self->trace("Testing perl...\n");
			$self->_make('test');
		}

		$self->trace("Installing perl...\n");
		$self->_make( qw/install UNINST=1/ );
	}

	# Should now have a perl to use
	$self->{bin_perl} = File::Spec->catfile( $self->image_dir, qw/perl bin perl.exe/ );
	unless ( -x $self->bin_perl ) {
		Carp::croak("Can't execute " . $self->bin_perl);
	}

	# Add to the environment variables
	$self->add_env_path( 'perl', 'bin' );

	return 1;
}





#####################################################################
# Perl 5.8.9 Support

sub install_perl_589 {
	my $self = shift;

	# Prefetch and predelegate the toolchain so that it
	# fails early if there's a problem
	$self->trace("Pregenerating toolchain...\n");
	my $toolchain = Perl::Dist::Util::Toolchain->new(
		perl_version => $self->perl_version_literal,
	) or die("Failed to resolve toolchain modules");
	$toolchain->delegate;
	if ( $toolchain->{errstr} ) {
		die("Failed to generate toolchain distributions");
	}

	# Install the main perl distributions
	$self->install_perl_589_bin(
		name       => 'perl',
		url        => 'http://strawberryperl.com/package/perl-5.8.9.tar.gz',
		unpack_to  => 'perl',
		install_to => 'perl',
		patch      => [ qw{
			lib/CPAN/Config.pm
		} ],
		license    => {
			'perl-5.8.9/Readme'   => 'perl/Readme',
			'perl-5.8.9/Artistic' => 'perl/Artistic',
			'perl-5.8.9/Copying'  => 'perl/Copying',
		},
	);

	# Upgrade the toolchain modules
	$self->install_perl_toolchain( $toolchain );

	return 1;
}

sub install_perl_589_bin {
	my $self = shift;
	my $perl = Perl::Dist::Asset::Perl->new(
		parent => $self,
		force  => $self->force,
		@_,
	);
	unless ( $self->bin_make ) {
		Carp::croak("Cannot build Perl yet, no bin_make defined");
	}

	# Download the file
	my $tgz = $self->_mirror( 
		$perl->url,
		$self->download_dir,
	);

	# Unpack to the build directory
	my $unpack_to = File::Spec->catdir( $self->build_dir, $perl->unpack_to );
	if ( -d $unpack_to ) {
		$self->trace("Removing previous $unpack_to\n");
		File::Remove::remove( \1, $unpack_to );
	}
	$self->_extract( $tgz => $unpack_to );

	# Get the versioned name of the directory
	(my $perlsrc = $tgz) =~ s{\.tar\.gz\z|\.tgz\z}{};
	$perlsrc = File::Basename::basename($perlsrc);

	# Pre-copy updated files over the top of the source
	my $patch = $perl->patch;
	if ( $patch ) {
		# Overwrite the appropriate files
		foreach my $file ( @$patch ) {
			$self->patch_file( "perl-5.8.9/$file" => $unpack_to );
		}
	}

	# Copy in licenses
	if ( ref $perl->license eq 'HASH' ) {
		my $license_dir = File::Spec->catdir( $self->image_dir, 'licenses' );
		$self->_extract_filemap( $tgz, $perl->license, $license_dir, 1 );
	}

	# Build win32 perl
	SCOPE: {
		my $wd = $self->_pushd($unpack_to, $perlsrc , "win32" );

		# Prepare to patch
		my $image_dir  = $self->image_dir;
		my $INST_TOP   = File::Spec->catdir( $self->image_dir, $perl->install_to );
		my ($INST_DRV) = File::Spec->splitpath( $INST_TOP, 1 );

		$self->trace("Patching makefile.mk\n");
		$self->patch_file( 'perl-5.8.9/win32/makefile.mk' => $unpack_to, {
			dist     => $self,
			INST_DRV => $INST_DRV,
			INST_TOP => $INST_TOP,
		} );

		$self->trace("Building perl...\n");
		$self->_make;

		unless ( $perl->force ) {
			local $ENV{PERL_SKIP_TTY_TEST} = 1;
			$self->trace("Testing perl...\n");
			$self->_make('test');
		}

		$self->trace("Installing perl...\n");
		$self->_make( qw/install UNINST=1/ );
	}

	# Should now have a perl to use
	$self->{bin_perl} = File::Spec->catfile( $self->image_dir, qw/perl bin perl.exe/ );
	unless ( -x $self->bin_perl ) {
		Carp::croak("Can't execute " . $self->bin_perl);
	}

	# Add to the environment variables
	$self->add_env_path( 'perl', 'bin' );

	return 1;
}




#####################################################################
# Perl 5.10.0 Support

=pod

=head2 install_perl_5100

The C<install_perl_5100> method provides a simplified way to install
Perl 5.10.0 into the distribution.

It takes care of calling C<install_perl_5100_bin> with the standard
params, and then calls C<install_perl_5100_toolchain> to set up the
Perl 5.10.0 CPAN toolchain.

Returns true, or throws an exception on error.

=cut

sub install_perl_5100 {
	my $self = shift;

	# Prefetch and predelegate the toolchain so that it
	# fails early if there's a problem
	$self->trace("Pregenerating toolchain...\n");
	my $toolchain = Perl::Dist::Util::Toolchain->new(
		perl_version => $self->perl_version_literal,
	) or die("Failed to resolve toolchain modules");
	$toolchain->delegate;
	if ( $toolchain->{errstr} ) {
		print "Error: $toolchain->{errstr}\n"; 
		die("Failed to generate toolchain distributions");
	}

	# Install the main binary
	$self->install_perl_5100_bin(
		name       => 'perl',
                url        => 'http://strawberryperl.com/package/perl-5.10.0.tar.gz',
		unpack_to  => 'perl',
		install_to => 'perl',
		patch      => [ qw{
			lib/ExtUtils/Command.pm
			lib/CPAN/Config.pm
		} ],
		license    => {
			'perl-5.10.0/Readme'   => 'perl/Readme',
			'perl-5.10.0/Artistic' => 'perl/Artistic',
			'perl-5.10.0/Copying'  => 'perl/Copying',
		},
	);

	# Install the toolchain
	$self->install_perl_toolchain( $toolchain );

	return 1;
}

=pod

=head2 install_perl_5100_bin

  $self->install_perl_5100_bin(
      name       => 'perl',
      dist       => 'RGARCIA/perl-5.10.0.tar.gz',
      unpack_to  => 'perl',
      license    => {
          'perl-5.10.0/Readme'   => 'perl/Readme',
          'perl-5.10.0/Artistic' => 'perl/Artistic',
          'perl-5.10.0/Copying'  => 'perl/Copying',
      },
      install_to => 'perl',
  );

The C<install_perl_5100_bin> method takes care of the detailed process
of building the Perl 5.10.0 binary and installing it into the
distribution.

A short summary of the process would be that it downloads or otherwise
fetches the named package, unpacks it, copies out any license files from
the source code, then tweaks the Win32 makefile to point to the specific
build directory, and then runs make/make test/make install. It also
registers some environment variables for addition to the Inno Setup
script.

It is normally called directly by C<install_perl_5100> rather than
directly from the API, but is documented for completeness.

It takes a number of parameters that are sufficiently detailed above.

Returns true (after 20 minutes or so) or throws an exception on
error.

=cut

sub install_perl_5100_bin {
	my $self = shift;
	my $perl = Perl::Dist::Asset::Perl->new(
		parent => $self,
		force  => $self->force,
		@_,
	);
	unless ( $self->bin_make ) {
		die("Cannot build Perl yet, no bin_make defined");
	}
	$self->trace("Preparing " . $perl->name . "\n");

	# Download the file
	my $tgz = $self->_mirror(
		$perl->url,
		$self->download_dir,
	);

	# Unpack to the build directory
	my $unpack_to = File::Spec->catdir( $self->build_dir, $perl->unpack_to );
	if ( -d $unpack_to ) {
		$self->trace("Removing previous $unpack_to\n");
		File::Remove::remove( \1, $unpack_to );
	}
	$self->_extract( $tgz => $unpack_to );

	# Get the versioned name of the directory
	(my $perlsrc = $tgz) =~ s{\.tar\.gz\z|\.tgz\z}{};
	$perlsrc = File::Basename::basename($perlsrc);

	# Pre-copy updated files over the top of the source
	my $patch = $perl->patch;
	if ( $patch ) {
		# Overwrite the appropriate files
		foreach my $file ( @$patch ) {
			$self->patch_file( "perl-5.10.0/$file" => $unpack_to );
		}
	}

	# Copy in licenses
	if ( ref $perl->license eq 'HASH' ) {
		my $license_dir = File::Spec->catdir( $self->image_dir, 'licenses' );
		$self->_extract_filemap( $tgz, $perl->license, $license_dir, 1 );
	}

	# Build win32 perl
	SCOPE: {
		my $wd = $self->_pushd($unpack_to, $perlsrc , "win32" );

		# Prepare to patch
		my $image_dir  = $self->image_dir;
		my $INST_TOP   = File::Spec->catdir( $self->image_dir, $perl->install_to );
		my ($INST_DRV) = File::Spec->splitpath( $INST_TOP, 1 );

		$self->trace("Patching makefile.mk\n");
		$self->patch_file( 'perl-5.10.0/win32/makefile.mk' => $unpack_to, {
			dist     => $self,
			INST_DRV => $INST_DRV,
			INST_TOP => $INST_TOP,
		} );

		$self->trace("Building perl...\n");
		$self->_make;

		unless ( $perl->force ) {
			local $ENV{PERL_SKIP_TTY_TEST} = 1;
			$self->trace("Testing perl...\n");
			$self->_make('test');
		}

		$self->trace("Installing perl...\n");
		$self->_make( 'install' );
	}

	# Should now have a perl to use
	$self->{bin_perl} = File::Spec->catfile( $self->image_dir, qw/perl bin perl.exe/ );
	unless ( -x $self->bin_perl ) {
		die "Can't execute " . $self->bin_perl;
	}

	# Add to the environment variables
	$self->add_env_path( 'perl', 'bin' );

	return 1;
}





#####################################################################
# Installing C Toolchain and Library Packages

=pod

=head2 install_dmake

  $dist->install_dmake

The C<install_dmake> method installs the B<dmake> make tool into the
distribution, and is typically installed during "C toolchain" build
phase.

It provides the approproate arguments to C<install_binary> and then
validates that the binary was installed correctly.

Returns true or throws an exception on error.

=cut

sub install_dmake {
	my $self = shift;

	# Install dmake
	$self->install_binary(
		name       => 'dmake',
		license    => {
			'dmake/COPYING'            => 'dmake/COPYING',
			'dmake/readme/license.txt' => 'dmake/license.txt',
		},
		install_to => {
			'dmake/dmake.exe' => 'c/bin/dmake.exe',	
			'dmake/startup'   => 'c/bin/startup',
		},
	);

	# Initialize the make location
	$self->{bin_make} = File::Spec->catfile(
		$self->image_dir, 'c', 'bin', 'dmake.exe',
	);
	unless ( -x $self->bin_make ) {
		Carp::croak("Can't execute make");
	}

	return 1;
}

=pod

=head2 install_gcc

  $dist->install_gcc

The C<install_gcc> method installs the B<GNU C Compiler> into the
distribution, and is typically installed during "C toolchain" build
phase.

It provides the appropriate arguments to several C<install_binary>
calls. The default C<install_gcc> method installs two binary
packages, the core compiler 'gcc-core' and the C++ compiler 'gcc-c++'.

Returns true or throws an exception on error.

=cut

sub install_gcc {
	my $self = shift;


	# Install the compilers (gcc)
	$self->install_binary(
		name       => 'gcc-core',
		license    => {
			'COPYING'     => 'gcc/COPYING',
			'COPYING.lib' => 'gcc/COPYING.lib',
		},
	);
	$self->install_binary(
		name       => 'gcc-g++',
	);

	return 1;
}

=pod

=head2 install_binutils

  $dist->install_binutils

The C<install_binutils> method installs the C<GNU binutils> package into
the distribution.

The most important of these is C<dlltool.exe>, which is used to extract
static library files from .dll files. This is needed by some libraries
to let the Perl interfaces build against them correctly.

Returns true or throws an exception on error.

=cut

sub install_binutils {
	my $self = shift;

	$self->install_binary(
		name       => 'binutils',
		license    => {
			'Copying'     => 'binutils/Copying',
			'Copying.lib' => 'binutils/Copying.lib',
		},
	);
	$self->{bin_dlltool} = File::Spec->catfile(
		$self->image_dir, 'c', 'bin', 'dlltool.exe',
	);
	unless ( -x $self->bin_dlltool ) {
		die "Can't execute dlltool";
	}

	return 1;
}

=pod

=head2 install_pexports

  $dist->install_pexports

The C<install_pexports> method installs the C<MinGW pexports> package
into the distribution.

This is needed by some libraries to let the Perl interfaces build against
them correctly.

Returns true or throws an exception on error.

=cut

sub install_pexports {
	my $self = shift;

	$self->install_binary(
		name       => 'pexports',
		url        => $self->binary_url('pexports-0.43-1.zip'),
		license    => {
			'pexports-0.43/COPYING' => 'pexports/COPYING',
		},
		install_to => {
			'pexports-0.43/bin' => 'c/bin',
		},
	);
	$self->{bin_pexports} = File::Spec->catfile(
		$self->image_dir, 'c', 'bin', 'pexports.exe',
	);
	unless ( -x $self->bin_pexports ) {
		die "Can't execute pexports";
	}

	return 1;
}

=pod

=head2 install_mingw_runtime

  $dist->install_mingw_runtime

The C<install_mingw_runtime> method installs the MinGW runtime package
into the distribution, which is basically the MinGW version of libc and
some other very low level libs.

Returns true or throws an exception on error.

=cut

sub install_mingw_runtime {
	my $self = shift;

	$self->install_binary(
		name       => 'mingw-runtime',
		license    => {
			'doc/mingw-runtime/Contributors' => 'mingw/Contributors',
			'doc/mingw-runtime/Disclaimer'   => 'mingw/Disclaimer',
		},
	);

	return 1;
}

=pod

=head2 install_zlib

  $dist->install_zlib

The C<install_zlib> method installs the B<GNU zlib> compression library
into the distribution, and is typically installed during "C toolchain"
build phase.

It provides the appropriate arguments to a C<install_library> call that
will extract the standard zlib win32 package, and generate the additional
files that Perl needs.

Returns true or throws an exception on error.

=cut

sub install_zlib {
	my $self = shift;

	# Zlib is a pexport-based lib-install
	$self->install_library(
		name       => 'zlib',
		url        => $self->binary_url('zlib-1.2.3.win32.zip'),
		unpack_to  => 'zlib',
		build_a    => {
			'dll'    => 'zlib-1.2.3.win32/bin/zlib1.dll',
			'def'    => 'zlib-1.2.3.win32/bin/zlib1.def',
			'a'      => 'zlib-1.2.3.win32/lib/zlib1.a',
		},
		install_to => {
			'zlib-1.2.3.win32/bin'     => 'c/bin',
			'zlib-1.2.3.win32/lib'     => 'c/lib',
			'zlib-1.2.3.win32/include' => 'c/include',
		},
	);

	return 1;
}

=pod

=head2 install_win32api

  $dist->install_win32api

The C<install_win32api> method installs C<MinGW win32api> layer, to
allow C code to compile against native Win32 APIs.

Returns true or throws an exception on error.

=cut

sub install_win32api {
	my $self = shift;

	$self->install_binary(
		name => 'w32api',
	);

	return 1;
}

=pod

=head2 install_mingw_make

  $dist->install_mingw_make

The C<install_mingw_make> method installs the MinGW build of the B<GNU make>
build tool.

While GNU make is not used by Perl itself, some C libraries can't be built
using the normal C<dmake> tool and explicitly need GNU make. So we install
it as mingw-make and certain Alien:: modules will use it by that name.

Returns true or throws an exception on error.

=cut

sub install_mingw_make {
	my $self = shift;

	$self->install_binary(
		name => 'mingw-make',
	);

	return 1;
}

=pod

=head2 install_libiconv

  $dist->install_libiconv

The C<install_libiconv> method installs the C<GNU libiconv> library,
which is used for various character encoding tasks, and is needed for
other libraries such as C<libxml>.

Returns true or throws an exception on error.

=cut

sub install_libiconv {
	my $self = shift;

	# libiconv for win32 comes in 3 parts, install them.
	$self->install_binary(
		name => 'libiconv-dep',
	);
	$self->install_binary(
		name => 'libiconv-lib',
	);
	$self->install_binary(
		name => 'libiconv-bin',
	);

	# The dll is installed with an unexpected name,
	# so we correct it post-install.
	$self->_move(
		File::Spec->catfile( $self->image_dir, 'c', 'bin', 'libiconv2.dll' ),
		File::Spec->catfile( $self->image_dir, 'c', 'bin', 'iconv.dll'     ),
	);

	return 1;
}

=pod

=head2 install_libxml

  $dist->install_libxml

The C<install_libxml> method installs the C<Gnome libxml> library,
which is a fast, reliable, XML parsing library, and the new standard
library for XML parsing.

Returns true or throws an exception on error.

=cut

sub install_libxml {
	my $self = shift;

	# libxml is a straight forward pexport-based install
	$self->install_library(
		name       => 'libxml2',
		url        => $self->binary_url('libxml2-2.6.30.win32.zip'),
		unpack_to  => 'libxml2',
		build_a    => {
			'dll'    => 'libxml2-2.6.30.win32/bin/libxml2.dll',
			'def'    => 'libxml2-2.6.30.win32/bin/libxml2.def',
			'a'      => 'libxml2-2.6.30.win32/lib/libxml2.a',
		},			
		install_to => {
			'libxml2-2.6.30.win32/bin'     => 'c/bin',
			'libxml2-2.6.30.win32/lib'     => 'c/lib',
			'libxml2-2.6.30.win32/include' => 'c/include',
		},
	);

	return 1;
}

=pod

=head2 install_expat

  $dist->install_expat

The C<install_expat> method installs the C<Expat> XML library,
which was the first popular C XML parser. Many Perl XML libraries
are based on Expat.

Returns true or throws an exception on error.

=cut

sub install_expat {
	my $self = shift;

	# Install the PAR version of libexpat
	$self->install_par(
		name         => 'libexpat',
		share        => 'Perl-Dist vanilla/libexpat-vanilla.par',
		install_perl => 1,
		install_c    => 0,
	);

	return 1;
}

=pod

=head2 install_gmp

  $dist->install_gmp

The C<install_gmp> method installs the C<GNU Multiple Precision Arithmetic
Library>, which is used for fast and robust bignum support.

Returns true or throws an exception on error.

=cut

sub install_gmp {
	my $self = shift;

	# Comes as a single prepackaged vanilla-specific zip file
	$self->install_binary(
		name => 'gmp',
	);

	return 1;
}

=pod

=head2 install_pari

  $dist->install_pari

The C<install_pari> method install (via a PAR package) libpari and the
L<Math::Pari> module into the distribution.

This method should only be called at during the install_modules phase.

=cut

sub install_pari {
	$_[0]->install_par(
		name => 'pari',
		url  => 'http://strawberryperl.com/package/Math-Pari-2.010800.par',
	);
}





#####################################################################
# General Installation Methods

=pod

=head2 install_binary

  $self->install_binary(
      name => 'gmp',
  );

The C<install_gmp> method is used by library-specific methods to
install pre-compiled and un-modified tar.gz or zip archives into
the distribution.

Returns true or throws an exception on error.

=cut

sub install_binary {
	my $self   = shift;
	my $binary = Perl::Dist::Asset::Binary->new(
		parent     => $self,
		install_to => 'c', # Default to the C dir
		@_,
	);
	my $name   = $binary->name;
	$self->trace("Preparing $name\n");

	# Download the file
	my $tgz = $self->_mirror(
		$binary->url,
		$self->download_dir,
	);

	# Unpack the archive
	my $install_to = $binary->install_to;
	if ( ref $binary->install_to eq 'HASH' ) {
		$self->_extract_filemap( $tgz, $binary->install_to, $self->image_dir );

	} elsif ( ! ref $binary->install_to ) {
		# unpack as a whole
		my $tgt = File::Spec->catdir( $self->image_dir, $binary->install_to );
		$self->_extract( $tgz => $tgt );

	} else {
		die "didn't expect install_to to be a " . ref $binary->install_to;
	}

	# Find the licenses
	if ( ref $binary->license eq 'HASH' )   {
		$self->_extract_filemap( $tgz, $binary->license, $self->license_dir, 1 );
	}

	return 1;
}

sub install_library {
	my $self    = shift;
	my $library = Perl::Dist::Asset::Library->new(
		parent => $self,
		@_,
	);
	my $name = $library->name;
	$self->trace("Preparing $name\n");

	# Download the file
	my $tgz = $self->_mirror(
		$library->url,
		$self->download_dir,
	);

	# Unpack to the build directory
	my $unpack_to = File::Spec->catdir( $self->build_dir, $library->unpack_to );
	if ( -d $unpack_to ) {
		$self->trace("Removing previous $unpack_to\n");
		File::Remove::remove( \1, $unpack_to );
	}
	$self->_extract( $tgz => $unpack_to );

	# Build the .a file if needed
	if ( Params::Util::_HASH($library->build_a) ) {
		# Hand off for the .a generation
		$self->_dll_to_a(
			$library->build_a->{source} ?
			(
				source => File::Spec->catfile(
					$unpack_to, $library->build_a->{source},
				),
			) : (),
			dll    => File::Spec->catfile(
				$unpack_to, $library->build_a->{dll},
			),
			def    => File::Spec->catfile(
				$unpack_to, $library->build_a->{def},
			),
			a      => File::Spec->catfile(
				$unpack_to, $library->build_a->{a},
			),
		);
	}

	# Copy in the files
	my $install_to = $library->install_to;
	if ( Params::Util::_HASH($install_to) ) {
		foreach my $k ( sort keys %$install_to ) {
			my $from = File::Spec->catdir(
				$unpack_to, $k,
			);
			my $to = File::Spec->catdir(
				$self->image_dir, $install_to->{$k},
			);
			$self->_copy( $from => $to );
		}
	}

	# Copy in licenses
	if ( Params::Util::_HASH($library->license) ) {
		my $license_dir = File::Spec->catdir( $self->image_dir, 'licenses' );
		$self->_extract_filemap( $tgz, $library->license, $license_dir, 1 );
	}

	return 1;
}

=pod

=head2 install_distribution

  $self->install_distribution(
      name              => 'ADAMK/File-HomeDir-0.69.tar.gz,
      force             => 1,
      automated_testing => 1,
      makefilepl_param  => [
          'LIBDIR=' . File::Spec->catdir(
              $self->image_dir, 'c', 'lib',
          ),
      ],
  );

The C<install_distribution> method is used to install a single
CPAN or non-CPAN distribution directly, without installing any of the
dependencies for that distribution.

It is used primarily during CPAN bootstrapping, to allow the
installation of the toolchain modules, with the distribution install
order precomputed or hard-coded.

It takes a compulsory 'name' param, which should be the AUTHOR/file
path within the CPAN mirror.

The optional 'force' param allows the installation of distributions
with spuriously failing test suites.

The optional 'automated_testing' param allows for installation
with the C<AUTOMATED_TESTING> environment flag enabled, which is
used to either run more-intensive testing, or to convince certain
Makefile.PL that insists on prompting that there is no human around
and they REALLY need to just go with the default options.

The optional 'makefilepl_param' param should be a reference to an
array of additional params that should be passwd to the
C<perl Makefile.PL>. This can help with distributions that insist
on taking additional options via Makefile.PL.

Returns true of throws an exception on error.

=cut

sub install_distribution {
	my $self = shift;
	my $dist = Perl::Dist::Asset::Distribution->new(
		parent => $self,
		force  => $self->force,
		@_,
	);
	my $name = $dist->name;

	# Download the file
	my $tgz = $self->_mirror( 
		$dist->abs_uri( $self->cpan ),
		$self->download_dir,
	);

	# Where will it get extracted to
	my $dist_path = $name;
	$dist_path   =~ s/\.tar\.gz//;
	$dist_path   =~ s/\.zip//;
	$dist_path   =~ s/.+\///;
	my $unpack_to = File::Spec->catdir( $self->build_dir, $dist_path );

	# Extract the tarball
	if ( -d $unpack_to ) {
		$self->trace("Removing previous $unpack_to\n");
		File::Remove::remove( \1, $unpack_to );
	}
	$self->_extract( $tgz => $self->build_dir );
	unless ( -d $unpack_to ) {
		Carp::croak("Failed to extract $unpack_to");
	}

	# Build the module
	SCOPE: {
		my $wd = $self->_pushd($unpack_to);

		# Enable automated_testing mode if needed
		# Blame Term::ReadLine::Perl for needing this ugly hack.
		if ( $dist->automated_testing ) {
			$self->trace("Installing with AUTOMATED_TESTING enabled...\n");
		}
		if ( $dist->release_testing ) {
			$self->trace("Installing with RELEASE_TESTING enabled...\n");
		}
		local $ENV{AUTOMATED_TESTING} = $dist->automated_testing;
		local $ENV{RELEASE_TESTING}   = $dist->release_testing;

		$self->trace("Configuring $name...\n");
		$self->_perl( 'Makefile.PL', @{$dist->makefilepl_param} );

		$self->trace("Building $name...\n");
		$self->_make;

		unless ( $dist->force ) {
			$self->trace("Testing $name...\n");
			$self->_make('test');
		}

		$self->trace("Installing $name...\n");
		$self->_make( qw/install UNINST=1/ );
	}

	return 1;
}

=pod

=head2 install_module

  $self->install_module(
      name => 'DBI',
  );

The C<install_module> method is a high level installation method that can
be used during the C<install_perl_modules> phase, once the CPAN toolchain
has been been initialized.

It makes the installation call using the CPAN client directly, allowing
the CPAN client to both do the installation and fulfill all of the
dependencies for the module, identically to if it was installed from
the CPAN shell via an "install Module::Name" command.

The compulsory 'name' param should be the class name of the module to
be installed.

The optional 'force' param can be used to force the install of module.
This does not, however, force the installation of the dependencies of
the module.

Returns true or throws an exception on error.

=cut

sub install_module {
	my $self   = shift;
	my $module = Perl::Dist::Asset::Module->new(
		force  => $self->force,
		parent => $self,
		@_,
	);
	my $name   = $module->name;
	my $force  = $module->force;
	unless ( $self->bin_perl ) {
		Carp::croak("Cannot install CPAN modules yet, perl is not installed");
	}

	# Generate the CPAN installation script
	my $cpan_string = <<"END_PERL";
print "Loading CPAN...\\n";
use CPAN;
CPAN::HandleConfig->load unless \$CPAN::Config_loaded++;
print "Installing $name from CPAN...\\n";
my \$module = CPAN::Shell->expandany( "$name" ) 
	or die "CPAN.pm couldn't locate $name";
if ( \$module->uptodate ) {
	print "$name is up to date\\n";
	exit(0);
}
print "\\\$ENV{PATH} = '\$ENV{PATH}'\\n";
if ( $force ) {
	CPAN::Shell->notest('install', '$name');
} else {
	CPAN::Shell->install('$name');
}
print "Completed install of $name\\n";
unless ( \$module->uptodate ) {
	die "Installation of $name appears to have failed";
}
exit(0);
END_PERL

	# Dump the CPAN script to a temp file and execute
	$self->trace("Running install of $name\n");
	my $cpan_file = File::Spec->catfile(
		$self->build_dir,
		'cpan_string.pl',
	);
	SCOPE: {
		open( CPAN_FILE, '>', $cpan_file )  or die "open: $!";
		print CPAN_FILE $cpan_string        or die "print: $!";
		close( CPAN_FILE )                  or die "close: $!";
	}
	local $ENV{PERL_MM_USE_DEFAULT} = 1;
	local $ENV{AUTOMATED_TESTING}   = '';
	local $ENV{RELEASE_TESTING}     = '';
	$self->_run3( $self->bin_perl, $cpan_file ) or die "perl failed";
	die "Failure detected installing $name, stopping" if $?;

	return 1;
}

=pod

=head2 install_modules

  $self->install_modules( qw{
      Foo::Bar
      This::That
      One::Two
  } );

The C<install_modules> method is a convenience shorthand that makes it
trivial to install a series of modules via C<install_module>.

As a convenience, it does not support any additional params to the
underlying C<install_module> call other than the name.

=cut

sub install_modules {
	my $self = shift;
	foreach my $name ( @_ ) {
		$self->install_module(
			name => $name,
		);
	}
	return 1;
}

=pod

=head2 install_par

The C<install_par> method extends the available installation options to
allow for the install of pre-compiled modules and pre-compiled C libraries
via "PAR" packages.

The compulsory 'name' param should be a simple identifying name, and does
not have any functional use.

The compulsory 'uri' param should be a URL string to the PAR package.

Returns true on success or throws an exception on error.

=cut

sub install_par {
	my $self = shift;
	my $par  = Perl::Dist::Asset::PAR->new(
		parent     => $self,
		# not supported at the moment:
		#install_to => 'c', # Default to the C dir
		@_,
	);

	# Download the file.
	# Do it here for consistency instead of letting PAR::Dist do it
	$self->trace("Preparing " . $par->name . "\n");
	my $file = $self->_mirror( 
		$par->url,
		$self->download_dir,
	);

	# Set the appropriate installation paths
	my $no_colon = $par->name;
	   $no_colon =~ s/::/-/g;
	my $perldir  = File::Spec->catdir($self->image_dir, 'perl');
	my $libdir   = File::Spec->catdir($perldir, 'site', 'lib');
	my $bindir   = File::Spec->catdir($perldir, 'bin');
	my $packlist = File::Spec->catfile($libdir, $no_colon, '.packlist');
	my $cdir     = File::Spec->catdir($self->image_dir, 'c');

	# Suppress warnings for resources that don't exist
	local $^W = 0;

	# Install
	PAR::Dist::install_par(
		dist           => $file,
		packlist_read  => $packlist,
		packlist_write => $packlist,
		inst_lib       => $libdir,
		inst_archlib   => $libdir,
		inst_bin       => $bindir,
		inst_script    => $bindir,
		inst_man1dir   => undef, # no man pages
		inst_man3dir   => undef, # no man pages
		custom_targets =>  {
			'blib/c/lib'     => File::Spec->catdir($cdir, 'lib'),
			'blib/c/bin'     => File::Spec->catdir($cdir, 'bin'),
			'blib/c/include' => File::Spec->catdir($cdir, 'include'),
			'blib/c/share'   => File::Spec->catdir($cdir, 'share'),
		},
	);

	return 1;
}

=pod

=head2 install_file

  # Overwrite the CPAN::Config
  $self->install_file(
      share      => 'Perl-Dist CPAN_Config.pm',
      install_to => 'perl/lib/CPAN/Config.pm',
  );
  
  # Install a custom icon file
  $self->install_file(
      name       => 'Strawberry Perl Website Icon',
      url        => 'http://strawberryperl.com/favicon.ico',
      install_to => 'Strawberry Perl Website.ico',
  );

The C<install_file> method is used to install a single specific file from
various sources into the distribution.

It is generally used to overwrite modules with distribution-specific
customisations, or to install licenses, README files, or other
miscellaneous data files which don't need to be compiled or modified.

It takes a variety of different params.

The optional 'name' param provides an optional plain name for the file.
It does not have any functional purpose or meaning for this method.

One of several alternative source methods must be provided.

The 'url' method is used to provide a fully-resolved path to the
source file and should be a fully-resolved URL.

The 'file' method is used to provide a local path to the source file
on the local system, and should be a fully-resolved filesystem path.

The 'share' method is used to provide a path to a file installed as
part of a CPAN distribution, and accessed via L<File::ShareDir>.

It should be a string containing two space-seperated value, the first
of which is the distribution name, and the second is the path within
the share dir of that distribution.

The final compulsory method is the 'install_to' method, which provides
either a destination file path, or alternatively a path to an existing
directory that the file be installed below, using its source file name.

Returns true or throws an exception on error.

=cut

sub install_file {
	my $self = shift;
	my $dist = Perl::Dist::Asset::File->new(
		parent => $self,
		@_,
	);

	# Get the file
	my $tgz = $self->_mirror(
		$dist->url,
		$self->download_dir
	);

	# Copy the file to the target location
	my $from = File::Spec->catfile( $self->download_dir, $dist->file       );
	my $to   = File::Spec->catfile( $self->image_dir,    $dist->install_to );
	$self->_copy( $from => $to );	

	# Clear the download file
	File::Remove::remove( \1, $tgz );

	return 1;
}

=pod

=head2 install_launcher

  $self->install_launcher(
      name => 'CPAN Client',
      bin  => 'cpan',
  );

The C<install_launcher> method is used to describe a binary program
launcher that will be added to the Windows "Start" menu when the
distribution is installed.

It takes two compulsory param.

The compulsory 'name' param is the name of the launcher, and the text
that label will be displayed in the start menu (Currently this only
supports ASCII, and is not language-aware in any way).

The compulsory 'bin' param should be the name of a .bat script launcher
in the Perl bin directory. The program itself MUST be installed before
trying to add the launcher.

Returns true or throws an exception on error.

=cut

sub install_launcher {
	my $self     = shift;
	my $launcher = Perl::Dist::Asset::Launcher->new(
		parent => $self,
		@_,
	);

	# Check the script exists
	my $to = File::Spec->catfile( $self->image_dir, 'perl', 'bin', $launcher->bin . '.bat' );
	unless ( -f $to ) {
		die "The script '" . $launcher->bin . '" does not exist';
	}

	# Add the icon
	$self->add_icon(
		name     => $launcher->name,
		filename => '{app}\\perl\bin\\' . $launcher->bin . '.bat',
	);

	return 1;
}

=pod

=head2 install_website

  $self->install_website(
      name       => 'Strawberry Perl Website',
      url        => 'http://strawberryperl.com/',
      icon_file  => 'Strawberry Perl Website.ico',
      icon_index => 1,
  );

The C<install_website> param is used to install a "Start" menu entry
that will load a website using the default system browser.

The compulsory 'name' param should be the name of the website, and will
be the labelled displayed in the "Start" menu.

The compulsory 'url' param is the fully resolved URL for the website.

The optional 'icon_file' param should be the path to a file that contains the
icon for the website.

The optional 'icon_index' param should be the icon index within the icon file.
This param is optional even if the 'icon_file' param has been provided, by
default the first icon in the file will be used.

Returns true on success, or throws an exception on error.

=cut

sub install_website {
	my $self    = shift;
	my $website = Perl::Dist::Asset::Website->new(
		parent => $self,
		@_,
	);

	# Write the file directly to the image
	$website->write(
		File::Spec->catfile($self->image_dir, $website->file)
	);

	# Add the file to the files section of the inno script
	$self->add_file(
		source   => $website->file,
		dest_dir => '{app}\\win32',
	);

	# Add the file to the icons section of the inno script
	$self->add_icon(
		name     => $website->name,
		filename => '{app}\\win32\\' . $website->file,
	);

	return 1;
}





#####################################################################
# Package Generation

sub write {
	my $self = shift;
	$self->{output_file} ||= [];
	if ( $self->zip ) {
		push @{ $self->{output_file} }, $self->write_zip;
	}
	if ( $self->exe ) {
		push @{ $self->{output_file} }, $self->write_exe;
	}
	return 1;
}

=pod

=head2 write_exe

  $self->write_exe;

The C<write_exe> method is used to generate the compiled installer
executable. It creates the entire installation file tree, and then
executes InnoSetup to create the final executable.

This method should only be called after all installation phases have
been completed and all of the files for the distribution are in place.

The executable file is written to the output directory, and the location
of the file is printed to STDOUT.

Returns true or throws an exception or error.

=cut

sub write_exe {
	my $self = shift;

	# Convert the environment to registry entries
	if ( @{$self->{env_path}} ) {
		my $value = "{olddata}";
		foreach my $array ( @{$self->{env_path}} ) {
			$value .= File::Spec::Win32->catdir(
				';{app}', @$array,
			);
		}
		$self->add_env( PATH => $value );
	}

	$self->SUPER::write_exe(@_);
}

=pod

=head2 write_zip

The C<write_zip> method is used to generate a standalone .zip file
containing the entire distribution, for situations in which a full
installer executable is not wanted (such as for "Portable Perl"
type installations).

The executable file is written to the output directory, and the location
of the file is printed to STDOUT.

Returns true or throws an exception or error.

=cut

sub write_zip {
	my $self = shift;
	my $file = File::Spec->catfile(
		$self->output_dir, $self->output_base_filename . '.zip'
	);
	$self->trace("Generating zip at $file\n");

	# Create the archive
	my $zip = Archive::Zip->new;

	# Add the image directory to the root
	$zip->addTree( $self->image_dir, '' );

	# Set max compression for all members
	foreach my $member ( $zip->members ) {
		next if $member->isDirectory;
		$member->desiredCompressionLevel( 9 );
	}

	# Write out the file name
	$zip->writeToFileNamed( $file );

	return $file;
}





#####################################################################
# Adding Inno-Setup Information

sub add_icon {
	my $self   = shift;
	my %params = @_;
	$params{name}     = "{group}\\$params{name}";
	unless ( $params{filename} =~ /^\{/ ) {
		$params{filename} = "{app}\\$params{filename}";
	}
	$self->SUPER::add_icon(%params);
}

sub add_system {
	my $self   = shift;
	my %params = @_;
	unless ( $params{filename} =~ /^\{/ ) {
		$params{filename} = "{app}\\$params{filename}";
	}
	$self->SUPER::add_system(%params);
}

sub add_run {
	my $self   = shift;
	my %params = @_;
	unless ( $params{filename} =~ /^\{/ ) {
		$params{filename} = "{app}\\$params{filename}";
	}
	$self->SUPER::add_run(%params);
}

sub add_uninstallrun {
	my $self   = shift;
	my %params = @_;
	unless ( $params{filename} =~ /^\{/ ) {
		$params{filename} = "{app}\\$params{filename}";
	}
	$self->SUPER::add_uninstallrun(%params);
}

sub add_env_path {
	my $self = shift;
	my @path = @_;
	my $dir = File::Spec->catdir(
		$self->image_dir, @path,
	);
	unless ( -d $dir ) {
		Carp::croak("PATH directory $dir does not exist");
	}
	push @{$self->{env_path}}, [ @path ];
	return 1;
}

sub get_env_path {
	my $self = shift;
	return join ';', map {
		File::Spec->catdir( $self->image_dir, @$_ )
	} @{$self->env_path};
}

sub get_inno_path {
	my $self = shift;
	return join ';', '{olddata}', map {
		File::Spec->catdir( '{app}', @$_ )
	} @{$self->env_path};
}

sub add_env_lib {
	my $self = shift;
	my @path = @_;
	my $dir = File::Spec->catdir(
		$self->image_dir, @path,
	);
	unless ( -d $dir ) {
		Carp::croak("INC directory $dir does not exist");
	}
	push @{$self->{env_lib}}, [ @path ];
	return 1;
}

sub get_env_lib {
	my $self = shift;
	return join ';', map {
		File::Spec->catdir( $self->image_dir, @$_ )
	} @{$self->env_lib};
}

sub get_inno_lib {
	my $self = shift;
	return join ';', '{olddata}', map {
		File::Spec->catdir( '{app}', @$_ )
	} @{$self->env_lib};
}

sub add_env_include {
	my $self = shift;
	my @path = @_;
	my $dir = File::Spec->catdir(
		$self->image_dir, @path,
	);
	unless ( -d $dir ) {
		Carp::croak("PATH directory $dir does not exist");
	}
	push @{$self->{env_include}}, [ @path ];
	return 1;
}

sub get_env_include {
	my $self = shift;
	return join ';', map {
		File::Spec->catdir( $self->image_dir, @$_ )
	} @{$self->env_include};
}

sub get_inno_include {
	my $self = shift;
	return join ';', '{olddata}', map {
		File::Spec->catdir( '{app}', @$_ )
	} @{$self->env_include};
}





#####################################################################
# Patch Support

# By default only use the default (as a default...)
sub patch_include_path {
	my $self  = shift;
	my $share = File::ShareDir::dist_dir('Perl-Dist');
	my $path  = File::Spec->catdir(
		$share, 'default',
	);
	unless ( -d $path ) {
		die("Directory $path does not exist");
	}
	return [ $path ];
}

sub patch_pathlist {
	my $self = shift;
	return File::PathList->new(
		paths => $self->patch_include_path,
	);
}

# Cache this
sub patch_template {
	$_[0]->{template_toolkit} or
	$_[0]->{template_toolkit} = Template->new(
		INCLUDE_PATH => $_[0]->patch_include_path,
		ABSOLUTE     => 1,
	);
}

sub patch_file {
	my $self     = shift;
	my $file     = shift;
	my $file_tt  = $file . '.tt';
	my $dir      = shift;
	my $to       = File::Spec->catfile( $dir, $file );
	my $pathlist = $self->patch_pathlist;

	# Locate the source file
	my $from    = $pathlist->find_file( $file );
	my $from_tt = $pathlist->find_file( $file_tt );;
	unless ( defined $from and defined $from_tt ) {
		die "Missing or invalid file $file or $file_tt in pathlist search";
	}

	if ( $from_tt ne '' ) {
		# Generate the file
		my $hash = Params::Util::_HASH(shift) || {};
		my ($fh, $output) = File::Temp::tempfile();
		$self->trace("Generating $from_tt into temp file $output\n");
		$self->patch_template->process(
			$from_tt,
			{ %$hash, self => $self },
			$fh,
		) or die "Template processing failed for $from_tt";

		# Copy the file to the final location
		$fh->close;
		$self->_copy( $output => $to );

	} elsif ( $from ne '' ) {
		# Simple copy of the regular file to the target location
		$self->_copy( $from => $to );

	} else {
		die "Failed to find file $file";
	}

	return 1;
}

sub image_dir_url {
	my $self = shift;
	URI::file->new( $self->image_dir )->as_string;
}

# This is a temporary hack
sub image_dir_quotemeta {
	my $self = shift;
	my $string = $self->image_dir;
	$string =~ s/\\/\\\\/g;
	return $string;
}





#####################################################################
# Support Methods

sub trace {
	my $self = shift;
	if ( $self->{trace} ) {
		print $_[0];
	}
	return 1;
}

sub dir {
	File::Spec->catdir( shift->image_dir, @_ );
}

sub file {
	File::Spec->catfile( shift->image_dir, @_ );
}

sub user_agent {
	my $self = shift;
	unless ( $self->{user_agent} ) {
		if ( $self->{user_agent_cache} ) {
			SCOPE: {
				# Temporarily set $ENV{HOME} to the File::HomeDir
				# version while loading the module.
				local $ENV{HOME} ||= File::HomeDir->my_home;
				require LWP::UserAgent::WithCache;
			}
			$self->{user_agent} = LWP::UserAgent::WithCache->new( {
				namespace          => 'perl-dist',
				cache_root         => $self->user_agent_directory,
				cache_depth        => 0,
				default_expires_in => 86400 * 30,
				show_progress      => 1,
			} );
		} else {
			$self->{user_agent} = LWP::UserAgent->new(
				agent         => ref($self) . '/' . ($VERSION || '0.00'),
				timeout       => 30,
				show_progress => 1,
			);
		}
	}
	return $self->{user_agent};
}

sub user_agent_cache {
	$_[0]->{user_agent_cache};
}

sub user_agent_directory {
	my $self = shift;
	my $path = ref($self);
	   $path =~ s/::/-/g;
	my $dir  = File::Spec->catdir(
		File::HomeDir->my_data,
		'Perl', $path,
	);
	unless ( -d $dir ) {
		unless ( File::Path::mkpath( $dir, { verbose => 0 } ) ) {
			die("Failed to create $dir");
		}
	}
	unless ( -w $dir ) {
		die("No write permissions for LWP::UserAgent cache '$dir'");
	}
	return $dir;
}

sub _mirror {
	my ($self, $url, $dir) = @_;
	my $file = $url;
	$file =~ s|.+\/||;
	my $target = File::Spec->catfile( $dir, $file );
	if ( $self->offline and -f $target ) {
		return $target;
	}
	if ( $self->offline and ! $url =~ m|^file://| ) {
		$self->trace("Error: Currently offline, cannot download.\n");
		exit(0);
	}
	File::Path::mkpath($dir);
	$| = 1;

	$self->trace("Downloading file $url...\n");
	if ( $url =~ m|^file://| ) {
		# Don't use WithCache for files (it generates warnings)
		my $ua = LWP::UserAgent->new;
		my $r  = $ua->mirror( $url, $target );
		if ( $r->is_error ) {
			$self->trace("    Error getting $url:\n" . $r->as_string . "\n");
		} elsif ( $r->code == HTTP::Status::RC_NOT_MODIFIED ) {
			$self->trace("(already up to date)\n");
		}
	} else {
		# my $ua = $self->user_agent;
		my $ua = LWP::UserAgent->new;
		my $r  = $ua->mirror( $url, $target );
		if ( $r->is_error ) {
			$self->trace("    Error getting $url:\n" . $r->as_string . "\n");
		} elsif ( $r->code == HTTP::Status::RC_NOT_MODIFIED ) {
			$self->trace("(already up to date)\n");
		}
	}

	return $target;
}

sub _copy {
	my ($self, $from, $to) = @_;
	my $basedir = File::Basename::dirname( $to );
	File::Path::mkpath($basedir) unless -e $basedir;
	$self->trace("Copying $from to $to\n");
	if ( -f $to and ! -w $to ) {
		require Win32::File::Object;

		# Make sure it isn't readonly
		my $file     = Win32::File::Object->new( $to, 1 );
		my $readonly = $file->readonly;
		$file->readonly(0);

		# Do the actual copy
		File::Copy::Recursive::rcopy( $from, $to ) or die $!;

		# Set it back to what it was
		$file->readonly($readonly);
	} else {
		File::Copy::Recursive::rcopy( $from, $to ) or die $!;
	}
	return 1;
}

sub _move {
	my ($self, $from, $to) = @_;
	my $basedir = File::Basename::dirname( $to );
	File::Path::mkpath($basedir) unless -e $basedir;
	$self->trace("Moving $from to $to\n");
	File::Copy::Recursive::rmove( $from, $to ) or die $!;
}

sub _pushd {
	my $self = shift;
	my $dir  = File::Spec->catdir(@_);
	$self->trace("Lexically changing directory to $dir...\n");
	return File::pushd::pushd( $dir );
}

sub _make {
	my $self   = shift;
	my @params = @_;
	$self->trace(join(' ', '>', $self->bin_make, @params) . "\n");
	$self->_run3( $self->bin_make, @params ) or die "make failed";
	die "make failed (OS error)" if ( $? >> 8 );
	return 1;
}

sub _perl {
	my $self   = shift;
	my @params = @_;
	$self->trace(join(' ', '>', $self->bin_perl, @params) . "\n");
	$self->_run3( $self->bin_perl, @params ) or die "perl failed";
	die "perl failed (OS error)" if ( $? >> 8 );
	return 1;
}

sub _run3 {
	my $self = shift;

	# Remove any Perl installs from PATH to prevent
	# "which" discovering stuff it shouldn't.
	my @path = split /;/, $ENV{PATH};
	my @keep = ();
	foreach my $p ( @path ) {
		# Strip any path that doesn't exist
		next unless -d $p;

		# Strip any path that contains either dmake or perl.exe.
		# This should remove both the ...\c\bin and ...\perl\bin
		# parts of the paths that Vanilla/Strawberry added.
		next if -f File::Spec->catfile( $p, 'dmake.exe' );
		next if -f File::Spec->catfile( $p, 'perl.exe'  );

		# Strip any path that contains either unzip or gzip.exe.
		# These two programs cause perl to fail its own tests.
		next if -f File::Spec->catfile( $p, 'unzip.exe' );
		next if -f File::Spec->catfile( $p, 'gzip.exe' );

		push @keep, $p;
	}

	# Reset the environment
	local $ENV{LIB}      = '';
	local $ENV{INCLUDE}  = '';
	local $ENV{PERL5LIB} = '';
	local $ENV{PATH}     = $self->get_env_path . ';' . join( ';', @keep );

	# Execute the child process
	return IPC::Run3::run3( [ @_ ],
		\undef,
		$self->debug_stdout,
		$self->debug_stderr,
	);
}

sub _extract {
	my ( $self, $from, $to ) = @_;
	File::Path::mkpath($to);
	my $wd = $self->_pushd($to);
	$self->trace("Extracting $from...\n");
	if ( $from =~ m{\.zip\z} ) {
		my $zip = Archive::Zip->new( $from );
		$zip->extractTree();

	} elsif ( $from =~ m{\.tar\.gz|\.tgz} ) {
		local $Archive::Tar::CHMOD = 0;
		Archive::Tar->extract_archive($from, 1);

	} else {
		die "Didn't recognize archive type for $from";
	}
	return 1;
}


sub _extract_filemap {
	my ( $self, $archive, $filemap, $basedir, $file_only ) = @_;

	if ( $archive =~ m{\.zip\z} ) {
		my $zip = Archive::Zip->new( $archive );
		my $wd  = $self->_pushd($basedir);
		while ( my ($f, $t) = each %$filemap ) {
			$self->trace("Extracting $f to $t\n");
			my $dest = File::Spec->catfile( $basedir, $t );
			$zip->extractTree( $f, $dest );
		}

	} elsif ( $archive =~ m{\.tar\.gz|\.tgz} ) {
		local $Archive::Tar::CHMOD = 0;
		my $tar = Archive::Tar->new( $archive );
		for my $file ( $tar->get_files ) {
			my $f = $file->full_path;
			my $canon_f = File::Spec::Unix->canonpath( $f );
			for my $tgt ( keys %$filemap ) {
				my $canon_tgt = File::Spec::Unix->canonpath( $tgt );
				my $t;

				# say "matching $canon_f vs $canon_tgt";
				if ( $file_only ) {
					next unless $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E\z}i;
					($t = $canon_f)   =~ s{\A([^/]+[/])?\Q$canon_tgt\E\z}
	             				{$filemap->{$tgt}}i;

				} else {
					next unless $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E}i;
					($t = $canon_f) =~ s{\A([^/]+[/])?\Q$canon_tgt\E}
	             				{$filemap->{$tgt}}i;
				}
				my $full_t = File::Spec->catfile( $basedir, $t );
				$self->trace("Extracting $f to $full_t\n");
				$tar->extract_file( $f, $full_t );
			}
		}

	} else {
		die "Didn't recognize archive type for $archive";
	}

	return 1;
}

# Convert a .dll to an .a file
sub _dll_to_a {
	my $self   = shift;
	my %params = @_;
	unless ( $self->bin_dlltool ) {
		Carp::croak("Required method bin_dlltool is not defined");
	}

	# Source file
	my $source = $params{source};
	if ( $source and ! $source =~ /\.dll$/ ) {
		Carp::croak("Missing or invalid source param");
	}

	# Target .dll file
	my $dll = $params{dll};
	unless ( $dll and $dll =~ /\.dll/ ) {
		Carp::croak("Missing or invalid .dll file");
	}

	# Target .def file
	my $def = $params{def};
	unless ( $def and $def =~ /\.def$/ ) {
		Carp::croak("Missing or invalid .def file");
	}

	# Target .a file
	my $_a = $params{a};
	unless ( $_a and $_a =~ /\.a$/ ) {
		Carp::croak("Missing or invalid .a file");
	}

	# Step 1 - Copy the source .dll to the target if needed
	unless ( ($source and -f $source) or -f $dll ) {
		Carp::croak("Need either a source or dll param");
	}
	if ( $source ) {
		$self->_move( $source => $dll );
	}

	# Step 2 - Generate the .def from the .dll
	SCOPE: {
		my $bin = $self->bin_pexports;
		unless ( $bin ) {
			Carp::croak("Required method bin_pexports is not defined");
		}
		my $ok = ! system("$bin $dll > $def");
		unless ( $ok and -f $def ) {
			Carp::croak("Failed to generate .def file");
		}
	}

	# Step 3 - Generate the .a from the .def
	SCOPE: {
		my $bin = $self->bin_dlltool;
		unless ( $bin ) {
			Carp::croak("Required method bin_dlltool is not defined");
		}
		my $ok = ! system("$bin -dllname $dll --def $def --output-lib $_a");
		unless ( $ok and -f $_a ) {
			Carp::croak("Failed to generate .a file");
		}
	}

	return 1;
}

sub make_path {
	my $class = shift;
	my $dir   = File::Spec->rel2abs(
		File::Spec->catdir(
			File::Spec->curdir, @_,
		),
	);
	File::Path::mkpath( $dir ) unless -d $dir;
	unless ( -d $dir ) {
		Carp::croak("Failed to make_path for $dir");
	}
	return $dir;
}

sub remake_path {
	my $class = shift;
	my $dir   = File::Spec->rel2abs(
		File::Spec->catdir(
			File::Spec->curdir, @_,
		),
	);
	File::Remove::remove( \1, $dir ) if -d $dir;
	File::Path::mkpath( $dir );
	unless ( -d $dir ) {
		Carp::croak("Failed to make_path for $dir");
	}
	return $dir;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>, L<vanillaperl.com>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
