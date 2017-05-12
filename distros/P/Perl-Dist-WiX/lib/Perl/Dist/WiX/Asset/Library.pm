package Perl::Dist::WiX::Asset::Library;

=pod

=head1 NAME

Perl::Dist::WiX::Asset::Library - "C Library" asset for a Win32 Perl

=head1 VERSION

This document describes Perl::Dist::WiX::Asset::Library version 1.500002.

=head1 SYNOPSIS

  my $library = Perl::Dist::Asset::Library->new(
      name       => 'zlib',
      url        => 'http://strawberryperl.com/packages/zlib-1.2.3.win32.zip',
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

=head1 DESCRIPTION

B<Perl::Dist::WiX::Asset::Library> is a data class that provides encapsulation
and error checking for a "C library" to be installed in a
L<Perl::Dist::WiX|Perl::Dist::WiX>-based Perl distribution.

It is normally created on the fly by the <Perl::Dist::WiX> C<install_library>
method (and other things that call it).

B<Perl::Dist::WiX::Asset::Library> is similar to 
L<Perl::Dist::WiX::Asset::Binary|Perl::Dist::WiX::Asset::Binary>,
in that it captures a name, source URL, and paths for where to install
files.

It also takes a few more pieces of information to support certain more
esoteric functions unique to C library builds.

The specification of the location to retrieve the package is done via
the standard mechanism implemented in 
L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>.

=cut

use 5.010;
use Moose;
use MooseX::Types::Moose qw( Str Maybe HashRef );

our $VERSION = '1.500002';

with 'Perl::Dist::WiX::Role::Asset';

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new C<Perl::Dist::WiX::Asset::Library> object.

It inherits all the parameters described in the 
L<< Perl::Dist::WiX::Role::Asset->new()|Perl::Dist::WiX::Role::Asset/new >> 
method documentation, and adds the additional parameters described below.

=head3 name

The required C<name> parameter is the name of the package for the purposes 
of identification in messages.

=cut



has name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_name',
	required => 1,
);



=head3 unpack_to

The optional C<unpack_to> parameter allows you to specify in which 
subdirectory of the build directory the tarball or zip file that was
downloaded gets unpacked to. 

It defaults to the display name.

=cut


has unpack_to => (
	is      => 'ro',
	isa     => Str,
	reader  => '_get_unpack_to',
	lazy    => 1,
	default => sub { $_[0]->_get_name() },
);



=head3 license

The C<license> parameter allows you to specify which files get 
copied to the license directory of the distribution.

The keys are the files to copy, as relative filenames from the subdirectory
named in C<unpack_to>. If the tarball is properly made, the filenames will 
include the name and version of the library.

The values are the locations to copy them to, relative to the license 
directory of the distribution.

=cut



has license => (
	is      => 'ro',
	isa     => Maybe [HashRef],
	reader  => '_get_license',
	default => undef,
);



=head3 install_to

The required C<install_to> parameter allows you to specify which directories
get installed in which subdirectories of the image directory of the 
distribution.

The keys are the directories to copy, relative to the subdirectory
named in C<unpack_to>. The directory names may include the name and 
version of the library.

The values are the locations to copy the directories to, relative to the 
image directory of the distribution.

=cut



has install_to => (
	is       => 'ro',
	isa      => HashRef,
	reader   => '_get_install_to',
	required => 1,
);



=head3 build_a

The C<build_a> parameter allows you to specify that the library needs
to have its import library created.

A hash reference with 3 keys is passed in: either a 'dll' or 'source'
key, and 'def' and 'a' keys.

The file referred to in the value of the C<source> key is copied to 
the directory named in C<unpack_to>.

The value of the C<dll> key, if that is used, is the dll that needs its 
import library created.

The value of the C<def> key is where to write the .def file, 
and the value of the C<a> key is where to write the final import library.

All files are relative to the directory named in C<unpack_to>. The 
directory names may include the name and version of the library.

=cut



has build_a => (
	is      => 'ro',
	isa     => HashRef,
	reader  => '_get_build_a',
	default => sub { return {} },
);



=head2 install

The install method installs the Perl library by the
B<Perl::Dist::WiX::Asset::Library> object and returns true or throws
an exception.

=cut



sub install {
	my $self = shift;

	# Announce the fact that we're starting to install a library.
	my $name = $self->_get_name();
	$self->_trace_line( 1, "Preparing $name\n" );

	# Download the file
	my $tgz =
	  $self->_mirror( $self->_get_url(), $self->_get_download_dir(), );

	# Unpack to the build directory
	my @files;
	my $unpack_to =
	  catdir( $self->_get_build_dir(), $self->_get_unpack_to() );
	if ( -d $unpack_to ) {
		$self->_trace_line( 2, "Removing previous $unpack_to\n" );
		$self->remove_path($unpack_to);
	}
	@files = $self->_extract( $tgz, $unpack_to );

	# Build the .a file if needed
	my $build_a = $self->_get_build_a();
	if ( defined $build_a ) {

		# If we have a source, use it.
		my @source = ();
		if ( $build_a->{source} ) {
			@source = ( dll => catfile( $unpack_to, $build_a->{source} ) );
		}

		# Hand off for the .a generation
		push @files,
		  $self->_dll_to_a(
			dll => catfile( $unpack_to, $build_a->{dll} ),
			def => catfile( $unpack_to, $build_a->{def} ),
			a   => catfile( $unpack_to, $build_a->{a} ),
			@source,
		  );
	} ## end if ( defined $build_a )

	# Copy in the files
	my $install_to = $self->_get_install_to();
	if ($install_to) {
		foreach my $k ( sort keys %{$install_to} ) {
			my $from = catdir( $unpack_to, $k );
			my $to = catdir( $self->_get_image_dir(), $install_to->{$k} );
			$self->_copy( $from, $to );
			@files = $self->_copy_filesref( \@files, $from, $to );
		}
	}

	# Copy in licenses
	my $licenses = $self->_get_license();
	if ( defined $licenses ) {
		my $license_dir = $self->_dir('licenses');
		push @files,
		  $self->_extract_filemap( $tgz, $licenses, $license_dir, 1 );
	}

	# Create the list of files.
	my @sorted_files = sort { $a cmp $b } @files;
	my $filelist =
	  File::List::Object->new->load_array(@sorted_files)
	  ->filter( $self->_filters() )->filter( [$unpack_to] );

	return $filelist;
} ## end sub install



# This routine copies a list of files, while changing the directory
# the files are in.
# It does not copy the files themselves.
sub _copy_filesref {
	my ( $self, $files_ref, $from, $to ) = @_;

	# Move each file referred to in @$file_ref from $from to $to.
	my @files;
	foreach my $file ( @{$files_ref} ) {
		if ( $file =~ m{\A\Q$from\E}msx ) {
			$file =~ s{\A\Q$from\E}{$to}msx;
		}
		push @files, $file;
	}

	return @files;
} ## end sub _copy_filesref



# Generate a .a file from a .dll.
sub _dll_to_a {
	my $self   = shift;
	my %params = @_;

	# Check for binaries required.
	if ( not $self->_bin_dlltool() ) {
		PDWiX->throw('dlltool has not been installed');
	}
	if ( not $self->_bin_pexports() ) {
		PDWiX->throw('pexports has not been installed');
	}

	my @files;

	# Source file
	my $source = $params{source};
	if ( $source and not( $source =~ /[.]dll\z/msx ) ) {
		PDWiX::Parameter->throw(
			parameter => 'source',
			where     => '::Asset::Library->_dll_to_a'
		);
	}

	# Target .dll file
	my $dll = $params{dll};
	if ( not $dll or $dll !~ /[.]dll/msx ) {
		PDWiX::Parameter->throw(
			parameter => 'dll',
			where     => '::Asset::Library->_dll_to_a'
		);
	}

	# Target .def file
	my $def = $params{def};
	if ( not $def or $def !~ /[.]def\z/msx ) {
		PDWiX::Parameter->throw(
			parameter => 'def',
			where     => '::Asset::Library->_dll_to_a'
		);
	}

	# Target .a file
	my $_a = $params{a};
	if ( not $_a or $_a !~ /[.]a\z/msx ) {
		PDWiX::Parameter->throw(
			parameter => 'a',
			where     => '::Asset::Library->_dll_to_a'
		);
	}

	# Step 1 - Copy the source .dll to the target if needed
	if ( not( ( $source and -f $source ) or -f $dll ) ) {
		PDWiX::Parameter->throw(
			parameter => 'source or dll: Need one of '
			  . 'these two parameters, and the file needs to exist',
			where => '::Asset::Library->_dll_to_a'
		);
	}

	if ($source) {
		$self->_move( $source => $dll );
		push @files, $dll;
	}

	# Step 2 - Generate the .def from the .dll
  SCOPE: {
		my $bin = $self->_bin_pexports();
		my $ok  = !system "$bin $dll > $def";
		if ( not $ok or not -f $def ) {
			PDWiX->throw('pexports failed to generate .def file');
		}

		push @files, $def;
	}

	# Step 3 - Generate the .a from the .def
  SCOPE: {
		my $bin = $self->_bin_dlltool();
		my $ok  = !system "$bin -dllname $dll --def $def --output-lib $_a";
		if ( not $ok or not -f $_a ) {
			PDWiX->throw('dlltool failed to generate .a file');
		}

		push @files, $_a;
	}

	return @files;
} ## end sub _dll_to_a

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

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
