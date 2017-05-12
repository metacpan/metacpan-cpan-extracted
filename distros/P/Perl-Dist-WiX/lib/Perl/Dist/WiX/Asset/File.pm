package Perl::Dist::WiX::Asset::File;

=pod

=head1 NAME

Perl::Dist::WiX::Asset::File - "Single File" asset for a Win32 Perl

=head1 VERSION

This document describes Perl::Dist::WiX::Asset::File version 1.500002.

=head1 SYNOPSIS

  my $binary = Perl::Dist::Asset::File->new(
      url        => 'http://host/path/file',
      install_to => 'perl/foo.txt',
  );

=head1 DESCRIPTION

B<Perl::Dist::Asset::File> is a data class that provides encapsulation
and error checking for a single file to be installed unmodified into a
L<Perl::Dist::WiX|Perl::Dist::WiX>-based Perl distribution.

It is normally created on the fly by the <Perl::Dist::WiX> C<install_file>
method (and other things that call it).

This asset exists to allow for cases where very small tweaks need to be
done to distributions by dropping in specific single files.

The specification of the location to retrieve the package is done via
the standard mechanism implemented in 
L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>.

=cut

use 5.010;
use Moose;
use MooseX::Types::Moose qw( Str );
use File::Spec::Functions qw( catfile );
use File::List::Object qw();

our $VERSION = '1.500002';

with 'Perl::Dist::WiX::Role::Asset';

=head1 METHODS

This class is a L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>
and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new C<Perl::Dist::WiX::Asset::File> object.

It inherits all the parameters described in the 
L<< Perl::Dist::WiX::Role::Asset->new|Perl::Dist::WiX::Role::Asset/new() >> 
method documentation, and adds an additional parameter described below.

=head3 install_to

The C<install_to> parameter is the location that the file needs installed
to, relative to the distribution's image directory.

=cut



has install_to => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_install_to',
	required => 1,
);



=head2 install

The install method installs the file described by the
B<Perl::Dist::WiX::Asset::File> object and returns true or throws
an exception.

=cut



sub install {
	my $self = shift;

	# Set up required variables.
	my $download_dir = $self->_get_download_dir();
	my $image_dir    = $self->_get_image_dir();
	my @files;

	# Get the file.
	my $file = $self->_mirror( $self->_get_url(), $download_dir );

	# Copy the file to the target location
	my $from = catfile( $download_dir, $self->_get_file() );
	my $to   = catfile( $image_dir,    $self->_get_install_to() );
	if ( not -f $to ) {
		push @files, $to;
	}

	$self->_copy( $from => $to );

	# Clear the download file
	## TODO: Deal with the 'no critic'
	unlink $file; ## no critic(RequireCheckedSyscalls)

	my $filelist =
	  File::List::Object->new()->load_array(@files)
	  ->filter( $self->_filters() );

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
