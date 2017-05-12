package Perl::Dist::WiX::Asset::Binary;

=pod

=head1 NAME

Perl::Dist::WiX::Asset::Binary - "Binary Package" asset for a Win32 Perl

=head1 VERSION

This document describes Perl::Dist::WiX::Asset::Binary version 1.500.

=head1 SYNOPSIS

  my $binary = Perl::Dist::WiX::Asset::Binary->new(
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
  
=head1 DESCRIPTION

B<Perl::Dist::WiX::Asset::Binary> is a data class that provides encapsulation
and error checking for a "binary package" to be installed in a
L<Perl::Dist::WiX|Perl::Dist::WiX>-based Perl distribution.

It is normally created on the fly by the 
L<Perl::Dist::WiX::Mixin::Installation|Perl::Dist::WiX::Mixin::Installation> 
C<install_binary> method (and other things that call it).

These packages will be simple zip or tar.gz files that are local files,
installed in a CPAN distribution's 'share' directory, or retrieved from
the internet via a URI.

The specification of the location to retrieve the package is done via
the standard mechanism implemented in 
L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>.

=cut

use 5.010;
use Moose;
use MooseX::Types::Moose qw( Str HashRef Maybe );
use File::Spec::Functions qw( catdir );

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

with 'Perl::Dist::WiX::Role::Asset';

=head1 METHODS

This class inherits from L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset> 
and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new C<Perl::Dist::WiX::Asset::Binary> object.

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



=head3 install_to

The required C<install_to> parameter allows you to specify which 
directories or files get installed in which subdirectories of the image 
directory of the distribution.

If a string is passed in, it is a location relative to the image directory, 
and the whole binary is extracted to that location.

If a hash reference is passed in, the keys are the directories or files 
to extract from the archive file, while the values are the locations to 
extract the directories or files to, relative to the image directory of 
the distribution.

Although this param does not default when called directly, in practice
the L<Perl::Dist::WiX|Perl::Dist::WiX> C<install_binary> method will 
default this value to "c", as most binary installations are for C toolchain 
tools or pre-compiled C libraries.

=cut



has install_to => (
	is      => 'ro',
	isa     => Str | HashRef,
	reader  => '_get_install_to',
	default => 'c',
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



=head2 install

The C<install> method extracts and installs the archive file using the 
directions described in the C<Perl::Dist::WiX::Asset::Binary> object.

=cut



sub install {
	my $self = shift;

	my $name = $self->_get_name();
	$self->_trace_line( 1, "Preparing $name\n" );

	# Download the file
	my $tgz =
	  $self->_mirror( $self->_get_url(), $self->_get_download_dir(), );

	# Unpack the archive
	my @files;
	my $install_to = $self->_get_install_to();
	if ( ref $install_to eq 'HASH' ) {
		@files =
		  $self->_extract_filemap( $tgz, $install_to,
			$self->_get_image_dir() );

	} elsif ( !ref $install_to ) {

		# unpack as a whole
		my $tgt = catdir( $self->_get_image_dir(), $install_to );
		@files = $self->_extract( $tgz, $tgt );
	}

	# Find the licenses
	my $licenses = $self->_get_license();
	if ( defined $licenses ) {
		push @files,
		  $self->_extract_filemap( $tgz, $licenses, $self->_get_license_dir,
			1 );
	}

	my $filelist =
	  File::List::Object->new()->load_array(@files)
	  ->filter( $self->_filters );

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
