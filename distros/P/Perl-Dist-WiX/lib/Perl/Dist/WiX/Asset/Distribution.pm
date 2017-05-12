package Perl::Dist::WiX::Asset::Distribution;

=pod

=head1 NAME

Perl::Dist::WiX::Asset::Distribution - "Perl Distribution" asset for a Win32 Perl

=head1 VERSION

This document describes Perl::Dist::WiX::Asset::Distribution version 1.500002.

=head1 SYNOPSIS

  my $distribution = Perl::Dist::WiX::Asset::Distribution->new(
      parent   => $dist,
      name     => 'MSERGEANT/DBD-SQLite-1.14.tar.gz',
	  mod_name => 'DBD::SQLite',
      force    => 1,
  );

=head1 DESCRIPTION

L<Perl::Dist::WiX|Perl::Dist::WiX> supports two methods for adding Perl modules to the
installation. The main method is to install it via the CPAN shell.

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

B<Perl::Dist::WiX::Asset::Distribution> is a data class that provides
encapsulation and error checking for a "Perl Distribution" to be
installed in a C<Perl::Dist::WiX>-created installer using this
secondary method.

It is normally created on the fly by the Perl::Dist::WiX
C<install_distribution> method (and other things that call it).

=cut

#<<<
use 5.010;
use Moose;
use MooseX::Types::Moose   qw( Str Bool ArrayRef Maybe );
use English                qw( -no_match_vars );
use File::Spec::Functions  qw( catdir catfile );
use Params::Util           qw( _INSTANCE );
use URI                    qw();
#>>>

our $VERSION = '1.500002';

with 'Perl::Dist::WiX::Role::Asset';
extends 'Perl::Dist::WiX::Asset::DistBase';

=head1 METHODS

This class is a L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>
and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::WiX::Asset::Distribution> object.

It inherits all the parameters described in the 
L<< Perl::Dist::WiX::Role::Asset->new|Perl::Dist::WiX::Role::Asset/new >> 
method documentation, and adds the additional parameters described below.

=head3 name

The required C<name> param is the CPAN path to the distribution
such as shown in the synopsis.

The url to fetch from will be derived from the name.

=cut



has name => (
	is       => 'bare',
	isa      => Str,
	reader   => 'get_name',
	required => 1,
);



=head3 mod_name

The required C<mod_name> param is the name of the main module being 
installed. This is used to create the fragment name.

=cut



has module_name => (
	is       => 'bare',
	isa      => Maybe [Str],
	reader   => 'get_module_name',
	init_arg => 'mod_name',
	lazy     => 1,
	default  => sub { return $_[0]->_name_to_module(); },
);



=head3 force

The optional boolean C<force> param allows you to specify that the tests
should be skipped and the distribution installed without validating it.

It defaults to the force() attribute of the parent.

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

Defaults to false.

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



=head3 overwritable

Some distributions (ExtUtils::MakeMaker, for example) install files that
are overwritten by distributions installed after it.

The optional C<overwritable> param lets you spedify that this is the case, 
and defaults to false.

=cut



has overwritable => (
	is      => 'ro',
	isa     => Bool,
	reader  => '_get_overwritable',
	default => 0,
);



sub BUILDARGS {
	my $class = shift;
	my %args;

	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%args = (@_);
	} else {
		PDWiX->throw( 'Parameters incorrect (not a hashref or hash) '
			  . 'for Perl::Dist::WiX::Asset::Distribution' );
	}

	if ( not defined _INSTANCE( $args{parent}, 'Perl::Dist::WiX' ) ) {
		PDWiX::Parameter->throw(
			parameter =>
			  'parent: missing or not a Perl::Dist::WiX instance',
			where => '::Asset::Distribution->new',
		);
	}

	if ( exists $args{url} ) {
		PDWiX::Parameter->throw(
			parameter =>
'url: Passed in (please remove - it will be calculated from name)',
			where => '::Asset::Distribution->new',
		);
	}

	if ( exists $args{file} ) {
		PDWiX::Parameter->throw(
			parameter =>
'file: Passed in (please remove - it will be calculated from name)',
			where => '::Asset::Distribution->new',
		);
	}

	# Map CPAN dist path to url
	my $dist = $args{name};
	if ( !defined $dist ) {
		PDWiX::Parameter->throw(
			parameter => 'name: Not defined',
			where     => '::Asset::Distribution->new',
		);
	}

	$args{parent}->trace_line( 2, "Using distribution path $dist\n" );
	my $one = substr $dist, 0, 1;
	my $two = substr $dist, 1, 1;
	my $path =
	  File::Spec::Unix->catfile( 'authors', 'id', $one, "$one$two", $dist,
	  );
	$args{url} = URI->new_abs( $path, $args{parent}->cpan() )->as_string();
	$args{file} = $args{url};
	$args{file} =~ s{.+/}{}ms;

	return {%args};
} ## end sub BUILDARGS

sub BUILD {
	my $self = shift;

	if ( $self->get_name() eq $self->_get_url()
		and not _DIST( $self->get_name() ) )
	{
		PDWiX::Parameter->throw("Missing or invalid name param\n");
	}

	return;
}


# get_name is defined earlier, in the "has name =>" line.
# Here works for documenting it.

=head2 get_name

This method returns the name of the module being installed, in order to use
it in filenames.

=head2 install

The install method installs the distribution described by the
B<Perl::Dist::WiX::Asset::Distribution> object and returns a list of files
that were installed as a L<File::List::Object|File::List::Object> object.

=cut



sub install {
	my $self = shift;

	my $name      = $self->get_name();
	my $build_dir = $self->_get_build_dir();

# If we don't have a packlist file, get an initial filelist to subtract from.
	my $module = $self->get_module_name();
	my $filelist_sub;

	if ( not $self->_get_packlist() ) {
		$filelist_sub =
		  File::List::Object->new->readdir( $self->_dir('perl') );
		$self->_trace_line( 5,
			    "***** Module being installed $module"
			  . " requires packlist => 0 *****\n" );
	}

	# Download the file
	my $url = $self->_abs_uri( $self->_get_cpan() );
	my $tgz =
	  eval { $self->_mirror_url( $url, $self->_get_modules_dir(), ) }
	  || PDWiX::Caught->throw(
		message => $EVAL_ERROR,
		info    => 'Error trying to download distribution'
	  );

	# Does it exist? If not, throw an error here.
	if ( not -f $tgz ) {
		PDWiX->throw('The file from an attempted download does not exist');
	}

	# Where will it get extracted to
	my $dist_path = $name;
	$self->_add_to_distributions_installed($dist_path);
	$dist_path =~ s{[.] tar [.] gz}{}msx;            # Take off extensions.
	$dist_path =~ s{[.] zip}{}msx;
	$dist_path =~ s{.+\/}{}msx;        # Take off directories.
	$dist_path =~ s{-withoutworldwriteables$}{}msx;
	my $unpack_to = catdir( $build_dir, $dist_path );

	# Extract the tarball
	if ( -d $unpack_to ) {
		$self->_trace_line( 2, "Removing previous $unpack_to\n" );
		$self->remove_path( \1, $unpack_to );
	}
	$self->_extract( $tgz => $build_dir );
	if ( not -d $unpack_to ) {
		PDWiX->throw("Failed to extract $unpack_to\n");
	}

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

	# Can't build version.pm using Build.PL until Module::Build
	# has been upgraded.
	if ( $module eq 'version' ) {
		$self->_trace_line( 3, "Bypassing version.pm's Build.PL\n" );
		$buildpl = 0;
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
			$self->_trace_line( 2,
				"Installing with RELEASE_TESTING enabled...\n" );
		}
		local $ENV{AUTOMATED_TESTING} =
		  $self->_get_automated_testing() ? 1 : undef;
		local $ENV{RELEASE_TESTING} =
		  $self->_get_release_testing() ? 1 : undef;
		local $ENV{PERL_MM_USE_DEFAULT}    = 1;
		local $ENV{PERL_MM_NONINTERACTIVE} = 1;

		$self->_configure($buildpl);

		$self->_install_distribution($buildpl);

	} ## end SCOPE:

	# Making final filelist.
	my $filelist;
	if ( $self->_get_packlist() ) {
		$filelist = $self->_search_packlist($module);
	} else {
		$filelist =
		  File::List::Object->new()->readdir( $self->_dir('perl') );
		$filelist->subtract($filelist_sub)->filter( $self->_filters() );
	}

	my $module_name = $self->get_module_name();
	$module_name =~ s{::}{_}msg;
	$module_name =~ s{-}{_}msg;

	# Insert fragment.
	$self->_insert_fragment( $module_name, $filelist,
		$self->_get_overwritable() );

	return 1;
} ## end sub install

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>

=head1 COPYRIGHT

Copyright 2009 - 2011 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
