package Perl::Dist::WiX::Asset::PAR;

=pod

=head1 NAME

Perl::Dist::WiX::Asset::PAR - "Binary .par package" asset for a Win32 Perl

=head1 VERSION

This document describes Perl::Dist::WiX::Asset::PAR version 1.500.

=head1 SYNOPSIS

  my $binary = Perl::Dist::Asset::PAR->new(
    parent => $dist, # A Perl::Dist::WiX object.
    name   => 'dmake',
    url    => 'http://parrepository.de/Perl-Dist-PrepackagedPAR-libexpat-2.0.1-MSWin32-x86-multi-thread-anyversion.par',
  );
  
  # Or usually more like this:
  $perl_dist_wix_obj->install_par(
    name => 'Perl-Dist-PrepackagedPAR-libexpat',
    url  => 'http://parrepository.de/Perl-Dist-PrepackagedPAR-libexpat-2.0.1-MSWin32-x86-multi-thread-anyversion.par',
  );

=head1 DESCRIPTION

B<Perl::Dist::WiX::Asset::PAR> is a data class that provides encapsulation
and error checking for a "binary .par package" to be installed in a
L<Perl::Dist::WiX|Perl::Dist::WiX>-based Perl distribution.

It is normally created by the L<install_par|Perl::Dist::WiX::Mixin::Installation/install_par> 
method of C<Perl::Dist::WiX> (and other things that call it). 

The specification of the location to retrieve the package is done via
the standard mechanism implemented in L<Perl::Dist::WiX::Asset|Perl::Dist::WiX::Asset>.

The C<install_to> argument of the 
L<Perl::Dist::WiX::Asset::Library|Perl::Dist::WiX::Asset::Library> 
asset is not supported by the PAR asset.

See L</PAR FILE FORMAT EXTENSIONS> below for details on how non-Perl binaries
are installed.

=cut

use 5.010;
use Moose;
use MooseX::Types::Moose qw( Str );
use File::Spec::Functions qw( catdir catfile );
use English qw( -no_match_vars );
require SelectSaver;
require PAR::Dist;
require IO::String;

our $VERSION = '1.500002';

with 'Perl::Dist::WiX::Role::Asset';

=head1 METHODS

This class is a L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset> 
and shares its API.

=pod

=head2 new

The C<new> constructor takes a series of parameters, validates them
and returns a new B<Perl::Dist::WiX::Asset::PAR> object.

The C<new> constructor will throw an exception (dies) if an invalid 
parameter is provided.

It inherits all the parameters described in the 
L<Perl::Dist::WiX::Asset/new|Perl::Dist::WiX::Asset-E<gt>new()> 
method documentation, and adds two additional parameters.

=head3 name

The required C<name> parameter is the name of the package for the purposes 
of identification in output. A sensible default would be the name of
the primary Perl module in the package.

=cut

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_name',
	required => 1,
);

=head3 dist_info

The required C<dist_info> parameter is the location of the source package 
for the .par file, either as a URL (which should be accessible for 3 years) 
or as a location on CPAN in the 'AUTHORID/dist-version.tar.gz' format.

=cut

has dist_info => (
	is       => 'ro',
	isa      => 'Str',
	reader   => '_get_dist_info',
	required => 1,
);

=head2 install

The C<install> method retrieves the specified .par file and installs it.

=cut

sub install {
	my $self = shift;

	my $name         = $self->get_name();
	my $image_dir    = $self->_get_image_dir();
	my $download_dir = $self->_get_download_dir();
	my $url          = $self->_get_url();
	my $vendor =
	    !$self->_get_parent()->portable()                    ? 1
	  : ( $self->_get_parent()->perl_major_version() >= 12 ) ? 1
	  :                                                        0;

	$self->_trace_line( 1, "Preparing $name\n" );

	my $output;
	my $io = IO::String->new($output);
	my $packlist;

	# When $saved goes out of scope, STDOUT will be restored.
	{
		my $saved = SelectSaver->new($io);

		# Download the file.
		# Do it here for consistency instead of letting PAR::Dist do it
		my $file = $self->_mirror( $url, $download_dir, );

		# Set the appropriate installation paths
		my @module_dirs = split m{::}ms, $name;
		my $perldir = catdir( $image_dir, 'perl' );
		my $libdir  = catdir( $perldir,   'vendor', 'lib' );
		my $bindir  = catdir( $perldir,   'bin' );
		my $cdir    = catdir( $image_dir, 'c' );

		if ( not $vendor ) {
			$libdir = catdir( $perldir, 'site', 'lib' );
		}
		$packlist = catfile( $libdir, 'auto', @module_dirs, '.packlist' );

		# Suppress warnings for resources that don't exist
		local $WARNING = 0;

		# Install
		PAR::Dist::install_par(
			dist           => $file,
			packlist_read  => $packlist,
			packlist_write => $packlist,
			inst_lib       => $libdir,
			inst_archlib   => $libdir,
			inst_bin       => $bindir,
			inst_script    => $bindir,
			inst_man1dir   => undef,   # no man pages
			inst_man3dir   => undef,   # no man pages
			custom_targets => {
				'blib/c/lib'     => catdir( $cdir, 'lib' ),
				'blib/c/bin'     => catdir( $cdir, 'bin' ),
				'blib/c/include' => catdir( $cdir, 'include' ),
				'blib/c/share'   => catdir( $cdir, 'share' ),
			},
		);
	}

	# Print saved output if required.
	$io->close;
	$self->_trace_line( 2, $output );

	# Get distribution name to add to what's installed.
	$self->_add_to_distributions_installed( $self->_get_dist_info() );

	# Read in the .packlist and return it.
	my $filelist =
	  File::List::Object->new->load_file($packlist)
	  ->filter( $self->_filters )->add_file($packlist);

	return $filelist;
} ## end sub install

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 PAR FILE FORMAT EXTENSIONS

This concerns packagers of .par binaries only.
 
A .par usually mostly contains the blib/ directory after making a Perl module.
For use with Perl::Dist::Asset::PAR, there are currently four more subdirectories
which will be installed:

 blib/c/lib     => goes into the c/lib library directory for non-Perl extensions
 blib/c/bin     => goes into the c/bin executable/dll directory for non-Perl extensions
 blib/c/include => goes into the c/include header directory for non-Perl extensions
 blib/c/share   => goes into the c/share share directory for non-Perl extensions

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

Copyright 2008 Steffen Mueller, borrowing heavily from
Adam Kennedy's code.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
