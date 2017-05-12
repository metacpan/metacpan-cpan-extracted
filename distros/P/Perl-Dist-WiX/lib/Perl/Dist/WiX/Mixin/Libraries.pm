package Perl::Dist::WiX::Mixin::Libraries;

=pod

=head1 NAME

Perl::Dist::WiX::Mixin::Libraries - Library installation routines

=head1 VERSION

This document describes Perl::Dist::WiX::Mixin::Libraries version 1.500002.

=head1 DESCRIPTION

This module provides the routines that Perl::Dist::WiX uses in order to
install the C toolchain and library files.  

=head1 SYNOPSIS

	# This module is not to be used independently.
	# It provides methods to be called on a Perl::Dist::WiX object.

=head1 INTERFACE

=cut

use 5.010;
use Moose;
use File::Spec::Functions qw( catfile );
use Params::Util qw( _STRING );
use Perl::Dist::WiX::Exceptions;
use Readonly;

our $VERSION = '1.500002';
$VERSION =~ s/_//ms;

Readonly my %PACKAGES => (
	'32bit-gcc3' => {
		'dmake'         => 'dmake-4.8-20070327-SHAY.zip',
		'mingw-make'    => 'mingw32-make-3.81-2.tar.gz',
		'pexports'      => '32bit-gcc3/pexports-0.43-1-20100120.zip',
		'gcc-toolchain' => 'mingw32-gcc3-toolchain-20091026-subset.tar.gz',
		'gcc-license'   => undef,

# Former components of what's now included in gcc-toolchain.
#		'gcc-core'      => 'gcc-core-3.4.5-20060117-3.tar.gz',
#		'gcc-g++'       => 'gcc-g++-3.4.5-20060117-3.tar.gz',
#		'binutils'      => 'binutils-2.17.50-20060824-1.tar.gz',
#		'mingw-runtime' => 'mingw-runtime-3.13.tar.gz',
#		'w32api'        => 'w32api-3.10.tar.gz',
	},
	'32bit-gcc4' => {
		'dmake'      => '32bit-gcc4/dmake-SVN20091127-bin_20100524.zip',
		'mingw-make' => '32bit-gcc4/gmake-3.81-20090914-bin_20100524.zip',
		'pexports'   => '32bit-gcc4/pexports-0.44-bin_20100120.zip',
		'gcc-toolchain' => '32bit-gcc4/mingw64-w32-20100123-kmx-v2.zip',
		'gcc-license'   => '32bit-gcc4/mingw64-w32-20100123-kmx-v2-lic.zip',
	},
	'64bit-gcc4' => {
		'dmake'         => '64bit-gcc4/dmake-SVN20091127-bin_20100524.zip',
		'mingw-make'    => '64bit-gcc4/gmake-3.81.90_20100127_20100524.zip',
		'pexports'      => '64bit-gcc4/pexports-0.44-bin_20100110.zip',
		'gcc-toolchain' => '64bit-gcc4/mingw64-w64-20100123-kmx-v2.zip',
		'gcc-license'   => '64bit-gcc4/mingw64-w64-20100123-kmx-v2-lic.zip',
	},
);

=pod

=head2 library_directory

  $dist->library_directory()

The C<library_directory> method returns the correct directory on the
strawberryperl.com server for libraries, given the L<bits()|Perl::Dist::WiX/bits> 
and L<gcc_version()|Perl::Dist::WiX/gcc_version> values.

=cut



sub library_directory {
	my $self = shift;

	my $answer = $self->bits() . 'bit-gcc' . $self->gcc_version();

	return $answer;
}



# Private routine to get the filename for a package.
sub _binary_file {
	my $self    = shift;
	my $package = shift;

	my $toolchain = $self->library_directory();

	$self->trace_line( 3, "Searching for $package in $toolchain\n" );

	if ( not exists $PACKAGES{$toolchain} ) {
		PDWiX->throw('Can only build 32 or 64-bit versions of perl');
	}

	if ( not exists $PACKAGES{$toolchain}{$package} ) {
		PDWiX->throw(
			'get_package_file was called on a package that was not defined.'
		);
	}

	my $package_file = $PACKAGES{$toolchain}{$package};
	$self->trace_line( 3, "Package $package is in $package_file\n" );

	return $package_file;
} ## end sub _binary_file


# Private routine to map a file or package name to a URL.
sub _binary_url {
	my $self = shift;
	my $file = shift;

	# Check parameters.
	if ( not _STRING($file) ) {
		PDWiX::Parameter->throw(
			parameter => 'file',
			where     => '->_binary_url'
		);
	}

	if ( $file !~ /[.] (?:zip | gz | tgz | par) \z/imsx ) {

		# Shorthand, map to full file name
		$file = $self->_binary_file( $file, @_ );
	}
	return $self->binary_root() . q{/} . $file;
} ## end sub _binary_url



#####################################################################
# Installing C Toolchain and Library Packages

=pod

=head2 install_gcc_toolchain

  $dist->install_gcc_toolchain()

The C<install_gcc_toolchain> method installs the corrent gcc toolchain into the
distribution, and is typically installed during "C toolchain" build
phase.

It provides the approproate arguments to C<install_binary> and then
validates that the binary was installed correctly.

Returns true or throws an exception on error.

=cut



sub install_gcc_toolchain {
	my $self = shift;

	# Install the gcc toolchain
	my $filelist = $self->install_binary(
		name => 'gcc-toolchain',
		url  => $self->_binary_url('gcc-toolchain'),
		( 32 == $self->bits() )
		? (
			license => {
				'COPYING'     => 'gcc/COPYING',
				'COPYING.lib' => 'gcc/COPYING.lib',
			},
		  )
		: (),
	);

	my $overwritable = ( 3 == $self->gcc_version() ) ? 1 : 0;
	$self->insert_fragment( 'gcc_toolchain', $filelist, $overwritable );

	# Initialize the dlltool location.
	$self->_set_bin_dlltool( $self->file( 'c', 'bin', 'dlltool.exe' ) );
	if ( not -x $self->bin_dlltool() ) {
		PDWiX->throw(q{Can't execute dlltool});
	}

	# Install the licenses (they're in a different file for gcc4)
	if ( 4 == $self->gcc_version() ) {
		my $filelist2 = $self->install_binary(
			name       => 'gcc-license',
			url        => $self->_binary_url('gcc-license'),
			install_to => q{.},
		);
		$self->insert_fragment( 'gcc_license', $filelist2 );
	}

	return 1;
} ## end sub install_gcc_toolchain



=pod

=head2 install_dmake

  $dist->install_dmake()

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
	my $filelist = $self->install_binary(
		name    => 'dmake',
		url     => $self->_binary_url('dmake'),
		license => {
			'dmake/COPYING'            => 'dmake/COPYING',
			'dmake/readme/license.txt' => 'dmake/license.txt',
			( 4 == $self->gcc_version )
			? ( 'dmake/readme/_INFO_' => 'dmake/_INFO_' )
			: ()
		},
		install_to => {
			'dmake/dmake.exe' => 'c/bin/dmake.exe',
			'dmake/startup'   => 'c/bin/startup',
		},
	);

	# Initialize the make location
	$self->_set_bin_make( $self->file( 'c', 'bin', 'dmake.exe' ) );
	if ( not -x $self->bin_make() ) {
		PDWiX->throw(q{Can't execute make});
	}

	$self->insert_fragment( 'dmake', $filelist );

	return 1;
} ## end sub install_dmake



=pod

=head2 install_pexports

  $dist->install_pexports()

The C<install_pexports> method installs the C<MinGW pexports> package
into the distribution.

This is needed by some libraries to let the Perl interfaces build against
them correctly.

Returns true or throws an exception on error.

=cut



sub install_pexports {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'pexports',
		url        => $self->_binary_url('pexports'),
		install_to => q{.},
	);

	# Initialize the pexports location.
	$self->_set_bin_pexports( $self->file( 'c', 'bin', 'pexports.exe' ) );
	if ( not -x $self->bin_pexports() ) {
		PDWiX->throw(q{Can't execute pexports});
	}

	$self->insert_fragment( 'pexports', $filelist );

	return 1;
} ## end sub install_pexports



=pod

=head2 install_mingw_make

  $dist->install_mingw_make()

The C<install_mingw_make> method installs the MinGW build of the B<GNU make>
build tool.

While GNU make is not used by Perl itself, some C libraries can't be built
using the normal C<dmake> tool and explicitly need GNU make. So we install
it as mingw-make and certain Alien:: modules will use it by that name.

Returns true or throws an exception on error.

=cut



sub install_mingw_make {
	my $self = shift;

	my $filelist;

	if ( 4 == $self->gcc_version() ) {
		$filelist = $self->install_binary(
			name    => 'mingw-make',
			url     => $self->_binary_url('mingw-make'),
			license => {
				'doc/COPYING' => 'gmake/COPYING',
				'doc/AUTHORS' => 'gmake/AUTHORS',
				( 4 == $self->gcc_version )
				? ( 'doc/_INFO_' => 'gmake/_INFO_' )
				: ()
			},
			install_to => { 'bin/gmake.exe' => 'c/bin/gmake.exe', },
		);
	} else {
		$filelist = $self->install_binary(
			name    => 'mingw-make',
			url     => $self->_binary_url('mingw-make'),
			license => {
				'doc/mingw32-make/COPYING'      => 'gmake/COPYING',
				'doc/mingw32-make/README.mingw' => 'gmake/README.mingw.txt',
			},
			install_to =>
			  { 'bin/mingw32-make.exe' => 'c/bin/mingw32-make.exe', },
		);
	} ## end else [ if ( 4 == $self->gcc_version...)]

	$self->insert_fragment( 'mingw_make', $filelist );

	return 1;
} ## end sub install_mingw_make

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2011 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
