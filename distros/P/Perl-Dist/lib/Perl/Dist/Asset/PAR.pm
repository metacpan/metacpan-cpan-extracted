package Perl::Dist::Asset::PAR;

use strict;
use Carp              ();
use Params::Util      qw{ _STRING };
use Perl::Dist::Asset ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.16';
	@ISA     = 'Perl::Dist::Asset';
}

use Object::Tiny qw{
	name
};

=pod

=head1 NAME

Perl::Dist::Asset::PAR - "Binary .par package" asset for a Win32 Perl

=head1 SYNOPSIS

  my $binary = Perl::Dist::Asset::PAR->new(
      name       => 'dmake',
  );
  
  # Or usually more like this:
  $perl_dist_inno_obj->install_par(
    name => 'Perl-Dist-PrepackagedPAR-libexpat',
    url  => 'http://parrepository.de/Perl-Dist-PrepackagedPAR-libexpat-2.0.1-MSWin32-x86-multi-thread-anyversion.par',
  );

=head1 DESCRIPTION

B<Perl::Dist::Asset::PAR> is a data class that provides encapsulation
and error checking for a "binary .par package" to be installed in a
L<Perl::Dist>-based Perl distribution.

It is normally created on the fly by the L<Perl::Dist::Inno> C<install_par>
method (and other things that call it). The C<install_par> routine
is currently implemented in this file and monkey-patched into
L<Perl::Dist::Inno> namespace. This will hopefully change in future.

The specification of the location to retrieve the package is done via
the standard mechanism implemented in L<Perl::Dist::Asset>.

The C<install_to> argument of the L<Perl::Dist::Asset::Library> Perl::Dist asset
is nto currently supported by the PAR asset.
See L<PAR FILE FORMAT EXTENSIONS> below for details on how non-Perl binaries
are installed.

=head1 METHODS

This class inherits from L<Perl::Dist::Asset> and shares its API.

=cut




#####################################################################
# Constructor and Accessors

=pod

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::Asset::PAR> object.

It inherits all the params described in the L<Perl::Dist::Asset> C<new>
method documentation, and adds some additional params.

=over 4

=item name

The required C<name> param is the logical (arbitrary) name of the package
for the purposes of identification. A sensible default would be the name of
the primary Perl module in the package.

=back

The C<new> constructor returns a B<Perl::Dist::Asset::PAR> object,
or throws an exception (dies) if an invalid param is provided.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( _STRING($self->name) ) {
		Carp::croak("Missing or invalid name param");
	}

	return $self;
}

1;

=pod

=head1 PAR FILE FORMAT EXTENSIONS

This concerns packagers of .par binaries only. 
A .par usually mostly contains the blib/ directory after making a Perl module.
For use with Perl::Dist::Asset::PAR, there are currently three more subdirectories
which will be installed:

 blib/c/lib     => goes into the c/lib library directory for non-Perl extensions
 blib/c/bin     => goes into the c/bin executable/dll directory for non-Perl extensions
 blib/c/include => goes into the c/include header directory for non-Perl extensions
 blib/c/share   => goes into the c/share share directory for non-Perl extensions

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist>

For other issues, contact the author.

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>, L<Perl::Dist::Inno>, L<Perl::Dist::Asset>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Steffen Mueller, borrowing heavily from
Adam Kennedy's code.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
