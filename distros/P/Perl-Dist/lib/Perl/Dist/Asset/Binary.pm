package Perl::Dist::Asset::Binary;

=pod

=head1 NAME

Perl::Dist::Asset::Binary - "Binary Package" asset for a Win32 Perl

=head1 SYNOPSIS

  my $binary = Perl::Dist::Asset::Binary->new(
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

B<Perl::Dist::Asset::Binary> is a data class that provides encapsulation
and error checking for a "binary package" to be installed in a
L<Perl::Dist>-based Perl distribution.

It is normally created on the fly by the <Perl::Dist::Inno> C<install_binary>
method (and other things that call it).

These packages will be simple zip or tar.gz files that are local files,
installed in a CPAN distribution's 'share' directory, or retrieved from
the internet via a URI.

The specification of the location to retrieve the package is done via
the standard mechanism implemented in L<Perl::Dist::Asset>.

=head1 METHODS

This class inherits from L<Perl::Dist::Asset> and shares its API.

=cut

use strict;
use Carp              ();
use Params::Util      qw{ _STRING _HASH };
use Perl::Dist::Asset ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.16';
	@ISA     = 'Perl::Dist::Asset';
}

use Object::Tiny qw{
	name
	license
	install_to
};





#####################################################################
# Constructor and Accessors

=pod

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::Asset::Binary> object.

It inherits all the params described in the L<Perl::Dist::Asset> C<new>
method documentation, and adds some additional params.

=over 4

=item name

The required C<name> param is the logical (arbitrary) name of the package
for the purposes of identification.

=item license

During the installation build process, licenses files are pulled from
the various source packages and written to a single dedicated directory.

The optional C<license> param should be a reference to a HASH, where the keys
are the location of license files within the package, and the values are
locations within the "licenses" subdirectory of the final installation.

=item install_to

The required C<install_to> param describes the location that the package
will be installed to.

If the C<install_to> param is a single string, such as "c" or "perl\foo"
the entire binary package will be installed, with the root of the package
archive being placed in the directory specified.

If the C<install_to> param is a reference to a HASH, it is taken to mean
that only some parts of the original binary package are required in the
final install. In this case, the keys should be the file or directories
desired, and the values are the names of the file or directory in the
final Perl installation.

Although this param does not default when called directly, in practice
the L<Perl::Dist::Inno> C<install_binary> method will default this value
to "c", as most binary installations are for C toolchain tools or 
pre-compiled C libraries.

=back

The C<new> constructor returns a B<Perl::Dist::Asset::Binary> object,
or throws an exception (dies) if an invalid param is provided.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( _STRING($self->name) ) {
		Carp::croak("Missing or invalid name param");
	}
	unless ( _STRING($self->install_to) or _HASH($self->install_to) ) {
		Carp::croak("Missing or invalid install_to param");
	}

	return $self;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>, L<Perl::Dist::Inno>, L<Perl::Dist::Asset>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
