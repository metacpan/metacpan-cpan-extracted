package Perl::Dist::WiX;

=pod

=begin readme text

Perl-Dist-WiX version 1.500002

=end readme

=for readme stop

=head1 NAME

Perl::Dist::WiX - 4th generation Win32 Perl distribution builder

=head1 VERSION

This document describes Perl::Dist::WiX version 1.500002.

=for readme continue

=head1 DESCRIPTION

This package is the upgrade to L<Perl::Dist|Perl::Dist> based on Windows 
Installer XML technology, instead of Inno Setup.

Perl distributions built with this module have the option of being created
as Windows Installer databases (otherwise known as .msi files)

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

=end readme

=for readme stop

=head1 SYNOPSIS

	# Sets up a distribution with the following options
	my $distribution = Perl::Dist::WiX->new(
		msi               => 1,
		trace             => 1,
		build_number      => 1,
		cpan              => URI->new(('file://C|/minicpan/')),
		image_dir         => 'C:\myperl',
		download_dir      => 'C:\cpandl',
		output_dir        => 'C:\myperl_build',
		temp_dir          => 'C:\temp',
		app_id            => 'myperl',
		app_name          => 'My Perl',
		app_publisher     => 'My Perl Distribution Project',
		app_publisher_url => 'http://test.invalid/',
	);

	# Creates the distribution
	$distribution->run();

=head1 INTERFACE

=cut

#<<<
use 5.010;
use Moose 1.08;
use Moose::Util::TypeConstraints;
use Alien::WiX                              qw(
	:ALL
);
use Archive::Zip                            qw(
	:ERROR_CODES
);
use English                                 qw(
	-no_match_vars
);
use List::MoreUtils                         qw(
	any none uniq
);
use MooseX::Types::Moose                    qw(
	Int Str Maybe Bool Undef ArrayRef Maybe HashRef
);
use MooseX::Types::URI                      qw( 
	Uri
);
use MooseX::Types::Path::Class              qw(
	File Dir
);
use Perl::Dist::WiX::Types                  qw(
	ExistingDirectory ExistingFile TemplateObj
	ExistingSubdirectory ExistingDirectory_Spaceless 
	ExistingDirectory_SaneSlashes
);
use Params::Util                            qw(
	_HASH _STRING _INSTANCE _IDENTIFIER _ARRAY0 _ARRAY
);
use Readonly                                qw(
	Readonly
);
use Storable                                qw(
	retrieve
);
use File::Spec::Functions                   qw(
	catdir catfile catpath tmpdir splitpath rel2abs curdir
);
use CPAN                             1.9600 qw();
use File::HomeDir                           qw();
use File::ShareDir                          qw();
use File::Copy::Recursive                   qw();
use File::PathList                          qw();
use HTTP::Status                            qw();
use IO::File                                qw();
use IO::String                              qw();
use IO::Handle                              qw();
use IPC::Run3                               qw();
use LWP::UserAgent                          qw();
use LWP::Online                             qw();
use Module::CoreList                   2.46 qw();
use PAR::Dist                               qw();
use Path::Class::Dir                        qw();
use Probe::Perl                             qw();
use SelectSaver                             qw();
use Template                                qw();
use URI                                     qw();
use URI::file                               qw();
use Win32                                   qw();
use File::List::Object                      qw();
use Perl::Dist::WiX::Exceptions             qw();
use Perl::Dist::WiX::DirectoryTree          qw();
use Perl::Dist::WiX::FeatureTree            qw();
use Perl::Dist::WiX::DirectoryCache         qw();
use Perl::Dist::WiX::Fragment::CreateFolder qw();
use Perl::Dist::WiX::Fragment::Files        qw();
use Perl::Dist::WiX::Fragment::Environment  qw();
use Perl::Dist::WiX::Fragment::StartMenu    qw();
use Perl::Dist::WiX::IconArray              qw();
use Perl::Dist::WiX::PropertyList           qw();
use Perl::Dist::WiX::Tag::MergeModule       qw();
use Perl::Dist::WiX::Tag::DirectoryRef      qw();
use WiX3::XML::GeneratesGUID::Object        qw();
use WiX3::XML::RegistryKey                  qw();
use WiX3::XML::RegistryValue                qw();
use WiX3::XML::Fragment                     qw();
use WiX3::XML::Component                    qw();
use WiX3::Traceable                         qw();

use namespace::clean  -except => 'meta';
#>>>

our $VERSION = '1.500002';

with
  'MooseX::Object::Pluggable'          => { -version => 0.0011 },
  'Perl::Dist::WiX::Role::MultiPlugin' => { -version => 1.500 },
  ;
extends
  'Perl::Dist::WiX::Mixin::BuildPerl'    => { -version => 1.500002 },
  'Perl::Dist::WiX::Mixin::Checkpoint'   => { -version => 1.500002 },
  'Perl::Dist::WiX::Mixin::Libraries'    => { -version => 1.500002 },
  'Perl::Dist::WiX::Mixin::Installation' => { -version => 1.500 },
  'Perl::Dist::WiX::Mixin::ReleaseNotes' => { -version => 1.500 },
  'Perl::Dist::WiX::Mixin::Patching'     => { -version => 1.500 },
  'Perl::Dist::WiX::Mixin::Support'      => { -version => 1.500002 },
  ;

#####################################################################
# Constructor
#
# (Technically, the definition of the public attributes, and the
# BUILDARGS routine, as Moose provides our new().)
#

=pod

=head2 new

The B<new> method creates a Perl::Dist::WiX object that describes a 
distribution of perl.

Each object is used to create a single distribution by calling L<run()|/run>, 
and then should be discarded.

Although there are over 60 potential constructor arguments that can be
provided, most of them are automatically resolved and exist for overloading
puposes only, or they revert to sensible defaults and generally never need
to be modified.

This routine may take a few minutes to run.

An example of the most likely attributes that will be specified is in the 
SYNOPSIS.

Attributes that are required to be set are marked as I<required> 
below.  They may often be set by subclasses.

All attributes below can also be called as accessors on the object created.

There are six types of parameters that can be passed to new().

=head3 Types of distributions to build

This specifies the "highest" level of change in how the perl distribution is 
made - whether a .zip is requested, a .msi, a "thumb-drive portable" .zip, or
a relocatable .msi or .zip.

=head4 msi

The optional boolean C<msi> param is used to indicate that a Windows
Installer distribution package (otherwise known as an msi file) should 
be created.

It defaults to true, unless L<portable()|/portable> is true.

=cut

has 'msi' => (
	is      => 'ro',
	isa     => Bool,
	writer  => '_set_msi',
	default => sub {
		my $self = shift;
		return $self->portable() ? 0 : 1;
	},
);



=head4 msm

The optional boolean C<msm> param is used to indicate that a Windows
Installer merge module (otherwise known as an msm file) should 
be created.

This defaults to true, unless L<portable()|/portable> is true. 

=cut

has 'msm' => (
	is      => 'ro',
	isa     => Bool,
	default => sub {
		my $self = shift;
		return $self->portable() ? 0 : 1;
	},
);



=head4 zip

The optional boolean C<zip> param is used to indicate that a zip
distribution package should be created.

This defaults to the value of C<portable()>.

=cut

has 'zip' => (
	is      => 'ro',
	isa     => Bool,
	lazy    => 1,
	default => sub {
		my $self = shift;
		return $self->portable() ? 1 : 0;
	},
);



=head4 portable

The optional C<portable> parameter is used to determine whether a portable
'Perl-on-a-stick' distribution - one that is intended for distribution on
a portable storage device - is built with this object.

If set to a true value, L<zip()|/zip> must also be set to a true value, and 
L<msi()|/msi> will be set to a false value.

This defaults to a false value. 

=cut

has 'portable' => (
	is      => 'ro',
	isa     => Bool,
	default => 0,
);



=head4 relocatable

The optional C<relocatable> parameter is used to determine whether the 
distribution is meant to be relocatable.

This defaults to a false value. 

=cut

has 'relocatable' => (
	is      => 'ro',
	isa     => Bool,
	default => 0,
);



=head4 exe

The optional boolean C<exe> param is unused at the moment.

=cut

has 'exe' => (
	is      => 'ro',
	isa     => Bool,
	writer  => '_set_exe',
	default => 0,
);



=head3 Parameters that affect the build process.

These parameters affect the build process - whether modules are tested 
or not, how much information is given, what routines to run, etcetera.

=head4 force

The optional C<force> parameter determines if perl and perl modules are 
tested upon installation.  If this parameter is true, then no testing 
is done.

This defaults to false.

=cut

has 'force' => (
	is      => 'ro',
	isa     => Bool,
	default => 0,
);



=head4 forceperl

The optional C<forceperl> parameter determines if perl and perl modules 
are tested upon installation.  If this parameter is true, then testing 
is done only upon installed modules, not upon perl itself.

This defaults to false.

=cut

has 'forceperl' => (
	is      => 'ro',
	isa     => Bool,
	default => 0,
);



=head4 offline

The B<Perl::Dist::WiX> module has limited ability to build offline, if all
packages have already been downloaded and cached.

The connectedness of the Perl::Dist object is checked automatically
be default using L<LWP::Online|LWP::Online>. It can be overidden 
by providing the C<offline> parameter to new().

The C<offline> accessor returns true if no connection to "the internet"
is available and the object will run in offline mode, or false
otherwise.

=cut

has 'offline' => (
	is      => 'ro',
	isa     => Bool,
	default => sub { return !!LWP::Online::offline() },
);



=head4 trace

The optional C<trace> parameter sets the level of tracing that is output.

Setting this parameter to 0 prints out only MAJOR stuff and errors.

Setting this parameter to a number between 2 and 5 will progressively
print out more information about the build.

Numbers above 2 are only needed for debugging purposes.

Default is 1 if not set.

=cut

has 'trace' => (
	is      => 'ro',
	isa     => Int,
	default => 1,
);



=head4 tasklist

The optional C<tasklist> parameter specifies the list of routines that the 
object can do.  The routines are object methods of Perl::Dist::WiX (or its 
subclasses) that will be executed in order, without parameters, and their 
task numbers (as used in Perl::Dist::WiX) will begin with 1 and increment in sequence.

Task routines should either return 1, or throw an exception. 

The default task list for Perl::Dist::WiX is as shown below.  Subclasses 
should provide their own list and insert their tasks in this list, rather 
than overriding routines shown above.

	tasklist => [

		# Final initialization
		'final_initialization',

		# Install the core C toolchain
		'install_c_toolchain',

		# Install the Perl binary
		'install_perl',

		# Install the Perl toolchain
		'install_perl_toolchain',

		# Install additional Perl modules
		'install_cpan_upgrades',

		# Check for missing files.
		'verify_msi_file_contents',

		# Apply optional portability support
		'install_portable',

		# Apply optional relocation support
		'install_relocatable',

		# Remove waste and temporary files
		'remove_waste',

		# Regenerate file fragments
		'regenerate_fragments',

		# Find file ID's for relocation.
		'find_relocatable_fields',

		# Write out the merge module
		'write_merge_module',

		# Install the Win32 extras
		'install_win32_extras',

		# Create the distribution list
		'create_distribution_list',

		# Check for missing files.
		'verify_msi_file_contents',

		# Regenerate file fragments again.
		'regenerate_fragments',

		# Write out the distributions
		'write',
	];


=cut

has 'tasklist' => (
	is      => 'ro',
	isa     => ArrayRef [Str],
	builder => '_build_tasklist',
);

sub _build_tasklist {
	return [

		# Final initialization
		'final_initialization',

		# Install the core C toolchain
		'install_c_toolchain',

		# Install the Perl binary
		'install_perl',

		# Install the Perl toolchain
		'install_perl_toolchain',

		# Install additional Perl modules
		'install_cpan_upgrades',

		# Check for missing files.
		'verify_msi_file_contents',

		# Apply optional portability support
		'install_portable',

		# Apply optional relocation support
		'install_relocatable',

		# Remove waste and temporary files
		'remove_waste',

		# Regenerate file fragments
		'regenerate_fragments',

		# Find file ID's for relocation.
		'find_relocatable_fields',

		# Write out the merge module
		'write_merge_module',

		# Install the Win32 extras
		'install_win32_extras',

		# Create the distribution list
		'create_distribution_list',

		# Check for missing files.
		'verify_msi_file_contents',

		# Regenerate file fragments again.
		'regenerate_fragments',

		# Write out the distributions
		'write',
	];
} ## end sub _build_tasklist



=head4 user_agent

The optional C<user_agent> parameter stores the L<LWP::UserAgent|LWP::UserAgent> 
object (or an object of a subclass of LWP::UserAgent) that Perl::Dist::WiX 
uses to download files.

The default creates an L<user_agent_cache|/user_agent_cache>
parameter.

=cut

has 'user_agent' => (
	is  => 'ro',
	isa => class_type(
		'LWP::UserAgent',
		{   message => sub {'Invalid user_agent'}
		}
	),
	lazy    => 1,
	writer  => '_set_user_agent',
	builder => '_build_user_agent',
	clearer => '_clear_user_agent',
);

sub _build_user_agent {
	my $self  = shift;
	my $class = ref $self;

	# Get the real class name after MooseX::Object::Pluggable
	# has messed with it.
	if ( $class =~ /MOP/ms ) {
		$class = $self->_original_class_name();
	}

	my $ua = LWP::UserAgent->new(
		agent => "$class/" . ( $VERSION || '0.00' ),
		timeout       => 30,
		show_progress => 1,
	);

	$ENV{HTTP_PROXY} and $ua->proxy( http => $ENV{HTTP_PROXY} );

	return $ua;
} ## end sub _build_user_agent



=head3 Parameters that describe the distribution to build.

These parameters specify the names/e-mails/etcetera used in making the distribution.

Some of these parameters are given no defaults by C<Perl::Dist::WiX>, so either
a subclass has to set these parameters, or they have to be specified.

=head4 app_id

The I<required> C<app_id> parameter provides the base identifier of the 
distribution that is used in constructing filenames by default.  This must 
be a legal Perl identifier (no spaces, for example.) 

=cut

has 'app_id' => (
	is  => 'ro',                       # String that passes _IDENTIFIER
	isa => subtype(
		Str => where { _IDENTIFIER($_) },
		message {'app_id must be a legal Perl identifier'}
	),
	required => 1,
);



=head4 app_name

The I<required> C<app_name> parameter provides the name of the distribution.

=cut

has 'app_name' => (
	is       => 'ro',
	isa      => Str,
	required => 1,
);



=head4 app_publisher

The I<required> C<app_publisher> parameter provides the publisher of the 
distribution. 

=cut

has 'app_publisher' => (
	is       => 'ro',
	isa      => Str,
	required => 1,
);



=head4 app_publisher_url

The I<required> C<app_publisher_url> parameter provides the URL of the 
publisher of the distribution.

It can be a string or a URI object.

=cut

has 'app_publisher_url' => (
	is       => 'ro',
	isa      => Uri,
	coerce   => 1,
	required => 1,
);



=head4 app_ver_name

The optional C<app_ver_name> parameter provides the name and version of 
the distribution. 

The default value for this parameter is assembled from C<app_name> and 
C<perl_version_human>.

=cut

has 'app_ver_name' => (
	is      => 'ro',
	isa     => Str,
	lazy    => 1,
	builder => '_build_app_ver_name',
);

sub _build_app_ver_name {
	my $self = shift;
	return $self->app_name() . q{ } . $self->perl_version_human();
}



=head4 beta_number

The optional integer C<beta_number> parameter is used to set the beta number
portion of the distribution's version number (if this is a beta distribution), 
and is used in constructing filenames.

It defaults to 0 if not set, which will construct distributions without a beta
number.

=cut

has 'beta_number' => (
	is      => 'ro',
	isa     => Int,
	default => 0,
);



=head4 bits

The optional C<bits> parameter specifies whether the perl being built is 
for 32-bit (i386) or 64-bit (referred to as Intel64 / amd-x64) Windows

32-bit (i386) is the default.

=cut

has 'bits' => (
	is  => 'ro',                       # Integer 32/64
	isa => subtype(
		'Int' => where {
			if ( not defined $_ ) {
				$_ = 32;
			}

			$_ == 32 or $_ == 64;
		},
		message {
			'Not 32 or 64-bit';
		},
	),
	default => 32,
);



=head4 build_number

The I<required> integer C<build_number> parameter is used to set the build 
number portion of the distribution's version number, and is used in 
constructing filenames.

=cut

has 'build_number' => (
	is  => 'ro',
	isa => subtype(
		'Int' => where { $_ < 127 and $_ >= 0 },
		message {'Build number must be between 0 and 127'}
	),
	required => 1,
);



=head4 default_group_name

The optional name for the Start menu group that the distribution's installer 
installs its shortcuts to.  Defaults to C<app_name> if none is provided.

=cut

has 'default_group_name' => (
	is      => 'ro',
	isa     => Str,
	lazy    => 1,
	default => sub {
		my $self = shift;
		return $self->app_name();
	},
);



=head4 gcc_version

The optional C<gcc_version> parameter specifies whether perl is being built 
using gcc 3.4.5 from the mingw32 project (by specifying a value of '3'), or 
using gcc 4.4.3 from the mingw64 project (by specifying a value of '4'). 

'3' (gcc 3.4.5) is the default, and is incompatible with C<< L<bits|/bits> 
=> 64 >>. '4' is compatible with both 32 and 64-bit, but is incompatible with
C<< L<perl_version|/perl_version> => 5100 5101 >>.

=cut

has 'gcc_version' => (
	is  => 'ro',
	isa => subtype(
		'Int' => where { $_ == 3 or $_ == 4 },
		message {'Not 3 or 4'}
	),
	default => 3,
);



=head4 msi_debug

The optional boolean C<msi_debug> parameter is used to indicate that
a debugging MSI (one that creates a log in $ENV{TEMP} upon execution
in Windows Installer 4.0 or above) will be created if C<msi> is also 
true.

This defaults to false.

=cut

has 'msi_debug' => (
	is      => 'ro',
	isa     => Bool,
	default => 0,
);



=head4 msi_exit_text

The optional C<msi_exit_text> parameter is used to customize the text
that the MSI shows on its last screen.

The default says: "Before you start using Perl, please read the README 
file."

=cut

has 'msi_exit_text' => (
	is      => 'ro',
	isa     => Str,
	default => 'Before you start using Perl, please read the README file.',
);



=head4 msi_install_warning_text

Returns the text that the MSI needs to use when not able to relocate.

=cut

has 'msi_install_warning_text' => (
	is      => 'ro',
	isa     => Str,
	lazy    => 1,
	builder => '_build_msi_install_warning_text',
);

sub _build_msi_install_warning_text {
	my $self = shift;

	my $app_name = $self->app_name();
	my $location = $self->image_dir()->stringify();
	my $url      = $self->app_publisher_url();

	return
"NOTE: This version of $app_name can only be installed to $location. If this is a problem, please download another version from $url.";
}



=head4 msi_run_readme_txt

Specifies whether to give the option to run a README.txt file when the 
installation is completed.

=cut

has 'msi_run_readme_txt' => (
	is      => 'ro',
	isa     => Bool,
	default => 0,
);



=head4 output_base_filename

The optional C<output_base_filename> parameter specifies the filename 
(without extensions) that is used for the installer(s) being generated.

The default is based on C<app_id()>, C<perl_version()>, C<bits()>, and the 
current date.

=cut

has 'output_base_filename' => (
	is      => 'ro',
	isa     => Str,
	lazy    => 1,
	builder => '_build_output_base_filename',
);

# Default the output filename to the id plus the current date
sub _build_output_base_filename {
	my $self = shift;

	my $bits = ( 64 == $self->bits ) ? q{64bit-} : q{};

	return
	    $self->app_id() . q{-}
	  . $self->perl_version_human() . q{-}
	  . $bits
	  . $self->output_date_string();
}



=head4 perl_config_cf_email

The optional C<perl_config_cf_email> parameter specifies the e-mail
of the person building the perl distribution defined by this object.

It is compiled into the perl binary as the C<cf_email> option accessible
through C<perl -V:cf_email>.

The username (the part before the at sign) of this parameter also sets the
C<cf_by> option.

If not defined, this is set to anonymous@unknown.builder.invalid.

=cut

has 'perl_config_cf_email' => (
	is  => 'ro',                       # E-mail address
	isa => subtype(
		Str => where { $_ =~ m/\A.*@.*\z/msx },
		message {
			'perl_config_cf_email must be in the form of an e-mail address';
		}
	),
	default => 'anonymous@unknown.builder.invalid',
);



=head4 perl_config_cf_by

The optional C<perl_config_cf_email> parameter specifies the username part
of the e-mail address of the person building the perl distribution defined 
by this object.

It is compiled into the perl binary as the C<cf_by> option accessible
through C<perl -V:cf_by>.

If not defined, this is set to the username part of C<perl_config_cf_email>.

=cut

has 'perl_config_cf_by' => (
	is      => 'ro',
	isa     => Str,
	lazy    => 1,
	builder => '_build_perl_config_cf_by',
);

sub _build_perl_config_cf_by {
	my $self = shift;
	return $self->perl_config_cf_email() =~ m/\A(.*)@.*\z/msx;
}



=head4 perl_debug

The optional boolean C<perl_debug> parameter is used to indicate that
a debugging perl interpreter will be created.

This only applies to 5.12.0 and later as of yet.

=cut

has 'perl_debug' => (
	is      => 'ro',
	isa     => Bool,
	default => 0,
);



=head4 perl_version

The C<perl_version> parameter specifies what version of perl is downloaded 
and built.  Legal values for this parameter are 'git', '5100', '5101', 
'5120', and '5121' (for a version from perl5.git.perl.org, 5.10.0, 
5.10.1, and 5.12.1, respectively.)

This parameter defaults to '5101' if not specified.

=cut

has 'perl_version' => (
	is      => 'ro',
	isa     => Str,
	default => '5101',
);



=head4 sitename

The optional C<sitename> parameter is used to generate the GUID's necessary
during the process of building the distribution.

This defaults to the host part of C<app_publisher_url>.

=cut

has 'sitename' => (
	is       => 'ro',                  # Hostname
	isa      => Str,
	required => 1,                     # Default is provided in BUILDARGS.
);



=head4 smoketest

The optional boolean C<smoketest> parameter is used to indicate that
a 'smoketest' marked perl interpreter will be created.

=cut

has 'smoketest' => (
	is      => 'ro',
	isa     => Bool,
	default => 0,
);



=head4 use_dll_relocation

The optional C<use_dll_relocation> parameter specifies whether to use the
C++ relocation dll that's being tested for relocating perl, or to call a 
Perl relocation script from the .msi's.

This parameter has no effect is the C<msi> parameter is false, or if the
C<relocatable> parameter is false.

If this variable is false, the Perl relocation script is used instead.
(The default is true.)

=cut

has 'use_dll_relocation' => (
	is      => 'ro',
	isa     => Bool,
	default => 1,
);



=head3 Directories, files, and URLs used in building.

These parameters specify which directories and files are used when building 
a distribution.

At a minimum, L<image_dir|/image_dir> is required, which specifies where Perl
will be installed (by default, in the case where L<relocatable|/relocatable>
is true.) All other options have defaults, most of the time.

=head4 binary_root

The optional C<binary_root> accessor is the URL (as a string, not including 
the filename) where the distribution will find its libraries to download.

Defaults to 'http://strawberryperl.com/package' unless C<offline> is set, 
in which case it defaults to C<download_dir()>.

=cut

has 'binary_root' => (
	is      => 'ro',
	isa     => Uri,
	coerce  => 1,
	lazy    => 1,
	builder => '_build_binary_root',
);

sub _build_binary_root {
	my $self = shift;

	if ( $self->offline() ) {
		return URI::file->new( $self->download_dir() );
	} else {
		return 'http://strawberryperl.com/package';
	}
}


=head4 build_dir

The optional directory where the source files for the distribution will 
be extracted and built from.

Defaults to C<temp_dir> . '\build', and must exist if given.

=cut

has 'build_dir' => (
	is      => 'ro',
	isa     => ExistingDirectory_SaneSlashes,
	coerce  => 1,
	lazy    => 1,
	builder => '_build_build_dir',
);

sub _build_build_dir {
	my $self = shift;

	my $dir = catdir( $self->temp_dir(), 'build' );
	$self->remake_path($dir);
	return $dir;
}



=head4 cpan

The optional C<cpan> param provides a path to a CPAN or minicpan mirror 
that the installer can use to fetch any needed files during the build
process.

The param should be a L<URI|URI> object to the root of the CPAN repository,
including trailing slash.  Strings will be coerced to URI objects.

If you are online, the value will default to the 
L<http://cpan.strawberryperl.com> repository as a convenience.

If you are offline, it defaults to using a CPAN mirror at C<C:\minicpan\>.

=cut

has 'cpan' => (
	is      => 'ro',
	isa     => Uri,
	lazy    => 1,
	coerce  => 1,
	builder => '_build_cpan',
);

sub _build_cpan {
	my $self = shift;

	# If we are online and don't have a cpan repository,
	# use cpan.strawberryperl.com as a default.
	if ( $self->offline() ) {
		return URI::file->new('C:\\minicpan\\'),;
	} else {
		return URI->new('http://cpan.strawberryperl.com/');
	}

	return;
} ## end sub _build_cpan




=head4 debug_stderr

The optional C<debug_stderr> parameter is used to set the location of the 
file that STDERR is redirected to when the perl tarball and perl modules 
are built.

The default location is in C<debug.err> in the 
C<< L<output_dir|/output_dir> >>.


=cut

has 'debug_stderr' => (
	is      => 'ro',
	isa     => File,
	lazy    => 1,
	coerce  => 1,
	default => sub {
		my $self = shift;
		return $self->output_dir()->file('debug.err');
	},
);



=head4 debug_stdout

The optional C<debug_stdout> parameter is used to set the location of the
file that STDOUT is redirected to when the perl tarball and perl modules
are built.

The default location is in C<debug.out> in the 
C<< L<output_dir|/output_dir> >>.

=cut

has 'debug_stdout' => (
	is      => 'ro',
	isa     => File,
	lazy    => 1,
	coerce  => 1,
	default => sub {
		my $self = shift;
		return $self->output_dir()->file('debug.out');
	},
);



=head4 download_dir 

The optional C<download_dir> parameter sets the location of the directory 
that packages of various types will be downloaded and cached to.

Defaults to C<temp_dir . '\download'>, and must exist if given.

=cut

has 'download_dir' => (
	is      => 'ro',
	isa     => ExistingDirectory_Spaceless,
	coerce  => 1,
	lazy    => 1,
	builder => '_build_download_dir',
);

sub _build_download_dir {
	my $self = shift;

	my $dir = catdir( $self->temp_dir(), 'download' );
	$self->make_path($dir);
	return $dir;
}



=head4 fragment_dir

The optional subdirectory of L<temp_dir|/temp_dir> where the .wxs fragment 
files for the different portions of the distribution will be created. 

Defaults to C<temp_dir . '\fragments'>, and needs to exist if given.

=cut

has 'fragment_dir' => (
	is      => 'ro',
	isa     => ExistingDirectory_SaneSlashes,
	lazy    => 1,
	coerce  => 1,
	builder => '_build_fragment_dir',
);

sub _build_fragment_dir {
	my $self = shift;

	my $dir = catdir( $self->temp_dir(), 'fragments' );
	$self->remake_path($dir);
	return Path::Class::Dir->new($dir);
}



=head4 git_checkout

The optional C<git_checkout> parameter is not used unless you specify 
that C<perl_version> is a plugin that implements building from a git 
checkout. In that event, this parameter should contain a string 
pointing to the location of a checkout from L<http://perl5.git.perl.org/>.

The default is C<'C:\perl-git'>, if it exists.

=cut

has 'git_checkout' => (
	is      => 'ro',
	isa     => Undef | ExistingDirectory_Spaceless,
	builder => '_build_git_checkout',
	coerce  => 1,
);

sub _build_git_checkout {
	my $dir = q{C:\\perl-git};

	if ( -d $dir ) {
		return Path::Class::Dir->new($dir);
	} else {
		## no critic (ProhibitExplicitReturnUndef)
		return undef;
	}
}



=head4 git_location

The optional C<git_location> parameter is not used unless you specify 
that C<perl_version> is 'git'. In that event, this parameter should 
contain a string pointing to the location of the git.exe binary, as because
a perl.exe file is in the same directory, it gets removed from the PATH 
during the execution of programs from Perl::Dist::WiX.
 
The default is 'C:\Program Files\Git\bin\git.exe', if it exists.  Otherwise,
the default is undef.

People on x64 systems should set this to 
C<'C:\Program Files (x86)\Git\bin\git.exe'> unless MSysGit is installed 
in a different location (or a 64-bit version becomes available).

This will be converted to a short name before execution, so this must 
NOT be on a partition that does not have them, unless the location does
not have spaces.

=cut

has 'git_location' => (
	is      => 'ro',
	isa     => Undef | ExistingFile,
	builder => '_build_git_location',
	coerce  => 1,
);

sub _build_git_location {
	my $file = 'C:\\Program Files\\Git\\bin\\git.exe';

	if ( -f $file ) {
		return $file;
	} else {
		## no critic (ProhibitExplicitReturnUndef)
		return undef;
	}
}



=head4 image_dir

The I<required> C<image_dir> method specifies the location of the Perl install,
both on the author's and end-user's host.

Please note that this directory will be automatically deleted if it
already exists at object creation time. Trying to build a Perl
distribution on the SAME distribution can thus have devastating
results, and an attempt is made to prevent this from happening.

Perl::Dist::WiX distributions can only be installed to fixed paths
as of yet, unless C<relocatable()|/relocatable> is true.

To facilitate a correctly working CPAN setup, the files that will
ultimately end up in the installer must also be assembled under the
same (default, in the C<relocatable> case) path on the author's machine.

=cut

has 'image_dir' => (
	is       => 'ro',
	isa      => ExistingSubdirectory,
	coerce   => 1,
	required => 1,
);



=head4 license_dir

The optional subdirectory of L<image_dir|/image_dir> where the licenses for 
the different portions of the distribution will be copied to. 

Defaults to C<image_dir . '\licenses'>, and needs to exist if given.

=cut

has 'license_dir' => (
	is      => 'ro',
	isa     => ExistingDirectory_Spaceless,
	lazy    => 1,
	coerce  => 1,
	builder => '_build_license_dir',
);

sub _build_license_dir {
	my $self = shift;

	my $dir = $self->image_dir()->subdir('licenses');
	if ( not -d "$dir" ) {
		$self->remake_path("$dir");
	}
	return $dir;
}

=head4 modules_dir

The optional C<modules_dir> parameter sets the location of the directory 
that perl modules will be downloaded and cached to.

Defaults to C<download_dir . '\modules'>, and must exist if given.

=cut

has 'modules_dir' => (
	is      => 'ro',
	isa     => ExistingDirectory_Spaceless,
	lazy    => 1,
	builder => '_build_modules_dir',
);

sub _build_modules_dir {
	my $self = shift;

	my $dir = $self->download_dir()->subdir('modules');
	$self->remake_path("$dir");
	return $dir;
}




=head4 msi_banner_side

The optional C<msi_banner_side> parameter specifies the location of 
a 493x312 .bmp file that is used in the introductory dialog in the MSI 
file.

WiX will use its default if no file is supplied here.

=cut

has 'msi_banner_side' => (
	is      => 'ro',
	isa     => Undef | ExistingFile,
	coerce  => 1,
	default => undef,
);



=head4 msi_banner_top

The optional C<msi_banner_top> parameter specifies the location of a 
493x58 .bmp file that is  used on the top of most of the dialogs in 
the MSI file.

WiX will use its default if no file is supplied here.

=cut

has 'msi_banner_top' => (
	is      => 'ro',
	isa     => Undef | ExistingFile,
	coerce  => 1,
	default => undef,
);



=head4 msi_help_url

The optional C<msi_help_url> parameter specifies the URL that 
Add/Remove Programs directs you to for support when you click 
the "Click here for support information." text.

This defaults to not setting a URL.

=cut

has 'msi_help_url' => (
	is      => 'ro',
	isa     => Uri | Undef,            # Maybe[ Uri ] will not work.
	                                   # Unions inherit coercions,
	                                   # parameterized types don't.
	coerce  => 1,
	default => undef,
);



=head4 msi_license_file

The optional C<msi_license_file> parameter specifies the location of an 
.rtf or .txt file to be displayed at the point where the MSI asks you 
to accept a license.

Perl::Dist::WiX provides a default filename if none is supplied here.

=cut

has 'msi_license_file' => (
	is      => 'ro',
	isa     => ExistingFile,
	lazy    => 1,
	coerce  => 1,
	default => sub {
		my $self = shift;
		return catfile( $self->wix_dist_dir(), 'License.rtf' );
	},
);



=head4 msi_product_icon

The optional C<msi_product_icon> parameter specifies the icon that is 
used in Add/Remove Programs for this MSI file.

The default Windows Installer icon is used if none is specified here.

=cut

has 'msi_product_icon' => (
	is      => 'ro',
	isa     => Undef | ExistingFile,
	coerce  => 1,
	default => undef,
);



=head4 msi_readme_file

The optional C<msi_readme_file> parameter specifies a .txt or .rtf file 
or a URL (TODO: check) that is linked in Add/Remove Programs in the 
"Click here for support information." text.

There is no file linked if none is specified here.

=cut

has 'msi_readme_file' => (
	is      => 'ro',
	isa     => Undef | ExistingFile,
	coerce  => 1,
	default => undef,
);



=head4 output_dir

This optional C<output_dir> parameter sets the location where the compiled 
installers and other files necessary to the build are written.

Defaults to C<temp_dir() . '\output'>, and must exist when given.

=cut

has 'output_dir' => (
	is      => 'ro',
	isa     => ExistingDirectory_SaneSlashes,
	lazy    => 1,
	coerce  => 1,
	builder => '_build_output_dir',
);

sub _build_output_dir {
	my $self = shift;

	my $dir = $self->temp_dir()->subdir('output');
	$self->make_path("$dir");
	return $dir;
}



=head4 temp_dir

B<Perl::Dist::WiX> needs a series of temporary directories while
it is running the build, including places to cache downloaded files,
somewhere to expand tarballs to build things, and somewhere to put
debugging output and the final installer zip and msi files.

The optional C<temp_dir> parameter specifies the root path for where 
these temporary directories should be created.

For convenience it is best to make these short paths with simple
names, near the root.

This parameter defaults to a subdirectory of $ENV{TEMP} if not specified.

=cut

has 'temp_dir' => (
	is     => 'ro',
	isa    => ExistingDirectory_SaneSlashes,
	coerce => 1,
	default =>
	  sub { return Path::Class::Dir->new( catdir( tmpdir(), 'perldist' ) ) }
	,
);



=head4 tempenv_dir

The processes that B<Perl::Dist::WiX> executes sometimes need
a place to put their temporary files, usually in $ENV{TEMP}.

The optional C<tempenv_dir> parameter specifies the location to
put those files.

This parameter defaults to a subdirectory of temp_dir() if not specified.

=cut

has 'tempenv_dir' => (
	is      => 'ro',
	isa     => ExistingDirectory_SaneSlashes,
	lazy    => 1,
	coerce  => 1,
	builder => '_build_tempenv_dir',
);

sub _build_tempenv_dir {
	my $self = shift;

	my $dir = $self->temp_dir()->subdir('tempenv');
	$self->remake_path("$dir");
	return $dir;
}



=head3 Using a merge module

Subclasses can start building a perl distribution from a merge module, 
instead of having to build perl from scratch.

This means that the distribution can:

1) update the version of Perl installed using the merge module.

2) be installed on top of another distribution using that merge module (or 
an earlier version of it).

The next 5 options specify the information required to use a merge module.

=head4 fileid_perl

The optional C<fileid_perl> parameter helps the relocation find the perl 
executable.

If the merge module is being built, this is set by the 
L<install_relocatable|/install_relocatable> method.

If the merge module is being used, it needs to be passed in to new().

=head4 fileid_perl_h

TODO

=cut

has 'fileid_perl' => (
	is      => 'ro',
	isa     => Str,
	writer  => '_set_fileid_perl',
	default => q{},
);

sub fileid_perl_h {
	my $self    = shift;
	my $perl_id = $self->fileid_perl();
	return q{[#} . $perl_id . q{]};
}

=head4 fileid_relocation_pl

The optional C<fileid_relocation_pl> parameter helps the relocation find 
the relocation script.

If the merge module is being built, this is set by the 
L<install_relocatable|/install_relocatable> method.

If the merge module is being used, it needs to be passed in to new().

=head4 fileid_relocation_pl_h

TODO

=cut

has 'fileid_relocation_pl' => (
	is      => 'ro',
	isa     => Str,
	writer  => '_set_fileid_relocation_pl',
	default => q{},
);

sub fileid_relocation_pl_h {
	my $self      = shift;
	my $script_id = $self->fileid_relocation_pl();
	return q{[#} . $script_id . q{]};
}


=head4 msm_code

The optional C<msm_code> parameter is used to specify the product code
for the merge module referred to in C<msm_to_use>.

C<msm_to_use>, C<msm_zip>, and this parameter must either be all unset, 
or all set. They must be all set if C<initialize_using_msm> is in the 
tasklist.

=cut

has 'msm_code' => (
	is      => 'ro',
	isa     => Maybe [Str],
	writer  => '_set_msm_code',
	default => undef,
);



=head4 msm_to_use

The optional C<msm_to_use> parameter is the location of a merge module 
to use when linking the .msi.

It can be specified as a string, a L<Path::Class::File|Path::Class::File> 
object, or a L<URI|URI> object. 

=cut

has 'msm_to_use' => (
	is      => 'ro',
	isa     => Uri | Undef,
	default => undef,
	coerce  => 1,
);



=head4 msm_zip

The optional C<msm_zip> refers to where the .zip version of Strawberry Perl 
that matches the merge module specified in C<msm_to_use> 

It can be a file:// URL if it's already downloaded.

It can be specified as a string, a L<Path::Class::File|Path::Class::File> 
object, or a L<URI|URI> object. 

=cut

has 'msm_zip' => (
	is      => 'ro',
	isa     => Uri | Undef,
	default => undef,
	coerce  => 1,
);



=head3 Checkpointing builds.

To speed up debugging of a distribution build, that distribution can be 
checkpointed, and then restarted from that checkpoint.

These parameters control the checkpointing process.

=head4 checkpoint_after

The optional parameter C<checkpoint_after> is an arrayref of task numbers.  
After each task in the list, Perl::Dist::WiX will stop and save a 
checkpoint.

[ 0 ] is the default, meaning that you do not wish to save a checkpoint anywhere.

=cut

has 'checkpoint_after' => (
	is      => 'ro',
	isa     => ArrayRef [Int],
	writer  => '_set_checkpoint_after',
	default => sub { return [0] },
);



=head4 checkpoint_before

The optional parameter C<checkpoint_before> is given an integer to know 
when to load a checkpoint. Unlike the other parameters that deal with 
checkpointing, this is based on the task number that is GOING to execute, 
rather than the task number that just executed, so that if a checkpoint 
was saved after (for example) task 5, this parameter should be 6
in order to load the checkpoint and start on task 6.

0 is the default, meaning that you do not wish to load a checkpoint.

=cut

has 'checkpoint_before' => (
	is      => 'ro',
	isa     => Int,
	writer  => '_set_checkpoint_before',
	default => 0,
);



=head4 checkpoint_dir

The optional directory where Perl::Dist::WiX will store its 
checkpoints. 

Defaults to C<temp_dir> . '\checkpoint', and must exist if given.

=cut

has 'checkpoint_dir' => (
	is      => 'ro',
	isa     => ExistingDirectory,
	lazy    => 1,
	builder => '_build_checkpoint_dir',
);

sub _build_checkpoint_dir {
	my $self = shift;
	my $dir  = $self->temp_dir()->subdir('checkpoint');
	if ( not -d "$dir" ) {
		$self->remake_path("$dir");
	}
	return $dir;
}



=head4 checkpoint_stop

The optional parameter C<checkpoint_stop> stops execution after the 
specified task if no error has happened before then.

0 is the default, meaning that you do not wish to stop unless an error 
occurs.

=cut

has 'checkpoint_stop' => (
	is      => 'ro',
	isa     => Int,
	writer  => '_set_checkpoint_stop',
	default => 0,
);



sub BUILDARGS {
	my $class = shift;
	my %params;

	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%params = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%params = (@_);
	} else {
		PDWiX::ParametersNotHash->throw( where => '->new()' );
	}

	## no critic(ProtectPrivateSubs RequireCarping RequireUseOfExceptions)
	eval {
		$params{_trace_object} ||=
		  WiX3::Traceable->new( tracelevel => $params{trace} );
		1;
	} || eval {
		WiX3::Trace::Object->_clear_instance();
		WiX3::Traceable->_clear_instance();
		$params{_trace_object} ||=
		  WiX3::Traceable->new( tracelevel => $params{trace} );
	} || die 'Could not create trace object';

	# Announce that we're starting.
	{
		my $time = scalar localtime;
		$params{_trace_object}
		  ->trace_line( 0, "Starting build at $time.\n" );
	}

	# Get the parameters required for the GUID generator set up.
	if (    not _STRING( $params{app_publisher_url} )
		and not _INSTANCE( $params{app_publisher_url}, 'URI' ) )
	{
		PDWiX::Parameter->throw(
			parameter => 'app_publisher_url',
			where     => '->new'
		);
	}

	# Convert a string to a URI object.
	if ( _STRING( $params{app_publisher_url} ) ) {
		$params{app_publisher_url} = URI->new( $params{app_publisher_url} );
	}

	# Default the sitename unless it is given.
	if ( not _STRING( $params{sitename} ) ) {
		$params{sitename} = $params{app_publisher_url}->host();
	}

	# Create the GUID generator.
	$params{_guidgen} ||=
	  WiX3::XML::GeneratesGUID::Object->new(
		_sitename => $params{sitename} );

	if ( defined $params{image_dir} ) {
		my $perl_location = lc Probe::Perl->find_perl_interpreter();
		$params{_trace_object}
		  ->trace_line( 3, "Currently executing perl: $perl_location\n" );
		my $our_perl_location =
		  lc catfile( $params{image_dir}, qw(perl bin perl.exe) );
		$params{_trace_object}->trace_line( 3,
			"Our perl to create:       $our_perl_location\n" );

		if ( $our_perl_location eq $perl_location ) {
			PDWiX::Parameter->throw(
				parameter => 'image_dir : attempting to commit suicide',
				where     => '->new'
			);
		}

		# We don't want to delete a previous one yet.
		$class->make_path( $params{image_dir} );
	} else {
		PDWiX::Parameter->throw(
			parameter => 'image_dir: is not defined',
			where     => '->new'
		);
	}

	if ( $params{app_name} =~ m{[\\/:*"<>|]}msx ) {
		PDWiX::Parameter->throw(
			parameter => 'app_name: Contains characters invalid '
			  . 'for Windows file/directory names',
			where => '->new'
		);
	}

	return \%params;
} ## end sub BUILDARGS



# This is called by Moose's DESTROY, and handles moving the CPAN source
# files back.
sub DEMOLISH {
	my $self = shift;

	if ( $self->_has_moved_cpan() ) {
		my $x = eval {
			$self->remove_path( $self->_cpan_sources_from() );
			File::Copy::Recursive::move( $self->_cpan_sources_to(),
				$self->_cpan_sources_from() );
		};
	}

	return;
} ## end sub DEMOLISH



################################################################
#
# Private attributes. (Ones that have no public accessors or
# are not valid parameters for new().)
#

# Reserved for a future parameter to new()
has 'msi_feature_tree' => (
	is       => 'ro',
	isa      => Maybe [ArrayRef],
	default  => undef,
	init_arg => undef,
);



has '_toolchain' => (
	is       => 'bare',
	isa      => 'Maybe[Perl::Dist::WiX::Toolchain]',
	reader   => '_get_toolchain',
	writer   => '_set_toolchain',
	init_arg => undef,
);



has '_build_start_time' => (
	is       => 'ro',
	isa      => Int,
	default  => time,
	init_arg => undef,                 # Cannot set this parameter in new().
);



has '_distributions' => (
	traits   => ['Array'],
	is       => 'bare',
	isa      => ArrayRef [Str],
	default  => sub { return [] },
	init_arg => undef,
	handles  => {
		'_add_distribution'  => 'push',
		'_get_distributions' => 'elements',
	},
);



has '_env_path' => (
	traits   => ['Array'],
	is       => 'bare',
	isa      => ArrayRef [ ArrayRef [Str] ],
	default  => sub { return [] },
	init_arg => undef,
	handles  => {
		'add_path'                => 'push',
		'_get_env_path_unchecked' => 'elements',
	},
);



has '_filters' => (
	is       => 'ro',
	isa      => ArrayRef [Str],
	lazy     => 1,
	builder  => '_build_filters',
	init_arg => undef,
);

sub _build_filters {
	my $self = shift;

	# Initialize filters.
#<<<
	return [   $self->temp_dir() . q{\\},
	  $self->dir(  qw{ perl man         } ) . q{\\},
	  $self->dir(  qw{ perl html        } ) . q{\\},
	  $self->dir(  qw{ c    man         } ) . q{\\},
	  $self->dir(  qw{ c    doc         } ) . q{\\},
	  $self->dir(  qw{ c    info        } ) . q{\\},
	  $self->dir(  qw{ c    contrib     } ) . q{\\},
	  $self->dir(  qw{ c    html        } ) . q{\\},
	  $self->dir(  qw{ c    examples    } ) . q{\\},
	  $self->dir(  qw{ c    manifest    } ) . q{\\},
	  $self->dir(  qw{ cpan sources     } ) . q{\\},
	  $self->dir(  qw{ cpan build       } ) . q{\\},
	  $self->dir(  qw{ c    bin         startup mac   } ) . q{\\},
	  $self->dir(  qw{ c    bin         startup msdos } ) . q{\\},
	  $self->dir(  qw{ c    bin         startup os2   } ) . q{\\},
	  $self->dir(  qw{ c    bin         startup qssl  } ) . q{\\},
	  $self->dir(  qw{ c    bin         startup tos   } ) . q{\\},
	  $self->dir(  qw{ c    libexec     gcc     mingw32 3.4.5 install-tools}) . q{\\},
	  $self->file( qw{ c    COPYING     } ),
	  $self->file( qw{ c    COPYING.LIB } ),
	  $self->file( qw{ c    bin         gccbug  } ),
	  $self->file( qw{ c    bin         mingw32-gcc-3.4.5  } ),
	  $self->file( qw{ cpan FTPstats.yml  } ),
	  ];
#>>>
} ## end sub _build_filters



has '_in_merge_module' => (
	is       => 'ro',
	isa      => Bool,
	default  => 1,
	init_arg => undef,
	writer   => '_set_in_merge_module',
);



has '_perl_version_corelist' => (
	is       => 'ro',
	isa      => Maybe [HashRef],
	lazy     => 1,
	builder  => '_build_perl_version_corelist',
	init_arg => undef,
);



sub _build_perl_version_corelist {
	my $self = shift;

	# Find the core list
	my $corelist_version = $self->perl_version_literal() + 0;
	my $hash             = $Module::CoreList::version{$corelist_version};
	if ( not _HASH($hash) ) {
		PDWiX->throw( 'Failed to resolve Module::CoreList hash for '
			  . $self->perl_version_human() );
	}
	return $hash;
} ## end sub _build_perl_version_corelist



has 'pdw_version' => (
	is      => 'ro',
	isa     => Str,
	default => $Perl::Dist::WiX::VERSION,
	init_arg => undef,                 # Cannot set this parameter in new().
);



has '_guidgen' => (
	is  => 'ro',
	isa => 'WiX3::XML::GeneratesGUID::Object',
	required => 1,                     # Default is provided in BUILDARGS.
	writer   => '_set_guidgen',
	clearer  => '_clear_guidgen',
);



has '_trace_object' => (
	is       => 'ro',
	isa      => 'WiX3::Traceable',
	required => 1,
	writer   => '_set_trace_object',
	clearer  => '_clear_trace_object',
	handles  => {
		'trace_line'      => 'trace_line',
		'_set_tracelevel' => 'set_tracelevel',
	},
);



has _user_agent_directory => (
	is       => 'ro',
	isa      => ExistingDirectory,
	lazy     => 1,
	builder  => '_build_user_agent_directory',
	init_arg => undef,
);

sub _build_user_agent_directory {
	my $self = shift;

# Create a legal path out of the object's class name under
# {Application Data}/Perl.
	my $path = ref $self;
	$path =~ s{::}{-}gmsx;             # Changes all :: to -.
	my $dir =
	  File::Spec->catdir( File::HomeDir->my_data(), 'Perl', $path, );

	# Make the directory or die vividly.
	if ( not -d $dir ) {
		if ( not File::Path::mkpath( $dir, { verbose => 0 } ) ) {
			PDWiX::Directory->throw(
				dir     => $dir,
				message => 'Failed to create'
			);
		}
	}
	if ( not -w $dir ) {
		PDWiX::Directory->throw(
			dir     => $dir,
			message => 'No write permissions for LWP::UserAgent cache'
		);
	}
	return $dir;
} ## end sub _build_user_agent_directory



has '_cpan_moved' => (
	traits   => ['Bool'],
	is       => 'bare',
	isa      => Bool,
	reader   => '_has_moved_cpan',
	default  => 0,
	init_arg => undef,                 # Cannot set this parameter in new().
	handles => { '_move_cpan' => 'set', },
);



has '_cpan_sources_to' => (
	is       => 'ro',
	isa      => Maybe [Str],
	writer   => '_set_cpan_sources_to',
	default  => undef,
	init_arg => undef,                 # Cannot set this parameter in new().
);



has '_cpan_sources_from' => (
	is      => 'ro',
	isa     => Maybe [Str],
	writer  => '_set_cpan_sources_from',
	default => undef,
	init_arg => undef,                 # Cannot set this parameter in new().
);



has '_portable_dist' => (
	is      => 'ro',                   # String
	isa     => 'Maybe[Portable::Dist]',
	writer  => '_set_portable_dist',
	default => undef,
	init_arg => undef,                 # Cannot set this parameter in new().
);



has '_use_sqlite' => (
	is       => 'ro',
	isa      => Bool,
	init_arg => undef,
	lazy     => 1,
	default  => sub {
		my $self = shift;
		return ( defined $self->msm_to_use() ) ? 1 : 0;
	},
);


has '_all_files_object' => (
	is       => 'ro',
	isa      => 'File::List::Object',
	init_arg => undef,
	lazy     => 1,
	default  => sub { File::List::Object->new() },
);

# This comes from MooseX::Object::Pluggable, and sets up the
# fact that Perl::Dist::WiX::BuildPerl::* is where plugins happen to be.
has '+_plugin_ns' => ( default => 'BuildPerl', );



#####################################################################
# Top Level Process Methods

sub prepare { return 1 }

=pod

=head2 run

The C<run> method is the main method for the class.

It does a complete build of a product, spitting out an installer, by
running each method named in the tasklist in order.

Returns true, or throws an exception on error.

This method may take an hour or more to run.

=cut

sub run {
	my $self  = shift;
	my $start = time;

	if ( not( $self->msi() or $self->zip() ) ) {
		$self->trace_line('No msi or zip target, nothing to do');
		return 1;
	}

	# Don't buffer
	STDOUT->autoflush(1);
	STDERR->autoflush(1);

	# List plugins that we can load if we want to.
	my @plugins = $self->_plugin_locator()->plugins();
	$self->trace_line( 3,
		join( qq{\n  }, 'Plugins to build Perl with available:', @plugins )
		  . qq{\n} );

	my $version_plugin = $self->perl_version();
	if ( none {m{:: $version_plugin \z}msx} @plugins ) {
		PDWiX::Parameter->throw(
			parameter => 'perl_version: No plugin installed'
			  . " for the requested version of perl ($version_plugin)",
			where => '->run',
		);
	}

	# Load our perl-building plugin now, because
	# if we do it later, we end up losing data
	# in trait-attached hashrefs and arrayrefs.
	$self->load_plugins($version_plugin);

	my @task_list   = @{ $self->tasklist() };
	my $task_number = 1;
	my $task;
	my $answer = 1;

	while ( $answer and ( $task = shift @task_list ) ) {
		$answer = $self->checkpoint_task( $task => $task_number );
		$task_number++;
	}

	my $time_string = scalar localtime;

	# Finished
	$self->trace_line( 0,
		    'Distribution generation completed in '
		  . ( time - $start )
		  . " seconds (${time_string})\n" );
	foreach my $file ( $self->get_output_files ) {
		$self->trace_line( 0, "Created distribution $file\n" );
	}

	return 1;
} ## end sub run



#####################################################################
#
# Perl::Dist::WiX Main Methods
# (Those referred to in the tasklist.)
#

=head2 Methods used by C<run> in the tasklist.

	my $dist = Perl::Dist::WiX->new(
		tasklist => [
			'final_initialization',
			... 
		],
		...
	);

These methods are used in the tasklist, along with other methods that
are defined by C<Perl::Dist::WiX> or its subclasses.

=head3 final_initialization

The C<final_initialization> routine does the initialization that is 
required after the object representing a distribution has been created, but 
before files can be installed.

=cut

sub final_initialization {
	my $self = shift;

	# Check for architectures that we can't build 64-bit on.
	if ( 64 == $self->bits() ) {
		$self->_check_64_bit();
	}

	if (    $self->use_dll_relocation()
		and $self->relocatable()
		and not $self->can('msm_relocation_idlist') )
	{
		PDWiX::Parameter->throw(
			parameter => 'use_dll_relocation: Cannot use DLL relocation'
			  . ' without a relocation file id being available '
			  . '(set this parameter to 0)',
			where => '->final_initialization',
		);
	}

	# Redirect $ENV{TEMP} to within our build directory.
	$self->trace_line( 1,
		"Emptying the directory to redirect \$ENV{TEMP} to...\n" );
	$self->remake_path( $self->tempenv_dir() );
	## no critic (RequireLocalizedPunctuationVars)
	$ENV{TEMP} = $self->tempenv_dir();
	$self->trace_line( 5, 'Emptied: ' . $self->tempenv_dir() . "\n" );

	### *** TODO: Move AppData/.cpan/CPAN/MyConfig.pm out of the way. ***

	# If we have a file:// url for the CPAN, move the
	# sources directory out of the way.
	if ( $self->cpan()->as_string() =~ m{\Afile://}mxsi ) {
		if ( not $CPAN::Config_loaded++ ) {
			CPAN::HandleConfig->load();
		}

		my $cpan_path_from = $CPAN::Config->{'keep_source_where'};
		my $cpan_path_to =
		  rel2abs( catdir( $cpan_path_from, q{..}, 'old_sources' ) );

		$self->trace_line( 0, "Moving CPAN sources files:\n" );
		$self->trace_line( 2, <<"EOF");
  From: $cpan_path_from
  To:   $cpan_path_to
EOF

		File::Copy::Recursive::move( $cpan_path_from, $cpan_path_to );

		$self->_set_cpan_sources_from($cpan_path_from);
		$self->_set_cpan_sources_to($cpan_path_to);
		$self->_move_cpan();
	} ## end if ( $self->cpan()->as_string...)

	# Do some sanity checks.
	if ( $self->cpan()->as_string() !~ m{\/\z}ms ) {
		PDWiX::Parameter->throw(
			parameter => 'cpan: Missing trailing slash',
			where     => '->final_initialization'
		);
	}
	if ( $self->build_dir() =~ /\s/ms ) {
		PDWiX::Parameter->throw(
			parameter => 'build_dir: Spaces are not allowed',
			where     => '->final_initialization'
		);
	}

	# Handle portable special cases
	if ( $self->portable() ) {
		$self->_set_exe(0);
		$self->_set_msi(0);
		if ( not $self->zip() ) {
			PDWiX->throw('Cannot be portable and not build a .zip');
		}
	}

	# Making sure that this is set.
	$self->_set_in_merge_module(1);

	## no critic(ProtectPrivateSubs)
	# Set up element collections, starting with the directory tree.
	$self->trace_line( 2, "Creating in-memory directory tree...\n" );
	Perl::Dist::WiX::DirectoryTree->_clear_instance();
	$self->_set_directories(
		Perl::Dist::WiX::DirectoryTree->new(
			app_dir  => $self->image_dir(),
			app_name => $self->app_name(),
		  )->initialize_tree(
			$self->perl_version(), $self->bits(), $self->gcc_version() ) );

	# Create an environment fragment.
	$self->_add_fragment( 'Environment',
		Perl::Dist::WiX::Fragment::Environment->new() );

	# Add directories that need created.
	$self->_add_fragment(
		'CreateCpan',
		Perl::Dist::WiX::Fragment::CreateFolder->new(
			directory_id => 'Cpan',
			id           => 'CPANFolder',
		) );
	$self->_add_fragment(
		'CreateCpanSources',
		Perl::Dist::WiX::Fragment::CreateFolder->new(
			directory_id => 'CpanSources',
			id           => 'CPANSourcesFolder',
		) );
	$self->_add_fragment(
		'CreatePerl',
		Perl::Dist::WiX::Fragment::CreateFolder->new(
			directory_id => 'Perl',
			id           => 'PerlFolder',
		) );
	$self->_add_fragment(
		'CreatePerlSite',
		Perl::Dist::WiX::Fragment::CreateFolder->new(
			directory_id => 'PerlSite',
			id           => 'PerlSiteFolder',
		) );
	$self->_add_fragment(
		'CreatePerlSiteBin',
		Perl::Dist::WiX::Fragment::CreateFolder->new(
			directory_id => 'PerlSiteBin',
			id           => 'PerlSiteBinFolder',
		) );
	$self->_add_fragment(
		'CreatePerlSiteLib',
		Perl::Dist::WiX::Fragment::CreateFolder->new(
			directory_id => 'PerlSiteLib',
			id           => 'PerlSiteLibFolder',
		) );
	$self->_add_fragment(
		'CreateCpanplus',
		Perl::Dist::WiX::Fragment::CreateFolder->new(
			directory_id => 'Cpanplus',
			id           => 'CPANPLUSFolder',
		) );

	# Empty directories that need emptied.
	$self->trace_line( 1,
		    'Wait a second while we empty the image, '
		  . "output, and fragment directories...\n" );
	$self->remake_path( $self->image_dir() );
	$self->remake_path( $self->output_dir() );
	$self->remake_path( $self->fragment_dir() );

	# Make some directories.
	my @directories_to_make =
	  ( $self->dir('cpan'), $self->dir('cpanplus') );
	for my $d (@directories_to_make) {
		next if -d $d;
		File::Path::mkpath($d);
	}

	# Add environment variables.
	# We use YAML as the backend because we have it.
	$self->add_env( 'TERM',              'dumb' );
	$self->add_env( 'FTP_PASSIVE',       '1' );
	$self->add_env( 'PERL_YAML_BACKEND', 'YAML' );

	# Blow away the directory cache for a new build.
	Perl::Dist::WiX::DirectoryCache->instance()->clear_cache();

	return 1;
} ## end sub final_initialization



sub _check_64_bit {
	my $self = shift;

	# Make the environment variable checks shorter.
	my $arch      = lc( $ENV{'PROCESSOR_ARCHITECTURE'} or 'x86' );
	my $archw6432 = lc( $ENV{'PROCESSOR_ARCHITEW6432'} or 'x86' );

	# Check for Itanium architecture.
	if (   ( 'ix86' eq $arch )
		or ( 'ix86' eq $archw6432 ) )
	{
		PDWiX->throw( 'We do not support building 64-bit Perl'
			  . ' on Itanium architectures.' );
	}

	# Check for x86 architecture.
	if (    ( 'x86' eq $arch )
		and ( 'x86' eq $archw6432 ) )
	{
		PDWiX->throw( 'We do not support building 64-bit Perl'
			  . ' on 32-bit machines.' );
	}

	return;
} ## end sub _check_64_bit



=head3 initialize_nomsm

The C<initialize_nomsm> routine does the initialization that is 
required after L<final_initialization()|/final_initialization> has 
been called, but before files can be installed if L<msm()|/msm> is 0.

=cut

sub initialize_nomsm {
	my $self = shift;

	# Making sure that this is unset.
	$self->_set_in_merge_module(0);

	# Add fragments that otherwise would be after the merge module is done.
	$self->_add_fragment( 'StartMenuIcons',
		Perl::Dist::WiX::Fragment::StartMenu->new() );
	$self->_add_fragment(
		'Win32Extras',
		Perl::Dist::WiX::Fragment::Files->new(
			id    => 'Win32Extras',
			files => File::List::Object->new(),
		) );

	$self->_set_icons(
		$self->get_fragment_object('StartMenuIcons')->get_icons() );
	if ( defined $self->msi_product_icon() ) {
		$self->_icons()->add_icon( $self->msi_product_icon() );
	}

	return 1;
} ## end sub initialize_nomsm



=head3 initialize_using_msm

The C<initialize_using_msm> routine does the initialization that is 
required after L<final_initialization()|/final_initialization> has 
been called, but before files can be installed if a merge module 
is to be used.

(see L</Using a merge module> for more information.)

=cut

sub initialize_using_msm {
	my $self = shift;

	# Making sure that this is unset.
	$self->_set_in_merge_module(0);

	# Download and extract the image.
	my $tgz = $self->mirror_url( $self->msm_zip(), $self->download_dir() );
	$self->extract_archive( $tgz, $self->image_dir() );

	# Start adding the fragments that are only for an .msi.
	$self->_add_fragment( 'StartMenuIcons',
		Perl::Dist::WiX::Fragment::StartMenu->new() );
	$self->_add_fragment(
		'Win32Extras',
		Perl::Dist::WiX::Fragment::Files->new(
			id    => 'Win32Extras',
			files => File::List::Object->new(),
		) );

	$self->_set_icons(
		$self->get_fragment_object('StartMenuIcons')->get_icons() );
	if ( defined $self->msi_product_icon() ) {
		$self->_icons()->add_icon( $self->msi_product_icon() );
	}

	# Download the merge module.
	my $msm =
	  $self->mirror_url( $self->msm_to_use(), $self->download_dir() );

	# Connect the Merge Module tag.
	my $mm = Perl::Dist::WiX::Tag::MergeModule->new(
		id                => 'Perl',
		disk_id           => 1,
		language          => 1033,
		source_file       => $msm,
		primary_reference => 1,
	);
	$self->_add_merge_module( 'Perl', $mm );
	$self->get_directory_tree()
	  ->add_merge_module( $self->image_dir()->stringify(), $mm );

   # Set the file paths that the first portion of the build otherwise would.
	$self->_set_bin_perl( $self->file(qw(perl bin perl.exe)) );
	$self->_set_bin_make( $self->file(qw(c bin dmake.exe)) );
	$self->_set_bin_pexports( $self->file(qw(c bin pexports.exe)) );
	$self->_set_bin_dlltool( $self->file(qw(c bin dlltool.exe)) );

	# Do the same for the environment variables
	$self->add_path( 'c',    'bin' );
	$self->add_path( 'perl', 'site', 'bin' );
	$self->add_path( 'perl', 'bin' );

	# Remove the .url files and README.txt files.
	my $answer;
	$answer = unlink glob $self->file(qw(win32 *.url));
	$answer = unlink $self->file('README.txt');

	# Initialize CPAN::SQLite if we need to.
	if ( $self->_use_sqlite() && $self->offline() ) {
		my $cpan_dir = $self->cpan()->dir();
		$cpan_dir =~ s{\\\z}{}ms;
		$self->execute_perl( $self->file(qw(perl bin cpandb)),
			'--setup', '--db_dir', $self->dir(qw(cpan)), '--CPAN',
			$cpan_dir, );
	}

	return 1;
} ## end sub initialize_using_msm



=head3 install_c_toolchain

The C<install_c_toolchain> method is used by L<run()|/run> to install 
various binary packages to provide a working C development environment.

By default, the C toolchain consists of dmake, gcc (C/C++), binutils,
pexports, the mingw runtime environment, and the win32api C package.

Although dmake is the "standard" make for Perl::Dist distributions,
it will also install the mingw version of GNU make for use with 
those modules that require it.

=cut

# Install the required toolchain elements.
# We use separate methods for each tool to make
# it easier for individual distributions to customize
# the versions of tools they incorporate.
sub install_c_toolchain {
	my $self = shift;

	# The primary make
	$self->install_dmake;

	# Core compiler and support libraries.
	$self->install_gcc_toolchain;

	# C Utilities
	$self->install_mingw_make;
	$self->install_pexports;

	# Set up the environment variables for the binaries
	$self->add_path( 'c', 'bin' );

	return 1;
} ## end sub install_c_toolchain



=head3 install_portable

The C<install_portable> method is used by L<run()|/run> to install 
the perl modules to make Perl installable on a portable device.

=cut

# Portability support must be added after modules
sub install_portable {
	my $self = shift;

	return 1 if not $self->portable();

	# Install the regular parts of Portability
	if ( not $self->isa('Perl::Dist::Strawberry') ) {
		$self->install_modules( qw(
			  Sub::Uplevel
			  Test::Exception
			  Test::Tester
			  Test::NoWarnings
			  LWP::Online
			  Class::Inspector
		) );
	}
	if ( not $self->isa('Perl::Dist::Bootstrap') ) {
		$self->install_modules( qw(
			  CPAN::Mini
			  Portable
		) );
	}

	# Create the portability object
	$self->trace_line( 1, "Creating Portable::Dist\n" );
	require Portable::Dist;
	$self->_set_portable_dist(
		Portable::Dist->new( perl_root => $self->dir('perl') ) );
	$self->trace_line( 1, "Running Portable::Dist\n" );
	$self->_portable_dist()->run();
	$self->trace_line( 1, "Completed Portable::Dist\n" );

	# Install the file that turns on Portability last
	$self->install_file(
		share      => 'Perl-Dist-WiX portable\portable.perl',
		install_to => 'portable.perl',
	);

	# Install files to help use Strawberry Portable.
	$self->install_file(
		share      => 'Perl-Dist-WiX portable\README.portable.txt',
		install_to => 'README.portable.txt',
	);
	$self->install_file(
		share      => 'Perl-Dist-WiX portable\portableshell.bat',
		install_to => 'portableshell.bat',
	);

	$self->get_directory_tree()->get_directory_object('INSTALLDIR')
	  ->add_directories_id( 'Data', 'data' );
	$self->_add_fragment(
		'DataFolder',
		Perl::Dist::WiX::Fragment::CreateFolder->new(
			directory_id => 'Data',
			id           => 'DataFolder'
		) );

	$self->make_path( $self->dir('data') );

	return 1;
} ## end sub install_portable



=head3 install_relocatable

The C<install_relocatable> method is used by C<run> to install the perl
script to make Perl relocatable when installed.

This routine must be run before L</regenerate_fragments>, so that the 
fragment created in this method is regenerated and the file ID can
be found by L</find_relocatable_fields> later.

=cut

# Relocatability support must be added before writing the merge module
sub install_relocatable {
	my $self = shift;

	return 1 if not $self->relocatable();

	# Copy the relocation information in.
	$self->copy_file( catfile( $self->wix_dist_dir(), 'relocation.pl.bat' ),
		$self->image_dir() );

	# Make sure it gets installed.
	$self->insert_fragment(
		'relocation_script',
		File::List::Object->new()
		  ->add_file( $self->file('relocation.pl.bat') ),
	);

	return 1;
} ## end sub install_relocatable



=head3 find_relocatable_fields

The C<find_relocatable_fields> method is used by C<run> to find the 
property ID's required to make Perl relocatable when installed.

This routine must be run after L<regenerate_fragments()|/regenerate_fragments>.

=cut

# Relocatability support must be added before writing the merge module
sub find_relocatable_fields {
	my $self = shift;

	return 1 if $self->portable();

	# Set the fileid attributes.
	my $perl_id =
	  $self->get_fragment_object('perl')
	  ->find_file_id( $self->file(qw(perl bin perl.exe)) );
	if ( not $perl_id ) {
		PDWiX->throw("Could not find perl.exe's ID.\n");
	}
	$self->_set_fileid_perl($perl_id);
	$self->trace_line( 2, "File ID for perl.exe: $perl_id\n" );

	return 1 if not $self->relocatable();

	my $script_id =
	  $self->get_fragment_object('relocation_script')
	  ->find_file_id( $self->file('relocation.pl.bat') );
	if ( not $script_id ) {
		PDWiX->throw("Could not find relocation.pl.bat's ID.\n");
	}
	$self->_set_fileid_relocation_pl($script_id);
	$self->trace_line( 2, "File ID for relocation.pl.bat: $script_id\n" );

	return 1;
} ## end sub find_relocatable_fields



=head3 install_win32_extras

The C<install_win32_extras> method is used by L<run()|/run> to install 
the links and launchers into the Start menu.

=cut

# Install links and launchers and so on
sub install_win32_extras {
	my $self = shift;

	File::Path::mkpath( $self->dir('win32') );

	# Copy the environment update script in.
	if ( not $self->portable() ) {
		$self->copy_file(
			catfile( $self->wix_dist_dir(), 'update_env.pl.bat' ),
			$self->image_dir()->file('update_env.pl.bat')->stringify() );
	}

	if ( $self->msi() ) {
		$self->install_launcher(
			name => 'CPAN Client',
			bin  => 'cpan',
		);
		$self->install_website(
			name      => 'CPAN Module Search',
			url       => 'http://search.cpan.org/',
			icon_file => catfile( $self->wix_dist_dir(), 'cpan.ico' ) );

		if ( $self->perl_version_human eq '5.10.0' ) {
			$self->install_website(
				name      => 'Perl 5.10.0 Documentation',
				url       => 'http://perldoc.perl.org/5.10.0/',
				icon_file => catfile( $self->wix_dist_dir(), 'perldoc.ico' )
			);
		}
		if ( $self->perl_version_human eq '5.10.1' ) {
			$self->install_website(
				name      => 'Perl 5.10.1 Documentation',
				url       => 'http://perldoc.perl.org/5.10.1/',
				icon_file => catfile( $self->wix_dist_dir(), 'perldoc.ico' )
			);
		}
		if ( $self->perl_version_human eq '5.12.0' ) {
			$self->install_website(
				name      => 'Perl 5.12.0 Documentation',
				url       => 'http://perldoc.perl.org/5.12.0/',
				icon_file => catfile( $self->wix_dist_dir(), 'perldoc.ico' )
			);
		}
		if ( $self->perl_version_human eq '5.12.1' ) {
			$self->install_website(
				name      => 'Perl 5.12.1 Documentation',
				url       => 'http://perldoc.perl.org/5.12.1/',
				icon_file => catfile( $self->wix_dist_dir(), 'perldoc.ico' )
			);
		}
		if ( $self->perl_version_human eq '5.12.2' ) {
			$self->install_website(
				name      => 'Perl 5.12.2 Documentation',
				url       => 'http://perldoc.perl.org/5.12.2/',
				icon_file => catfile( $self->wix_dist_dir(), 'perldoc.ico' )
			);
		}
		if ( $self->perl_version_human eq '5.12.3' ) {
			$self->install_website(
				name =>
				  'Perl 5.12.2 Documentation (5.12.3 not available yet)',
				url       => 'http://perldoc.perl.org/5.12.2/',
				icon_file => catfile( $self->wix_dist_dir(), 'perldoc.ico' )
			);
		}
		if ( $self->perl_version_human eq '5.14.0' ) {
			$self->install_website(
				name =>
				  'Perl 5.12.2 Documentation (5.14.0 not available yet)',
				url       => 'http://perldoc.perl.org/5.12.2/',
				icon_file => catfile( $self->wix_dist_dir(), 'perldoc.ico' )
			);
		}
		$self->install_website(
			name      => 'Win32 Perl Wiki',
			url       => 'http://win32.perl.org/',
			icon_file => catfile( $self->wix_dist_dir(), 'win32.ico' ) );

		$self->get_fragment_object('StartMenuIcons')->add_shortcut(
			name => 'Perl (command line)',
			description =>
			  'Quick way to get to the command line in order to use Perl.',
			target       => '[SystemFolder]cmd.exe',
			id           => 'PerlCmdLine',
			working_dir  => 'PersonalFolder',
			directory_id => 'D_App_Menu',
		);

		$self->add_to_fragment(
			'Win32Extras',
			[   $self->file(qw(win32 win32.ico)),
				$self->file(qw(win32 cpan.ico)),
			] );

		# Make sure the environment script gets installed.
		$self->insert_fragment(
			'update_env_script',
			File::List::Object->new()
			  ->add_file( $self->file('update_env.pl.bat') ),
		);

	} ## end if ( $self->msi() )

	return $self;
} ## end sub install_win32_extras



=head3 remove_waste

The C<remove_waste> method is used by L<run()|/run> to remove files 
that the distribution does not need to package.

=cut

# Delete various stuff we won't be needing
sub remove_waste {
	my $self = shift;

	$self->trace_line( 1, "Removing waste\n" );
	$self->trace_line( 2,
		"  Removing doc, man, info and html documentation\n" );
	$self->_remove_dir(qw{ perl man       });
	$self->_remove_dir(qw{ perl html      });
	$self->_remove_dir(qw{ c    man       });
	$self->_remove_dir(qw{ c    doc       });
	$self->_remove_dir(qw{ c    info      });
	$self->_remove_dir(qw{ c    contrib   });
	$self->_remove_dir(qw{ c    html      });

	$self->trace_line( 2, "  Removing C examples, manifests\n" );
	$self->_remove_dir(qw{ c examples  });
	$self->_remove_dir(qw{ c manifest  });

	$self->trace_line( 2, "  Removing extra dmake/gcc files\n" );
	$self->_remove_dir(qw{ c bin startup mac   });
	$self->_remove_dir(qw{ c bin startup msdos });
	$self->_remove_dir(qw{ c bin startup os2   });
	$self->_remove_dir(qw{ c bin startup qssl  });
	$self->_remove_dir(qw{ c bin startup tos   });
	$self->_remove_dir(qw{ c libexec gcc mingw32 3.4.5 install-tools});

	$self->trace_line( 2, "  Removing redundant files\n" );
	$self->_remove_file(qw{ c COPYING     });
	$self->_remove_file(qw{ c COPYING.LIB });
	$self->_remove_file(qw{ c bin gccbug  });
	$self->_remove_file(qw{ c bin mingw32-gcc-3.4.5 });

	$self->trace_line( 2,
		"  Removing CPAN build directories and download caches\n" );
	$self->_remove_dir(qw{ cpan sources  });
	$self->_remove_dir(qw{ cpan build    });
	$self->_remove_file(qw{ cpan cpandb.sql });
	$self->_remove_file(qw{ cpan FTPstats.yml });
	$self->_remove_file(qw{ cpan cpan_sqlite_log.* });
	$self->_remove_file(qw{ cpan Metadata });

	# Readding the cpan directory.
	$self->remake_path( catdir( $self->build_dir, 'cpan' ) );

	return 1;
} ## end sub remove_waste

sub _remove_dir {
	my $self = shift;
	my $dir  = $self->dir(@_);
	if ( -e $dir ) {
		$self->remove_path($dir);
	}
	return 1;
}

sub _remove_file {
	my $self = shift;
	my $file = $self->file(@_);
	if ( -e $file ) {
		## TODO: Deal with the 'no critic'
		unlink $file; ## no critic(RequireCheckedSyscalls)
	}
	return 1;
}



=head3 regenerate_fragments

The C<regenerate_fragments> method is used by L<run()|/run> to fully 
generate the object tree for file-containing fragments, which only 
contain a list of files until their C<regenerate()> routines are run.

=cut

sub regenerate_fragments {
	my $self = shift;

	return 1 if not $self->msi();

	# Add the perllocal.pod here, because apparently it's disappearing.
	if ( $self->fragment_exists('perl') ) {
		$self->add_to_fragment( 'perl',
			[ $self->file(qw(perl lib perllocal.pod)) ] );
	}

	my @fragment_names_regenerate;
	my @fragment_names = $self->_fragment_keys();
	while ( 0 != scalar @fragment_names ) {
		foreach my $name (@fragment_names) {
			my $fragment = $self->get_fragment_object($name);
			if ( defined $fragment ) {
				push @fragment_names_regenerate, $fragment->_regenerate();
			} else {
				$self->trace_line( 0,
					    "Couldn't regenerate fragment $name "
					  . "because fragment object did not exist.\n" );
			}
		}

		$#fragment_names = -1;         # clears the array.
		@fragment_names             = uniq @fragment_names_regenerate;
		$#fragment_names_regenerate = -1;
	} ## end while ( 0 != scalar @fragment_names)

	return 1;
} ## end sub regenerate_fragments

=head3 verify_msi_file_contents

This method is used by L<run()|/run> to verify that all the files that are
supposed to be in the .msi or .msm are actually in it. ('supposed to be' is 
defined as 'the files would be in the .zip at this point'.)

This method does not verify anything (start menu options, etc.) that does not
go in the L<image_dir()|/image_dir>

=cut

sub verify_msi_file_contents {
	my $self = shift;

	return 1 if not $self->msi();

	my $image_dir = $self->image_dir()->stringify();
	my $perllocal =
	  $self->image_dir()->file(qw(perl lib perllocal.pod))->stringify();
	my $files_msi = $self->_all_files_object();

	# Add files being installed in fragments to the list.
	my @files;
	my @fragment_names = $self->_fragment_keys();
	foreach my $name (@fragment_names) {
		my $fragment = $self->get_fragment_object($name);
		if ( defined $fragment and $fragment->can('_get_files') ) {
			push @files, @{ $fragment->_get_files() };
		}
	}
	my @files_in_imagedir = grep {m/\A\Q$image_dir\E/msx} @files;
	$files_msi->load_array(@files_in_imagedir);
	if ( -e $perllocal ) {
		$files_msi->add_file($perllocal);
	}

	# Now get what the zip would grab.
	my $files_zip = File::List::Object->new();
	$files_zip->readdir($image_dir);
	$files_zip->remove_files(
		( grep {m/\Q.AAA\E\z/msx} @{ $files_zip->files() } ) );
	$files_zip->filter( $self->_filters() );

	my $not_in_msi =
	  File::List::Object->clone($files_zip)->subtract($files_msi);
	my $not_in_zip =
	  File::List::Object->clone($files_msi)->subtract($files_zip);

	if ( $not_in_msi->count() ) {
		$self->trace_line( 0, "Files list:\n" );
		$self->trace_line( 0, $not_in_msi->as_string() . "\n" );
		PDWiX->throw(
			    'These files should be installed by the MSI file being '
			  . 'generated, but will not be.' );
	}

	if ( $not_in_zip->count() ) {
		$self->trace_line( 0, "Files list:\n" );
		$self->trace_line( 0, $not_in_zip->as_string() . "\n" );
		PDWiX->throw( 'These files should be installed by a ZIP file, but '
			  . 'will not be.' );
	}

	return 1;
} ## end sub verify_msi_file_contents

=head3 write

The C<write> method is used by L<run()|/run> to compile the final
installers for the distribution.

=cut

sub write { ## no critic 'ProhibitBuiltinHomonyms'
	my $self = shift;

	if ( $self->zip() ) {
		$self->add_output_files( $self->_write_zip() );
	}
	if ( $self->msi() ) {
		$self->add_output_files( $self->_write_msi() );
	}
	return 1;
}



=head3 write_merge_module

The C<write_merge_module> method is used by L<run()|/run> to compile 
the merge module for the distribution.

=cut

sub write_merge_module {
	my $self = shift;

	if ( $self->msi() ) {

		$self->add_output_files( $self->_write_msm() );

		$self->_clear_fragments();

		my $zipfile = catfile( $self->output_dir(), 'fragments.zip' );
		$self->trace_line( 1, "Generating zip at $zipfile\n" );

		# Create the archive
		my $zip = Archive::Zip->new();

		# Add the fragments directory to the root
		$zip->addTree( $self->fragment_dir(), q{} );

		my @members = $zip->members();

		# Set max compression for all members, deleting .AAA files.
		foreach my $member (@members) {
			next if $member->isDirectory();
			$member->desiredCompressionLevel(9);
			if ( $member->fileName =~ m{[.] wixout\z}smx ) {
				$zip->removeMember($member);
			}
			if ( $member->fileName =~ m{[.] wixobj\z}smx ) {
				$zip->removeMember($member);
			}
		}

		# Write out the file name
		$zip->writeToFileNamed($zipfile);

		# Remake the fragments directory.
		$self->remake_path( $self->fragment_dir() );

		## no critic(ProtectPrivateSubs)
		# Reset the directory tree.
		$self->_set_directories(undef);
		Perl::Dist::WiX::DirectoryTree->_clear_instance();
		$self->_set_directories(
			Perl::Dist::WiX::DirectoryTree->new(
				app_dir  => $self->image_dir(),
				app_name => $self->app_name(),
			  )->initialize_short_tree( $self->perl_version() ) );

		$self->_set_in_merge_module(0);

		# Start adding the fragments that are only for the .msi.
		$self->_add_fragment( 'StartMenuIcons',
			Perl::Dist::WiX::Fragment::StartMenu->new() );
		$self->_add_fragment(
			'Win32Extras',
			Perl::Dist::WiX::Fragment::Files->new(
				id    => 'Win32Extras',
				files => File::List::Object->new(),
			) );

		$self->_set_icons(
			$self->get_fragment_object('StartMenuIcons')->get_icons() );
		if ( defined $self->msi_product_icon() ) {
			$self->_icons()
			  ->add_icon( $self->msi_product_icon()->stringify() );
		}

		my $mm = Perl::Dist::WiX::Tag::MergeModule->new(
			id          => 'Perl',
			disk_id     => 1,
			language    => 1033,
			source_file => $self->output_dir()
			  ->file( $self->output_base_filename() . '.msm' )->stringify(),
			primary_reference => 1,
		);
		$self->_add_merge_module( 'Perl', $mm );
		$self->get_directory_tree()
		  ->add_merge_module( $self->image_dir()->stringify(), $mm );
	} ## end if ( $self->msi() )

	return 1;
} ## end sub write_merge_module



#####################################################################
# Package Generation

=head2 Package generation methods

These are the (private) routines that generate different types of packages 
and are called by the L<write()|/write> method when required.

=head3 _write_zip

	$self->_write_zip();

The C<_write_zip> method is used to generate a standalone .zip file
containing the entire distribution, for situations in which a full
installer database is not wanted (such as for "Portable Perl"
type installations). It is called by L<write()|/write> when needed.

The .zip file is written to the output directory, and the location
of the file is printed to STDOUT.

Returns true or throws an exception or error.

=cut

sub _write_zip {
	my $self = shift;
	my $file =
	  catfile( $self->output_dir(), $self->output_base_filename . '.zip' );
	$self->trace_line( 1, "Generating zip at $file\n" );

	# Make directories.
	$self->remake_path( $self->dir(qw(cpan sources)) );
	$self->remake_path( $self->dir(qw(cpanplus    )) );

	# Create the archive
	my $zip = Archive::Zip->new();

	# Add the image directory to the root
	$zip->addTree( $self->image_dir(), q{} );

	my @members = $zip->members();

	# Set max compression for all members, deleting .AAA files.
	foreach my $member (@members) {
		next if $member->isDirectory();
		$member->desiredCompressionLevel(9);
		if ( $member->fileName =~ m{[.] AAA\z}smx ) {
			$zip->removeMember($member);
		}
	}

	# Write out the file name
	$zip->writeToFileNamed($file);

	return $file;
} ## end sub _write_zip



=head3 _write_msi

  $self->_write_msi();

The C<_write_msi> method is used to generate the compiled installer
database. It creates the entire installation file tree, and then
executes WiX to create the final executable.

This method is called by L<write()|/write>.

The executable file is written to the output directory, and the location
of the file is printed to STDOUT.

Returns true or throws an exception or error.

=cut

sub _write_msi {
	my $self = shift;

	my $dir = $self->fragment_dir;
	my ( $fragment, $fragment_name, $fragment_string );
	my ( $filename_in, $filename_out );
	my $fh;
	my @files;

	$self->trace_line( 1, "Generating msi\n" );
	$self->_create_rightclick_fragment();

  FRAGMENT:

	# Write out .wxs files for all the fragments and compile them.
	foreach my $key ( $self->_fragment_keys() ) {
		$fragment        = $self->get_fragment_object($key);
		$fragment_string = $fragment->as_string();
		next
		  if ( ( not defined $fragment_string )
			or ( $fragment_string eq q{} ) );
		$fragment_name = $fragment->get_id;
		$filename_in   = catfile( $dir, $fragment_name . q{.wxs} );
		$filename_out  = catfile( $dir, $fragment_name . q{.wixout} );
		$fh            = IO::File->new( $filename_in, 'w' );

		if ( not defined $fh ) {
			PDWiX::File->throw(
				file    => $filename_in,
				message => 'Could not open file for writing '
				  . "[$OS_ERROR] [$EXTENDED_OS_ERROR]"
			);
		}
		$fh->print($fragment_string);
		$fh->close;
		$self->trace_line( 2, "Compiling $filename_in\n" );
		$self->_compile_wxs( $filename_in, $filename_out )
		  or PDWiX->throw("WiX could not compile $filename_in");

		if ( not -f $filename_out ) {
			PDWiX->throw( "Failed to find $filename_out (probably "
				  . "compilation error in $filename_in)" );
		}

		push @files, $filename_out;
	} ## end foreach my $key ( $self->_fragment_keys...)

	# Generate feature tree.
	$self->_set_feature_tree_object(
		Perl::Dist::WiX::FeatureTree->new( parent => $self, ) );

	my $mm;

	# Add merge modules.
	foreach my $mm_key ( $self->_merge_module_keys() ) {
		$mm = $self->get_merge_module_object($mm_key);
		$self->feature_tree_object()->add_merge_module($mm);
	}

	# Write out the .wxs file
	my $content = $self->process_template(
		'Main.wxs.tt',
		fileid_relocation_pl_h => $self->fileid_relocation_pl_h(),
		fileid_perl_h          => $self->fileid_perl_h(),
		propertylist           => $self->_get_msi_property_list(),
	);
	$content =~ s{\r\n}{\n}msg;        # CRLF -> LF
	$filename_in =
	  catfile( $self->fragment_dir(), $self->app_name() . q{.wxs} );

	if ( -f $filename_in ) {

		# Had a collision. Yell and scream.
		PDWiX->throw(
			"Could not write out $filename_in: File already exists.");
	}
	$filename_out =
	  catfile( $self->fragment_dir, $self->app_name . q{.wixobj} );
	$fh = IO::File->new( $filename_in, 'w' );

	if ( not defined $fh ) {
		PDWiX::File->throw(
			file    => $filename_in,
			message => 'Could not open file for writing '
			  . "[$OS_ERROR] [$EXTENDED_OS_ERROR]"
		);
	}
	$fh->print($content);
	$fh->close;

	# Compile the main .wxs
	$self->trace_line( 2, "Compiling $filename_in\n" );
	$self->_compile_wxs( $filename_in, $filename_out )
	  or PDWiX->throw("WiX could not compile $filename_in");
	if ( not -f $filename_out ) {
		PDWiX->throw( "Failed to find $filename_out (probably "
			  . "compilation error in $filename_in)" );
	}

	# Start linking the msi.

	# Get the parameters for the msi linking.
	my $output_msi =
	  catfile( $self->output_dir, $self->output_base_filename . '.msi', );
	my $input_wixouts = catfile( $self->fragment_dir, '*.wixout' );
	my $input_wixobj =
	  catfile( $self->fragment_dir, $self->app_name . '.wixobj' );

	# Link the .wixobj files
	$self->trace_line( 1, "Linking $output_msi\n" );
	my $out;
	my $cmd = [
		wix_bin_light(),
		'-sice:ICE38',                 # Gets rid of ICE38 warning.
		'-sice:ICE43',                 # Gets rid of ICE43 warning.
		'-sice:ICE47',                 # Gets rid of ICE47 warning.
		                               # (Too many components in one
		                               # feature for Win9X)
		'-sice:ICE48',                 # Gets rid of ICE48 warning.
		                               # (Hard-coded installation location)

#		'-v',                          # Verbose for the moment.
		'-out', $output_msi,
		'-ext', wix_lib_wixui(),
		'-ext', wix_library('WixUtil'),
		$input_wixobj,
		$input_wixouts,
	];
	my $rv = IPC::Run3::run3( $cmd, \undef, \$out, \undef );

	$self->trace_line( 1, $out );

	# Did everything get done correctly?
	if ( ( not -f $output_msi ) and ( $out =~ /error|warning/msx ) ) {
		$self->trace_line( 0, $out );
		PDWiX->throw(
			"Failed to find $output_msi (probably compilation error)");
	}

	return $output_msi;
} ## end sub _write_msi



sub _get_msi_property_list {
	my $self = shift;

	my $list = Perl::Dist::WiX::PropertyList->new();

	$list->add_simple_property( 'PerlModuleID',
		$self->msm_package_id_property() );
	$list->add_simple_property( 'MSIFASTINSTALL', 1 );
	$list->add_simple_property( 'ARPNOREPAIR',    1 );
	if ( defined $self->msi_feature_tree() ) {
		$list->add_simple_property( 'ARPNOMODIFY', 1 );
	}
	$list->add_simple_property( 'ARPCOMMENTS',
		$self->app_name() . q{ } . $self->perl_version_human() );
	$list->add_simple_property( 'ARPCONTACT', $self->app_publisher() );
	$list->add_simple_property( 'ARPURLINFOABOUT',
		$self->app_publisher_url() );

	if ( defined $self->msi_help_url() ) {
		$list->add_simple_property( 'ARPHELPLINK', $self->msi_help_url() );
	}
	if ( defined $self->msi_readme_file() ) {
		$list->add_simple_property( 'ARPREADME', $self->msi_readme_file() );
	}
	if ( defined $self->msi_product_icon() ) {
		$list->add_simple_property( 'ARPPRODUCTICON',
			$self->msi_product_icon_id() );
	}
	$list->add_simple_property( 'WIXUI_EXITDIALOGOPTIONALTEXT',
		$self->msi_exit_text() );
	if ( $self->msi_run_readme_txt() ) {
		$list->add_simple_property( 'WIXUI_EXITDIALOGOPTIONALCHECKBOXTEXT',
			'Read README file.' );
		$list->add_simple_property( 'WIXUI_EXITDIALOGOPTIONALCHECKBOX', 1 );
		$list->add_simple_property( 'WixShellExecTarget',
			$self->msi_fileid_readme_txt() );
	}
	if ( $self->relocatable() ) {
		$list->add_simple_property( 'WIXUI_INSTALLDIR', 'INSTALLDIR' );
	}
	if ( defined $self->msi_banner_top() ) {
		$list->add_wixvariable( 'WixUIBannerBmp', $self->msi_banner_top() );
	}
	if ( defined $self->msi_banner_side() ) {
		$list->add_wixvariable( 'WixUIDialogBmp',
			$self->msi_banner_side() );
	}
	$list->add_wixvariable( 'WixUILicenseRtf', $self->msi_license_file() );

	return $list;
} ## end sub _get_msi_property_list



=head3 _write_msm

  $self->_write_msm();

The C<_write_msm> method is used to generate the compiled merge module
used in the installer. It creates the entire installation file tree, and then
executes WiX to create the merge module.

This method is called by L<write_merge_module()|/write_merge_module>, and 
should only be called after all installation phases that install perl 
modules that should be in the .msm have been completed and all of the files 
for the merge module are in place.

The merge module file is written to the output directory, and the location
of the file is printed to STDOUT.

Returns true or throws an exception or error.

=cut

sub _write_msm {
	my $self = shift;

	my $dir = $self->fragment_dir;
	my ( $fragment, $fragment_name, $fragment_string );
	my ( $filename_in, $filename_out );
	my $fh;
	my @files;

	$self->trace_line( 1, "Generating msm\n" );

	# Add the path in.
	foreach my $value ( map { '[INSTALLDIR]' . catdir( @{$_} ) }
		$self->_get_env_path_unchecked() )
	{
		$self->add_env( 'PATH', $value, 1 );
	}

  FRAGMENT:

	# Write out .wxs files for all the fragments and compile them.
	foreach my $key ( $self->_fragment_keys() ) {
		$fragment        = $self->get_fragment_object($key);
		$fragment_string = $fragment->as_string();
		next
		  if ( ( not defined $fragment_string )
			or ( $fragment_string eq q{} ) );
		$fragment_name = $fragment->get_id();
		$filename_in   = catfile( $dir, $fragment_name . q{.wxs} );
		$filename_out  = catfile( $dir, $fragment_name . q{.wixout} );
		$fh            = IO::File->new( $filename_in, 'w' );

		if ( not defined $fh ) {
			PDWiX::File->throw(
				file    => $filename_in,
				message => 'Could not open file for writing '
				  . "[$OS_ERROR] [$EXTENDED_OS_ERROR]"
			);
		}
		$fh->print($fragment_string);
		$fh->close;
		$self->trace_line( 2, "Compiling $filename_in\n" );
		$self->_compile_wxs( $filename_in, $filename_out )
		  or PDWiX->throw("WiX could not compile $filename_in");

		if ( not -f $filename_out ) {
			PDWiX->throw( "Failed to find $filename_out (probably "
				  . "compilation error in $filename_in)" );
		}

		push @files, $filename_out;
	} ## end foreach my $key ( $self->_fragment_keys...)

	# Generate feature tree.
	$self->_set_feature_tree_object(
		Perl::Dist::WiX::FeatureTree->new( parent => $self, ) );

	my $commandline = q{};
	if ( $self->relocatable() ) {
		$commandline = $self->msm_relocation_commandline();
	}

	# Write out the .wxs file
	my $content = $self->process_template(
		'Merge-Module.wxs.tt',
		fileid_relocation_pl_h     => $self->fileid_relocation_pl_h(),
		fileid_perl_h              => $self->fileid_perl_h(),
		msm_relocation_commandline => $commandline,
	);
	$content =~ s{\r\n}{\n}msg;        # CRLF -> LF
	$filename_in =
	  catfile( $self->fragment_dir, $self->app_name . q{.wxs} );

	if ( -f $filename_in ) {

		# Had a collision. Yell and scream.
		PDWiX->throw(
			"Could not write out $filename_in: File already exists.");
	}
	$filename_out =
	  catfile( $self->fragment_dir, $self->app_name . q{.wixobj} );
	$fh = IO::File->new( $filename_in, 'w' );

	if ( not defined $fh ) {
		PDWiX->throw(
"Could not open file $filename_in for writing [$OS_ERROR] [$EXTENDED_OS_ERROR]"
		);
	}
	$fh->print($content);
	$fh->close;

	# Compile the main .wxs
	$self->trace_line( 2, "Compiling $filename_in\n" );
	$self->_compile_wxs( $filename_in, $filename_out )
	  or PDWiX->throw("WiX could not compile $filename_in");
	if ( not -f $filename_out ) {
		PDWiX->throw( "Failed to find $filename_out (probably "
			  . "compilation error in $filename_in)" );
	}

# Start linking the merge module.

	# Get the parameters for the msi linking.
	my $output_msm =
	  catfile( $self->output_dir, $self->output_base_filename . '.msm', );
	my $input_wixouts = catfile( $self->fragment_dir, '*.wixout' );
	my $input_wixobj =
	  catfile( $self->fragment_dir, $self->app_name . '.wixobj' );

	# Link the .wixobj files
	$self->trace_line( 1, "Linking $output_msm\n" );
	my $out;
	my $cmd = [
		wix_bin_light(),        '-out',
		$output_msm,            '-ext',
		wix_lib_wixui(),        '-ext',
		wix_library('WixUtil'), $input_wixobj,
		$input_wixouts,
	];
	my $rv = IPC::Run3::run3( $cmd, \undef, \$out, \undef );

	$self->trace_line( 1, $out );

	# Did everything get done correctly?
	if ( ( not -f $output_msm ) and ( $out =~ /error|warning/msx ) ) {
		$self->trace_line( 0, $out );
		PDWiX->throw(
			"Failed to find $output_msm (probably compilation error)");
	}

	# Now write out the documentation for the msm.
	my $output_docs =
	  catfile( $self->output_dir(),
		'merge-module-' . $self->distribution_version_file() . '.html',
	  );
	my $docs =
	  $self->process_template('Merge-Module.documentation.html.tt');
	$fh = IO::File->new( $output_docs, 'w' );

	if ( not defined $fh ) {
		PDWiX::File->throw(
			file    => $filename_in,
			message => 'Could not open file for writing '
			  . "[$OS_ERROR] [$EXTENDED_OS_ERROR]"
		);
	}
	$fh->print($docs);
	$fh->close;

	return ( $output_msm, $output_docs );
} ## end sub _write_msm



=head3 _compile_wxs

Compiles a .wxs file (specified by $filename) into a .wixobj file 
(specified by $wixobj.)  Both parameters are required.

This method is used by the L<_write_msi()|/_write_msi> and 
L<_write_msm()|/_write_msm> methods.

	$self->_compile_wxs("Perl.wxs", "Perl.wixobj");

=cut

sub _compile_wxs {
	my ( $self, $filename, $wixobj ) = @_;
	my @files = @_;

	# Check parameters.
	if ( not _STRING($filename) ) {
		PDWiX::Parameter->throw(
			parameter => 'filename',
			where     => '->compile_wxs'
		);
	}
	if ( not _STRING($wixobj) ) {
		PDWiX::Parameter->throw(
			parameter => 'wixobj',
			where     => '->compile_wxs'
		);
	}
	if ( not -r $filename ) {
		PDWiX::File->throw(
			file    => $filename,
			message => 'File does not exist or is not readable'
		);
	}

	# Compile the .wxs file
	my $cmd = [
		wix_bin_candle(),
		'-out', $wixobj,
		$filename,

	];
	my $out;
	my $rv = IPC::Run3::run3( $cmd, \undef, \$out, \undef );

	if ( ( not -f $wixobj ) and ( $out =~ /error|warning/msx ) ) {
		$self->trace_line( 0, $out );
		PDWiX->throw( "Failed to find $wixobj (probably "
			  . "compilation error in $filename)" );
	}


	return $rv;
} ## end sub _compile_wxs

=head2 Accessors

	$id = $dist->bin_candle(); 

Accessors will return a specified portion of the distribution state, rather than 
changing the distribution object's state.

=head3 msi_product_icon_id

Specifies the Id for the icon that is used in Add/Remove Programs for 
this MSI file.

=head3 feature_tree_object

Returns the L<Perl::Dist::WiX::FeatureTree|Perl::Dist::WiX::FeatureTree> 
object associated with this distribution.

=cut

has 'feature_tree_object' => (
	is       => 'ro',                  # String
	isa      => 'Maybe[Perl::Dist::WiX::FeatureTree]',
	writer   => '_set_feature_tree_object',
	default  => undef,
	init_arg => undef,
);



=head3 bin_perl

=head3 bin_make

=head3 bin_pexports

=head3 bin_dlltool

The locations of perl.exe, dmake.exe, pexports.exe, and dlltool.exe.

These only are available (not undef) once the appropriate packages 
are installed.

=cut

has 'bin_perl' => (
	is       => 'ro',
	isa      => Maybe [Str],
	writer   => '_set_bin_perl',
	init_arg => undef,
	default  => undef,
);

has 'bin_make' => (
	is       => 'ro',
	isa      => Maybe [Str],
	writer   => '_set_bin_make',
	init_arg => undef,
	default  => undef,
);

has 'bin_pexports' => (
	is       => 'ro',
	isa      => Maybe [Str],
	writer   => '_set_bin_pexports',
	init_arg => undef,
	default  => undef,
);

has 'bin_dlltool' => (
	is       => 'ro',
	isa      => Maybe [Str],
	writer   => '_set_bin_dlltool',
	init_arg => undef,
	default  => undef,
);



=head3 dist_dir

Provides a shortcut to the location of the shared files directory.

Returns a directory as a string or throws an exception on error.

=cut

sub dist_dir {
	return File::ShareDir::dist_dir('Perl-Dist-WiX');
}



=head3 wix_dist_dir

Provides a shortcut to the location of the shared files directory for 
C<Perl::Dist::WiX>.

Returns a directory as a L<Path::Class::Dir|Path::Class::Dir> object 
or throws an exception on error.

=cut

has 'wix_dist_dir' => (
	is       => 'ro',
	isa      => ExistingDirectory_Spaceless,
	builder  => '_build_wix_dist_dir',
	init_arg => undef,
	coerce   => 1,
);

sub _build_wix_dist_dir {
	my $dir;

	if (
		not eval {
			$dir = Path::Class::Dir->new(
				File::ShareDir::dist_dir('Perl-Dist-WiX') );
			1;
		} )
	{
		PDWiX::Caught->throw(
			message =>
			  'Could not find distribution directory for Perl::Dist::WiX',
			info => ( defined $EVAL_ERROR )
			? $EVAL_ERROR
			: 'Unknown error',
		);
	} ## end if ( not eval { $dir =...})

	return $dir;
} ## end sub _build_wix_dist_dir



=head3 pdw_class

Used in the templates for documentation purposes.

=cut

sub pdw_class {
	my $self = shift;

	# This is defined in MooseX::Object::Pluggable.
	return $self->_original_class_name();
}



=head3 perl_version_literal

The C<perl_version_literal> method returns the literal numeric Perl
version for the distribution.

For example, a Perl 5.10.1 distribution will return '5.010001'.

=cut

# This is defined in the perl version plugins.



=head3 perl_version_human

The C<perl_version_human> method returns the "marketing" form
of the Perl version.

This will be either 'git', or a string along the lines of '5.10.0'.

=cut

# This is defined in the perl version plugins.



=head3 distribution_version_human

The C<distribution_version_human> method returns the "marketing" form
of the distribution version.

=cut

sub distribution_version_human {
	my $self = shift;

	my $version = $self->perl_version_human();

	if ( 'git' eq $version ) {
		$version = $self->git_describe();
	}

	return
	    $version . q{.}
	  . $self->build_number()
	  . ( $self->portable() ? ' Portable' : q{} )
	  . ( $self->beta_number() ? ' Beta ' . $self->beta_number() : q{} );
} ## end sub distribution_version_human



=head3 distribution_version_file

The C<distribution_version_file> method returns the "marketing" form
of the distribution version, in such a way that it can be used in a file 
name.

=cut

sub distribution_version_file {
	my $self = shift;

	my $version = $self->perl_version_human();

	if ( 'git' eq $version ) {
		$version = $self->git_describe();
	}

	return
	    $version . q{.}
	  . $self->build_number()
	  . ( $self->portable() ? '-portable' : q{} )
	  . ( $self->beta_number() ? '-beta-' . $self->beta_number() : q{} );
} ## end sub distribution_version_file



=head3 output_date_string

Returns a stringified date in YYYYMMDD format for the use of other 
routines.

=cut

# Convenience method
sub output_date_string {
	my @t = localtime;
	return sprintf '%04d%02d%02d', $t[5] + 1900, $t[4] + 1, $t[3];
}



=head3 msi_ui_type

Returns the UI type that the MSI needs to use.

=cut

# For template
sub msi_ui_type {
	my $self = shift;

	if ( defined $self->msi_feature_tree() ) {
		return 'FeatureTree';
	} elsif ( $self->relocatable() ) {
		return 'MyInstallDir';
	} else {
		return 'MyInstall';
	}
}



=head3 msi_platform_string

Returns the Platform attribute to the MSI's Package tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_package.htm>

=cut

# For template
sub msi_platform_string {
	my $self = shift;
	return ( 64 == $self->bits() ) ? 'x64' : 'x86';
}



=head3 msi_product_icon_id

Returns the product icon to use in the main template.

=cut

sub msi_product_icon_id {
	my $self = shift;

	# Get the icon ID if we can.
	if ( defined $self->msi_product_icon() ) {
		return 'I_'
		  . $self->_icons()
		  ->search_icon( $self->msi_product_icon()->stringify() );
	} else {
		## no critic (ProhibitExplicitReturnUndef)
		return undef;
	}
} ## end sub msi_product_icon_id



=head3 msi_product_id

Returns the Id for the MSI's <Product> tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_product.htm>

=cut

# For template
sub msi_product_id {
	my $self = shift;

	my $generator = WiX3::XML::GeneratesGUID::Object->instance();

	my $product_name =
	    $self->app_name()
	  . ( $self->portable() ? ' Portable ' : q{ } )
	  . $self->app_publisher_url()
	  . q{ ver. }
	  . $self->msi_perl_version();

	#... then use it to create a GUID out of the ID.
	my $guid = $generator->generate_guid($product_name);

	return $guid;
} ## end sub msi_product_id



=head3 msm_product_id

Returns the Id for the <Product> tag for the MSI's merge module.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_product.htm>

=cut

# For template
sub msm_product_id {
	my $self = shift;

	my $generator = WiX3::XML::GeneratesGUID::Object->instance();

	my $product_name =
	    $self->app_name()
	  . ( $self->portable() ? ' Portable ' : q{ } )
	  . $self->app_publisher_url()
	  . q{ ver. }
	  . $self->msi_perl_version()
	  . q{ merge module.};

	#... then use it to create a GUID out of the ID.
	my $guid = $generator->generate_guid($product_name);
	$guid =~ s/-/_/msg;

	return $guid;
} ## end sub msm_product_id



=head3 msi_upgrade_code

Returns the Id for the MSI's <Upgrade> tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_upgrade.htm>

=cut

# For template
sub msi_upgrade_code {
	my $self = shift;

	my $generator = WiX3::XML::GeneratesGUID::Object->instance();

	my $upgrade_ver =
	    $self->app_name()
	  . ( $self->portable() ? ' Portable' : q{} ) . q{ }
	  . $self->app_publisher_url();

	#... then use it to create a GUID out of the ID.
	my $guid = $generator->generate_guid($upgrade_ver);

	return $guid;
} ## end sub msi_upgrade_code



=head3 msm_package_id

Returns the Id for the MSM's <Package> tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_package.htm>

=cut

# For template
sub msm_package_id {
	my $self = shift;

	# Handles including a merge module correctly.
	if ( defined $self->msm_code() ) { return $self->msm_code(); }

	my $generator = WiX3::XML::GeneratesGUID::Object->instance();

	my $upgrade_ver =
	    $self->app_name()
	  . ( $self->portable() ? ' Portable' : q{} ) . q{ }
	  . $self->app_publisher_url()
	  . q{ merge module.};

	#... then use it to create a GUID out of the ID.
	my $guid = $generator->generate_guid($upgrade_ver);

	$self->_set_msm_code($guid);

	return $guid;
} ## end sub msm_package_id



=head3 msm_package_id_property

Returns the Id for the MSM's <Package> tag, as the merge module would append it.

This is used in the main .wxs file.

=cut

# For template.
sub msm_package_id_property {
	my $self = shift;

	my $guid = $self->msm_package_id();
	$guid =~ s/-/_/msg;

	return $guid;
}



=head3 msm_code_property

Returns the Id passed in as C<msm_code>, as the merge module would append it.

This is used in the main .wxs file for subclasses.

=cut

# For template.
sub msm_code_property {
	my $self = shift;

	my $guid = $self->msm_code();
	$guid =~ s/-/_/msg;

	return $guid;
}



=head3 msi_perl_version

Returns the Version attribute for the MSI's <Product> tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_product.htm>

=cut

# For template.
# MSI versions are 3 part, not 4, with the maximum version being 255.255.65535
sub msi_perl_version {
	my $self = shift;

	my @ver = @{ $self->_perl_version_arrayref() };

	# Merge build number with last part of perl version.
	$ver[2] = ( $ver[2] << 8 ) + $self->build_number();

	return join q{.}, @ver;

}



=head3 perl_major_version 

Gets the major version (the 10, or 12 part of 5.10, or 5.12) of
the perl distribution being built.

=cut

sub perl_major_version {
	my $self = shift;

	my $ver = $self->_perl_version_arrayref();

	return @{$ver}[1];
}

=head3 msi_perl_major_version

Returns the major perl version so that upgrades that jump delete the
site directory.

=cut

# For template.
# MSI versions are 3 part, not 4, with the maximum version being 255.255.65535
sub msi_perl_major_version {
	my $self = shift;

	# Get perl version arrayref.
	my @ver = @{ $self->_perl_bincompat_version_arrayref() };

	if ( $self->does('Perl::Dist::WiX::Role::GitPlugin') ) {

	 # Shift the third portion over to match msi_perl_version.
	 # Correct to the build number (minus 1 so as not to duplicate) for git.
		$ver[2] <<= 8;
		$ver[2] += $self->build_number();
		$ver[2] -= 1;
	} else {

		# Shift the third portion over to match msi_perl_version.
		$ver[2] <<= 8;
		$ver[2] += 255;
	}

	return join q{.}, @ver;

} ## end sub msi_perl_major_version


=head3 msi_relocation_commandline

Returns a command line to use in Main.wxs.tt for relocation purposes.

=cut

# For template.
sub msi_relocation_commandline {
	my $self = shift;

	my $answer;
	my %files = $self->msi_relocation_commandline_files();

	my ( $fragment, $file, $id );
	while ( ( $fragment, $file ) = each %files ) {
		$id = $self->get_fragment_object($fragment)->find_file_id($file);
		if ( not defined $id ) {
			PDWiX->throw(
				"Could not find file $file in fragment $fragment\n");
		}
		$answer .= " --file [#$id]";
	}

	return $answer;
} ## end sub msi_relocation_commandline



=head3 msm_relocation_commandline

Returns a command line to use in Merge-Module.wxs.tt for relocation purposes.

=cut

# For template.
sub msm_relocation_commandline {
	my $self = shift;

	my $answer;
	my %files = $self->msm_relocation_commandline_files();

	my ( $fragment, $file, $id );
	while ( ( $fragment, $file ) = each %files ) {
		$id = $self->get_fragment_object($fragment)->find_file_id($file);
		if ( not defined $id ) {
			PDWiX->throw(
				"Could not find file $file in fragment $fragment\n");
		}
		$answer .= " --file [#$id]";
	}

	return $answer;
} ## end sub msm_relocation_commandline



=head3 msi_relocation_commandline_files

Returns the files to use in Main.wxs.tt for relocation purposes.

This is overridden in subclasses, and creates an exception if not overridden.

=cut

# For template.
sub msi_relocation_commandline_files {
	my $self = shift;

	PDWiX::Unimplemented->throw();

	return;
}



=head3 msm_relocation_commandline_files

Returns the files to use in Merge-Module.wxs.tt for relocation purposes.

This is overridden in subclasses, and creates an exception if not overridden.

=cut

# For template.
sub msm_relocation_commandline_files {
	my $self = shift;

	PDWiX::Unimplemented->throw();

	return;
}



=head3 msi_relocation_ca

Returns which CA to use in Main.wxs.tt and Merge-Module.wxs.tt for relocation 
purposes.

=cut

sub msi_relocation_ca {
	my $self = shift;

	return ( 64 == $self->bits() ) ? 'CAQuietExec64' : 'CAQuietExec';
}



=head3 msi_fileid_readme_txt 

Returns the ID of the tag that installs a README.txt file.

=cut

sub msi_fileid_readme_txt {
	my $self = shift;

	# Set the fileid attributes.
	my $readme_id =
	  $self->get_fragment_object('Win32Extras')
	  ->find_file_id( $self->file(qw(README.txt)) );
	if ( not $readme_id ) {
		PDWiX->throw("Could not find README.txt's ID.\n");
	}

	return "[#$readme_id]";

} ## end sub msi_fileid_readme_txt


=head3 perl_config_myuname

Returns the value to be used for perl -V:myuname, which is in this pattern:

	Win32 app_id 5.10.0.1.beta_1 #1 Mon Jun 15 23:11:00 2009 i386
	
(the .beta_X is omitted if the beta_number accessor is not set.)

=cut

# For template.
sub perl_config_myuname {
	my $self = shift;

	my $version = $self->perl_version_human();

	if ( $version =~ m/git/ms ) {
		$version = $self->git_describe();
	}

	if ( $self->smoketest() ) {
		$version .= '.smoketest';
	} else {
		$version .= q{.} . $self->build_number();
		if ( $self->beta_number() > 0 ) {
			$version .= '.beta_' . $self->beta_number();
		}
	}

	my $bits = ( 64 == $self->bits() ) ? 'x64' : 'i386';

	return join q{ }, 'Win32', $self->app_id(), $version, '#1',
	  scalar localtime $self->_build_start_time(), $bits;

} ## end sub perl_config_myuname



=head3 get_component_array

Returns the array of <Component Id>'s required.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_component.htm>, 
L<http://wix.sourceforge.net/manual-wix3/wix_xsd_componentref.htm>

=cut

sub get_component_array {
	my $self = shift;

	print "Running get_component_array...\n";
	my @answer;
	foreach my $key ( $self->_fragment_keys() ) {
		push @answer,
		  $self->get_fragment_object($key)->get_componentref_array();
	}

	return @answer;
} ## end sub get_component_array



=head3 mk_debug

Used in the makefile.mk template for 5.12.0+ to activate building a debugging perl. 

=cut

sub mk_debug {
	my $self = shift;

	return ( $self->perl_debug() ) ? 'CFG' : '#CFG';
}



=head3 mk_gcc4

Used in the makefile.mk template for 5.12.0+ to activate building with gcc4. 

=cut

sub mk_gcc4 {
	my $self = shift;

	return ( 4 == $self->gcc_version() ) ? 'GCC_4XX' : '#GCC_4XX';
}



=head3 mk_bits

Used in the makefile.mk template for 5.12.0+ to activate building 64 or 32-bit 
versions. (Actually, this turns off the fact that we're building a 64-bit 
version of perl when we want a 32-bit version on 64-bit processors)

=cut

sub mk_bits {
	my $self = shift;

	my $bits = 1;
	$bits &= ( 4 == $self->gcc_version() );
	$bits &= ( 32 == $self->bits() );
	$bits &= (
		'x86' ne (
			lc( $ENV{'PROCESSOR_ARCHITECTURE'}
				  or 'x86'
			) )
		  or 'x86' ne (
			lc( $ENV{'PROCESSOR_ARCHITEW6432'}
				  or 'x86'
			) ) );

	return $bits ? 'WIN64' : '#WIN64';
} ## end sub mk_bits



=head3 mk_gcc4_dll

Used in the makefile.mk template for 5.12.0+ to activate using the correct 
helper dll for our gcc4 packs. 

=cut

sub mk_gcc4_dll {
	my $self = shift;

	return ( 4 == $self->gcc_version() )
	  ? 'GCCHELPERDLL'
	  : '#GCCHELPERDLL';
}



=head3 mk_extralibs

Used in the makefile.mk template for 5.12.0+ to activate using the correct 
extra library directory for our gcc4 packs. 

=cut

sub mk_extralibs {
	my $self = shift;

	return
	    ( 3 == $self->gcc_version() ) ? q{}
	  : ( 64 == $self->bits() )
	  ? catdir( $self->image_dir, qw(c x86_64-w64-mingw32 lib) )
	  : catdir( $self->image_dir, qw(c i686-w64-mingw32 lib) );
}



=head3 patch_template

C<patch_template> returns the L<Template|Template> object that is used to generate 
patched files.

=cut

has 'patch_template' => (
	is       => 'ro',
	isa      => TemplateObj,
	lazy     => 1,
	init_arg => undef,
	builder  => '_build_patch_template',
	clearer  => '_clear_patch_template',
);

sub _build_patch_template {
	my $self = shift;
	my $obj  = Template->new(
		INCLUDE_PATH => $self->patch_include_path(),
		ABSOLUTE     => 1,
		EVAL_PERL    => 1,
	);

	if ( not $obj ) {
		PDWiX::Caught->throw(
			message => Template::error(),
			info    => 'Template'
		);
	}

	return $obj;
} ## end sub _build_patch_template



=head3 fragment_exists

	my $bool = $dist->fragment_exists('FragmentId');
	
Returns whether the fragment with the name given has been attached to
this distribution.

=head3 get_fragment_object

	my $fragment_tag = $dist->get_fragment_object('FragmentId');

Returns the L<WiX3::XML::Role::Fragment|WiX3::XML::Role::Fragment>-using
object that is attached to this distribution with the given name.

Returns undef if no such object found.

=cut



has '_fragments' => (
	traits => ['Hash'],
	is     => 'ro',
	isa    => 'HashRef[WiX3::XML::Role::Fragment]'
	,                                  # Needs to be Perl::Dist::WiX::Role::Fragment
	default  => sub { return {} },
	init_arg => undef,
	handles  => {
		get_fragment_object => 'get',
		fragment_exists     => 'defined',
		_add_fragment       => 'set',
		_clear_fragments    => 'clear',
		_fragment_keys      => 'keys',
	},
);



=head3 image_drive

The drive letter of the image directory.  Retrieved from C<image_dir>.

=cut

sub image_drive {
	my $self = shift;
	return substr rel2abs( $self->image_dir() ), 0, 2;
}



=head3 image_dir_url

Returns a string containing the C<image_dir> as a file: URL.

=cut

sub image_dir_url {
	my $self = shift;
	return URI::file->new( $self->image_dir() )->as_string();
}



=head3 image_dir_quotemeta

Returns a string containing the C<image_dir>, with all backslashes
converted to 2 backslashes.

=cut

# This is a temporary hack
sub image_dir_quotemeta {
	my $self   = shift;
	my $string = $self->image_dir();
	$string =~ s{\\}        # Convert a backslash
				{\\\\}gmsx; ## to 2 backslashes.
	return $string;
}



=head3 get_output_files

Returns a list of output files created so far. 

=cut



has '_output_file' => (
	traits   => ['Array'],
	is       => 'bare',
	isa      => ArrayRef [Str],
	default  => sub { return [] },
	init_arg => undef,
	handles  => {
		_add_output_files => 'push',
		get_output_files  => 'elements',
	},
);



=head3 get_directory_tree

Retrieves the 
L<Perl::Dist::WiX::DirectoryTree|Perl::Dist::WiX::DirectoryTree> object
created to keep track of directories in this distribution.

=cut

has '_directories' => (
	is       => 'bare',
	isa      => 'Maybe[Perl::Dist::WiX::DirectoryTree]',
	writer   => '_set_directories',
	reader   => 'get_directory_tree',
	clearer  => '_clear_directory_tree',
	default  => undef,
	init_arg => undef,
);



=head3 get_merge_module_object 

	$self->get_merge_module_object('Perl');

Retrieves the
L<Perl::Dist::WiX::Tag::MergeModule|Perl::Dist::WiX::Tag::MergeModule>
that has been added to the list that this distribution uses.

=head3 merge_module_exists

	$self->get_merge_module_object('Perl');

Returns true or false as to whether the merge module named has been added to 
the list of merge modules included in this installer.
	
=cut

has '_merge_modules' => (
	traits   => ['Hash'],
	is       => 'bare',
	isa      => 'HashRef[Perl::Dist::WiX::Tag::MergeModule]',
	default  => sub { return {} },
	init_arg => undef,
	handles  => {
		get_merge_module_object => 'get',
		merge_module_exists     => 'defined',
		_add_merge_module       => 'set',
		add_merge_module        => 'set',
		_clear_merge_modules    => 'clear',
		_merge_module_keys      => 'keys',
	},
);

=head2 Other routines that your tasks (or users of the class) can use

=head3 add_merge_module

    $self->add_merge_module('Perl', $perl_merge_module);
	
Adds a L<Perl::Dist::WiX::Tag::MergeModule|Perl::Dist::WiX::Tag::MergeModule>
to the list of merge modules used in this distribution.

=head3 add_output_file

=head3 add_output_files

    $self->add_output_files('information.html', 'README.txt');
    $self->add_output_file('distribution.msi');

These two methods add files to the list of output files returned by 
L<get_output_files()|/get_output_files>.

They also may create a Growl notification that is sent out locally if 
L<Growl::GNTP|Growl::GNTP> is installed. Growl for Windows (downloadable 
at L<http://www.growlforwindows.com/>) can either display these 
notifications on the local machine, or forward them to another
machine or device that can receive GNTP messages.

Growl notifications are only sent out for msi, msm, and zip files.

The application name sent out will be the class name used to
create the distribution.

=cut

# This is used in order to give notifications an ID.
has '_notification_index' => (
	traits   => ['Counter'],
	is       => 'bare',
	isa      => Int,
	default  => 0,
	reader   => '_get_notify_index',
	init_arg => undef,
	handles  => {
		'_increment_notify_index' => 'inc',

	},
);



# This throws a Growl notification up when files are created.
sub add_output_file {
	my $self  = shift;
	my $class = ref $self;

	# Get the real class name after MooseX::Object::Pluggable
	# has messed with it.
	if ( $class =~ /MOP/ms ) {
		$class = $self->_original_class_name();
	}

	if ( eval { require Growl::GNTP; 1; } ) {

		# Open up our communication link to Growl.
		my $growl = Growl::GNTP->new(
			AppName => $class,
			AppIcon => catfile( $self->wix_dist_dir(), 'growl-icon.png' ),
		);

		# Only need to register with Growl for Windows once.
		if ( not $self->_get_notify_index() ) {
			$growl->register( [ {
						Name        => 'OUTPUT_FILE',
						DisplayName => 'Output file created',
						Enabled     => 'True',
						Sticky      => 'False',
						Priority => -2,       # very low priority.
						Icon     => catfile(
							$self->wix_dist_dir(), 'growl-icon.png'
						),
					} ] );
		} ## end if ( not $self->_get_notify_index...)

		foreach my $file (@_) {
			if ( $file =~ m{[.] (?:msi|zip|msm)\Z}msx ) {

				# Actually do the notification.
				$growl->notify(
					Event => 'OUTPUT_FILE',          # name of notification
					Title => 'Output file created',
					Message => "$file has been created",
					ID      => $self->_get_notify_index(),
				);

				# Increment the ID for next time.
				$self->_increment_notify_index();
			} ## end if ( $file =~ m{[.] (?:msi|zip|msm)\Z}msx)
		} ## end foreach my $file (@_)
	} ## end if ( eval { require Growl::GNTP...})

	return $self->_add_output_files(@_);
} ## end sub add_output_file

sub add_output_files {
	goto &add_output_file;
}

=head3 add_icon

    $self->add_icon(
	    name     => 'CPAN Client',
		filename => 'C:\strawberry\perl\bin\cpan.bat',
		icon_id  => 'I_cpan_bat_ico',
	);

This method adds a start menu icon to the installer that calls the file 
given as the C<filename> parameter, and is named using the C<name> 
parameter within the directory identified by the C<directory_id> parameter,
using the icon identified by the C<icon_id> parameter.

If a C<description> parameter is given, it is used as the description of 
the icon. If the C<directory_id> parameter is not given, it defaults to
'D_App_Menu' (the application menu directory.)

=cut

sub add_icon {
	my $self = shift;
	my %params;
	if ( 'HASH' eq ref $_[0] ) {
		%params = %{ $_[0] };
	} else {
		%params = @_;
	}

	$params{directory_id} ||= 'D_App_Menu';
	$params{description}  ||= $params{name};

	my ( $vol, $dir, $file, $dir_id );

	# Get the Id for directory object that stores the filename passed in.
	( $vol, $dir, $file ) = splitpath( $params{filename} );
	$self->trace_line( 4, "Directory being searched for: $vol $dir\n" );
	$dir_id = $self->get_directory_tree()->search_dir(
		path_to_find => catdir( $vol, $dir ),
		exact        => 1,
		descend      => 1,
	)->get_directory_id();

	# Get a legal id.
	my $id = $params{name};
	$id =~ s{\s}{_}msxg;               # Convert whitespace to underlines.
	$id =~ s{:\\}{}msxg;               # Get rid of colons and backslashes.

	# Add the start menu icon.
	$self->get_fragment_object('StartMenuIcons')->add_shortcut(
		name         => $params{name},
		description  => $params{description},
		target       => "[$dir_id]$file",
		id           => $id,
		working_dir  => $dir_id,
		icon_id      => $params{icon_id},
		directory_id => $params{directory_id},
	);

	return $self;
} ## end sub add_icon



=head3 icons_string

Calls L<< Perl::Dist::WiX::IconArray->as_string()|Perl::Dist::WiX::IconArray/as_string >>
on the array of icons created for this distribution.

=cut

has '_icons' => (
	is       => 'ro',
	isa      => 'Maybe[Perl::Dist::WiX::IconArray]',
	writer   => '_set_icons',
	init_arg => undef,
	handles  => { 'icons_string' => 'as_string', },
);



=head3 add_path

	$self->add_path('perl', 'bin');

Adds a path entry that will be installed when the installer is executed.

=cut

around 'add_path' => sub {
	my $orig = shift;
	my $self = shift;
	my @path = @_;
	my $dir  = $self->dir(@path);
	if ( not -d $dir ) {
		PDWiX::Directory->throw(
			dir     => $dir,
			message => 'PATH directory does not exist'
		);
	}
	$self->$orig( [@path] );
	return 1;
}; ## end sub add_path



=head3 get_path_string

	my $ENV{PATH} = "$ENV{PATH};" . $dist->get_path_string();

Returns a string containing all the path entries that have been added,
so that later portions of the installer generation can use the
programs that have already been put in place.

=cut

sub get_path_string {
	my $self = shift;
	return join q{;},
	  map { $self->dir( @{$_} ) } $self->_get_env_path_unchecked();
}



=head3 add_env

	$self->add_env('PATH', $self->image_dir()->subdir(qw(perl bin)), 1);
	$self->add_env('TERM', 'dumb');

Adds the contents of $value to the environment variable $name 
(or appends to it, if $append is true) upon installation (by 
adding it to the Reg_Environment fragment.)

$name and $value are required. 

=cut

sub add_env {
	my ( $self, $name, $value, $append ) = @_;

	if ( not defined $append ) {
		$append = 0;
	}

	if ( not _STRING($name) ) {
		PDWiX::Parameter->throw(
			parameter => 'name',
			where     => '->add_env'
		);
	}

	if ( not _STRING($value) ) {
		PDWiX::Parameter->throw(
			parameter => 'value',
			where     => '->add_env'
		);
	}

	my $env_fragment = $self->get_fragment_object('Environment');
	my $num          = $env_fragment->get_entries_count();

	$env_fragment->add_entry(
		id     => "Env_$num",
		name   => $name,
		value  => $value,
		action => 'set',
		part   => $append ? 'last' : 'all',
	);

	return $self;
} ## end sub add_env



=head3 add_file

	$dist->add_file(
		source => $filename, 
		fragment => $fragment_name
	);

Adds the file C<$filename> to the fragment named by C<$fragment_name>.

Both parameters are required, and the file and fragment must both exist. 

=cut

sub add_file {
	my ( $self, %params ) = @_;

	if ( not _STRING( $params{source} ) ) {
		PDWiX::Parameter->throw(
			parameter => 'source',
			where     => '->add_file'
		);
	}

	if ( not -f $params{source} ) {
		PDWiX::File->throw(
			file    => $params{source},
			message => 'File does not exist'
		);
	}

	if ( not _IDENTIFIER( $params{fragment} ) ) {
		PDWiX::Parameter->throw(
			parameter => 'fragment',
			where     => '->add_file'
		);
	}

	if ( not $self->fragment_exists( $params{fragment} ) ) {
		PDWiX->throw("Fragment $params{fragment} does not exist");
	}

	$self->get_fragment_object( $params{fragment} )
	  ->add_file( $params{source} );

	return $self;
} ## end sub add_file



=head3 insert_fragment

	$self->insert_fragment($id, $files_obj, $overwritable);

Adds the list of files C<$files_obj> (which is a 
L<File::List::Object|File::List::Object>) to the fragment named by 
C<$id>. C<$overwritable> defaults to false, and most be set to true if
the files in this fragment can be overwritten by future fragments.

The fragment is created by this routine, so this can only be done once.

This B<MUST> be done for each set of files to be installed in an MSI.

=cut

sub insert_fragment {
	my ( $self, $id, $files_obj, $overwritable, $feature ) = @_;

	# Check parameters.
	if ( not _IDENTIFIER($id) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '->insert_fragment'
		);
	}
	if ( not _INSTANCE( $files_obj, 'File::List::Object' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'files_obj',
			where     => '->insert_fragment'
		);
	}

	defined $overwritable or $overwritable = 0;
	defined $feature      or $feature      = 'Complete';

	$self->trace_line( 2, "Adding fragment $id to feature $feature...\n" );

	my $frag;
  FRAGMENT:
	foreach my $frag_key ( $self->_fragment_keys() ) {
		$frag = $self->get_fragment_object($frag_key);
		next FRAGMENT
		  if not $frag->isa('Perl::Dist::WiX::Fragment::Files');
		$frag->_check_duplicates($files_obj);
	}

	my $fragment = Perl::Dist::WiX::Fragment::Files->new(
		id              => $id,
		files           => $files_obj,
		can_overwrite   => $overwritable,
		in_merge_module => $self->_in_merge_module(),
		sub_feature     => $feature,
	);

	$self->_add_fragment( $id, $fragment );

	return $fragment;
} ## end sub insert_fragment



=head3 add_to_fragment

	$dist->add_to_fragment($id, $files_obj);

Adds the list of files C<$files_obj> (which is a 
L<File::List::Object|File::List::Object>) to the fragment named by C<$id>.

The fragment must already exist.

=cut

sub add_to_fragment {
	my ( $self, $id, $files_ref ) = @_;

	# Check parameters.
	if ( not _IDENTIFIER($id) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '->add_to_fragment'
		);
	}
	if ( not _ARRAY($files_ref) ) {
		PDWiX::Parameter->throw(
			parameter => 'files_ref',
			where     => '->add_to_fragment'
		);
	}

	if ( not $self->fragment_exists($id) ) {
		PDWiX->throw("Fragment $id does not exist");
	}

	my @files = @{$files_ref};

	my $files_obj = File::List::Object->new()->add_files(@files);

	my $frag;
	foreach my $frag_key ( $self->_fragment_keys() ) {
		$frag = $self->get_fragment_object($frag_key);
		$frag->_check_duplicates($files_obj);
	}

	my $fragment = $self->get_fragment_object($id)->add_files(@files);

	return $fragment;
} ## end sub add_to_fragment

sub _create_rightclick_fragment {
	my $self = shift;

	my $root_key = WiX3::XML::RegistryKey->new(
		root   => 'HKCR',
		action => 'none',
		key    => '.pl',
	);

	$root_key->add_child_tag(
		WiX3::XML::RegistryValue->new(
			id       => 'sp1010r_pointer',
			value    => 'Perl_program_file',
			type     => 'string',
			action   => 'write',
			key_path => 1,
		) );

	my $classes_key = WiX3::XML::RegistryKey->new(
		root   => 'HKLM',
		action => 'none',
		key    => 'SOFTWARE\\Classes',
	);

	my $child_tag;
	$child_tag = WiX3::XML::RegistryKey->new(
		id     => 'sp1010c_root',
		key    => 'Perl_program_file',
		action => 'createAndRemoveOnUninstall',
	);
	$classes_key->add_child_tag($child_tag);

	$child_tag->add_child_tag(
		WiX3::XML::RegistryValue->new(
			id     => 'sp1010c_pointer',
			value  => 'Perl program file',
			type   => 'string',
			action => 'write',
		) );

	$child_tag->add_child_tag(
		WiX3::XML::RegistryKey->new(
			id     => 'sp1010c_shell',
			key    => 'shell',
			action => 'createAndRemoveOnUninstall',
		) );

	$child_tag = $child_tag->get_child_tag(1);

	$child_tag->add_child_tag(
		WiX3::XML::RegistryKey->new(
			id     => 'sp1010c_syncheck',
			key    => 'Syntax Check',
			action => 'createAndRemoveOnUninstall',
		) );

	$child_tag->add_child_tag(
		WiX3::XML::RegistryKey->new(
			id     => 'sp1010c_execute',
			key    => 'Execute Perl Program',
			action => 'createAndRemoveOnUninstall',
		) );

	$child_tag->get_child_tag(0)->add_child_tag(
		WiX3::XML::RegistryKey->new(
			id     => 'sp1010c_syncheckcommand',
			key    => 'command',
			action => 'createAndRemoveOnUninstall',
		) );

	## no critic(RequireInterpolationOfMetachars)
	$child_tag->get_child_tag(0)->get_child_tag(0)->add_child_tag(
		WiX3::XML::RegistryValue->new(
			id     => 'sp1010c_syncheckcommand',
			value  => q{[P_Perl_Location] -E"system($^X, q{-c}, q{%1});"},
			type   => 'string',
			action => 'write',
		) );

	$child_tag->get_child_tag(1)->add_child_tag(
		WiX3::XML::RegistryKey->new(
			id     => 'sp1010c_executecommand',
			key    => 'command',
			action => 'createAndRemoveOnUninstall',
		) );

	$child_tag->get_child_tag(1)->get_child_tag(0)->add_child_tag(
		WiX3::XML::RegistryValue->new(
			id     => 'sp1010c_executecommand',
			value  => '[P_Perl_Location] "%1" %*',
			type   => 'string',
			action => 'write',
		) );

	my $component = WiX3::XML::Component->new(
		id                        => 'RightClickEntries',
		disableregistryreflection => 1,
		neveroverwrite            => 0,
	);

	$component->add_child_tag($root_key);
	$component->add_child_tag($classes_key);

	my $ref = Perl::Dist::WiX::Tag::DirectoryRef->new(
		$self->get_directory_tree()->get_directory_object('INSTALLDIR') );
	$ref->add_child_tag($component);

	my $fragment = WiX3::XML::Fragment->new( id => 'RightClickEntries', );
	$fragment->add_child_tag($ref);
	$self->_add_fragment( 'RightClickEntries', $fragment );

	return 1;
} ## end sub _create_rightclick_fragment



__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=for readme continue

=head1 DEPENDENCIES

Perl 5.10.0 is the mimimum version of perl that this module will run on.

Other modules that this module depends on are a working version of 
L<Alien::WiX|Alien::WiX>, L<Data::Dump::Streamer|Data::Dump::Streamer> 2.08, 
L<Data::UUID|Data::UUID> 1.149, L<Devel::StackTrace|Devel::StackTrace> 1.20, 
L<Exception::Class|Exception::Class> 1.22, L<File::ShareDir|File::ShareDir> 
1.00, L<IO::String|IO::String> 1.08, L<List::MoreUtils|List::MoreUtils> 0.07, 
L<Module::CoreList|Module::CoreList> 2.32, L<Win32::Exe|Win32::Exe> 0.13, 
L<Object::InsideOut|Object::InsideOut> 3.53, L<Perl::Dist|Perl::Dist> 1.14, 
L<Process|Process> 0.26, L<Readonly|Readonly> 1.03, L<URI|URI> 1.35, and 
L<Win32|Win32> 0.35.

=for readme stop

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist|Perl::Dist>, L<Perl::Dist::Inno|Perl::Dist::Inno>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=for readme continue

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2011 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
