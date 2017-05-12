package Perl::Dist::WiX::Asset::DistFile;

=pod

=head1 NAME

Perl::Dist::WiX::Asset::DistFile - "Local Distribution" asset for a Win32 Perl

=head1 VERSION

This document describes Perl::Dist::WiX::Asset::DistFile version 1.500002.

=head1 SYNOPSIS

  my $distribution = Perl::Dist::WiX::Asset::DistFile->new(
      parent   => $dist,
      file     => 'C:\modules\Perl-Dist-WiX-1.200.tar.gz',
	  mod_name => 'Perl::Dist::WiX',
      force    => 1,
  );

=head1 DESCRIPTION

L<Perl::Dist::WiX|Perl::Dist::WiX> supports two methods for adding Perl 
modules to the installation. The main method is to install it via the 
CPAN shell.

The second is to download, make, test and install the Perl distribution
package independently, avoiding the use of the CPAN client. Unlike the
CPAN installation method, installing the distribution directly does
C<not> allow the installation of dependencies, or the ability to discover
and install the most recent release of the module.

This secondary method is primarily used to deal with cases where the CPAN
shell either fails or does not yet exist. Installation of the Perl
toolchain to get a working CPAN client is done exclusively using the
direct method, as well as the installation of a few special case modules
such as ones where the newest release is broken, but an older
or a development release is known to be good.

B<Perl::Dist::WiX::Asset::DistFile> is a data class that provides
encapsulation and error checking for a "Perl Distribution" to be
installed in a C<Perl::Dist::WiX>-based Perl distribution using this
secondary method that comes from a file on disk (possibly in a share 
directory.)

It is normally created on the fly by the Perl::Dist::WiX
C<install_distribution_from_file> method (and other things that call it).

The specification of the location to retrieve the package is done via
the standard mechanism implemented in 
L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>.

=cut

#<<<
use 5.010;
use Moose;
use MooseX::Types::Moose        qw( Str Maybe Bool ArrayRef );
use File::Spec::Functions       qw( catdir catfile splitpath );
use URI                         qw();
use File::Spec::Unix            qw();
use Perl::Dist::WiX::Exceptions qw();
#>>>

our $VERSION = '1.500002';

with qw( Perl::Dist::WiX::Role::Asset WiX3::Role::Traceable );
extends 'Perl::Dist::WiX::Asset::DistBase';

=head1 METHODS

This class is a L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>
and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new C<Perl::Dist::WiX::Asset::DistFile> object.

It inherits all the parameters described in the 
L<< Perl::Dist::WiX::Role::Asset->new|Perl::Dist::WiX::Role::Asset/new() >> 
method documentation, and adds the additional parameters described below.

=head3 url

The C<url> parameter is used as a location where the package can be 
downloaded for 3 years, as required by the GNU Public License.

This is used when generating release notes.

=head3 mod_name

The required C<mod_name> parameter is the name of the package for the 
purposes of identification.

This should match the name of the main Perl module in the distribution, for 
example, "File::Spec" or "Perl::Dist::WiX".

=cut

has mod_name => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => 'get_name',
	lazy    => 1,
	default => sub { return $_[0]->_name_to_module( $_[0]->_get_file() ); },
);



=head3 force

The optional boolean C<force> param allows you to specify that the tests
should be skipped and the module installed without validating it.

It defaults to what the C<force()> method on the object passed as the 
C<parent> parameter returns.

=cut

has force => (
	is      => 'ro',
	isa     => Bool,
	reader  => '_get_force',
	lazy    => 1,
	default => sub { !!$_[0]->_get_parent()->force() },
);

=head3 automated_testing

Many modules contain additional long-running tests, tests that require
additional dependencies, or have differing behaviour when installing
in a non-user automated environment.

The optional C<automated_testing> param lets you specify that the
module should be installed with the B<AUTOMATED_TESTING> environment
variable set to true, to make the distribution behave properly in an
automated environment (in cases where it doesn't otherwise).

=cut

has automated_testing => (
	is      => 'ro',
	isa     => Bool,
	reader  => '_get_automated_testing',
	default => 0,
);

=head3 release_testing

Some modules contain release-time only tests, that require even heavier
additional dependencies compared to even the C<automated_testing> tests.

The optional C<release_testing> param lets you specify that the module
tests should be run with the additional C<RELEASE_TESTING> environment
flag set.

By default, C<release_testing> is set to false to squelch any accidental
execution of release tests when L<Perl::Dist::WiX|Perl::Dist::WiX> itself 
is being tested under C<RELEASE_TESTING>.

=cut

has release_testing => (
	is      => 'ro',
	isa     => Bool,
	reader  => '_get_release_testing',
	default => 0,
);

=head3 makefilepl_param

Some distributions illegally require you to pass additional non-standard
parameters when you invoke "perl Makefile.PL".

The optional C<makefilepl_param> param should be a reference to an ARRAY
where each element contains the argument to pass to the Makefile.PL.

=cut

has makefilepl_param => (
	is      => 'ro',
	isa     => ArrayRef,
	reader  => '_get_makefilepl_param',
	default => sub { return [] },
);

=head3 buildpl_param

Some distributions require you to pass additional non-standard
parameters when you invoke "perl Build.PL".

The optional C<buildpl_param> param should be a reference to an ARRAY
where each element contains the argument to pass to the Build.PL.

=cut

has buildpl_param => (
	is      => 'ro',
	isa     => ArrayRef,
	reader  => '_get_buildpl_param',
	default => sub { return [] },
);

=head3 packlist

The optional C<packlist> param lets you specify whether this distribution 
creates a packlist (which is a quick way to verify which files are installed
by the distribution).

This parameter defaults to true.

=cut

has packlist => (
	is      => 'ro',
	isa     => Bool,
	reader  => '_get_packlist',
	default => 1,
);

=head2 install

The install method installs the distribution described by the
B<Perl::Dist::WiX::Asset::DistFile> object and returns a list of files
that were installed as a L<File::List::Object|File::List::Object> object.

=cut

sub install {
	my $self = shift;

	# Validate the path.
	my $path = $self->_get_file();
	if ( not -f $path ) {
		PDWiX::Parameter->throw(
			parameter => "file: $path does not exist",
			where     => '->install_distribution_from_file'
		);
	}

# If we don't have a packlist file, get an initial filelist to subtract from.
	my ( undef, undef, $filename ) = splitpath( $path, 0 );
	my $module = $self->_name_to_module("CSJ/$filename");
	my $filelist_sub;

	if ( not $self->_get_packlist() ) {
		$filelist_sub =
		  File::List::Object->new->readdir( $self->_dir('perl') );
		$self->_trace_line( 5,
			    "***** Module being installed $module"
			  . " requires packlist => 0 *****\n" );
	}

	# Where will it get extracted to?
	my $dist_path = $filename;
	$dist_path =~ s{[.] tar [.] gz}{}msx;   # Take off extensions.
	$dist_path =~ s{[.] zip}{}msx;
	my $unpack_to = catdir( $self->_get_build_dir(), $dist_path );
	my $dist_url = $self->_get_url();
	$self->_add_to_distributions_installed($dist_url);
	$self->trace_line( 0, "$dist_url\n" );

	# Extract the tarball
	if ( -d $unpack_to ) {
		$self->_trace_line( 2, "Removing previous $unpack_to\n" );
		$self->remove_path($unpack_to);
	}
	$self->_trace_line( 4, "Unpacking to $unpack_to\n" );
	$self->_extract( $path => $self->_get_build_dir() );
	if ( not -d $unpack_to ) {
		PDWiX->throw("Failed to extract $unpack_to\n");
	}

	# Check for a way to build the distribution.
	my $buildpl    = ( -r catfile( $unpack_to, 'Build.PL' ) )    ? 1 : 0;
	my $makefilepl = ( -r catfile( $unpack_to, 'Makefile.PL' ) ) ? 1 : 0;
	if ( not $buildpl and not $makefilepl ) {
		PDWiX->throw(
			"Could not find Makefile.PL or Build.PL in $unpack_to\n");
	}

	# Build using Build.PL if we have one
	# unless Module::Build is not installed.
	if ( not $self->_module_build_installed() ) {
		$buildpl = 0;
		if ( not $makefilepl ) {
			PDWiX->throw( "Could not find Makefile.PL in $unpack_to"
				  . " (too early for Build.PL)\n" );
		}
	}

	# Build the module
  SCOPE: {
		my $wd = $self->_pushd($unpack_to);

		# Enable automated_testing mode if needed
		# Blame Term::ReadLine::Perl for needing this ugly hack.
		if ( $self->_get_automated_testing() ) {
			$self->_trace_line( 2,
				"Installing with AUTOMATED_TESTING enabled...\n" );
		}
		if ( $self->_get_release_testing() ) {
			$self->trace_line( 2,
				"Installing with RELEASE_TESTING enabled...\n" );
		}
		local $ENV{AUTOMATED_TESTING} =
		  $self->_get_automated_testing() ? 1 : undef;
		local $ENV{RELEASE_TESTING} =
		  $self->_get_release_testing() ? 1 : undef;

		$self->_configure($buildpl);

		$self->_install_distribution($buildpl);

	} ## end SCOPE:

	# Making final filelist.
	my $filelist;
	if ( $self->_get_packlist() ) {
		$filelist = $self->_search_packlist($module);
	} else {
		$filelist = File::List::Object->new->readdir(
			catdir( $self->_get_image_dir(), 'perl' ) );
		$filelist->subtract($filelist_sub)->filter( $self->_filters() );
	}

	return $filelist;
} ## end sub install

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__



=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>

=head1 COPYRIGHT

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
