package Perl::Dist::Asset::File;

=pod

=head1 NAME

Perl::Dist::Asset::File - "Single File" asset for a Win32 Perl

=head1 SYNOPSIS

  my $binary = Perl::Dist::Asset::File->new(
      url        => 'http://host/path/file',
      install_to => 'perl/foo.txt',
  );

=head1 DESCRIPTION

B<Perl::Dist::Asset::File> is a data class that provides encapsulation
and error checking for a single file to be installed unmodified into a
L<Perl::Dist>-based Perl distribution.

It is normally created on the fly by the <Perl::Dist::Inno> C<install_file>
method (and other things that call it).

This asset exists to allow for cases where very small tweaks need to be
done to distributions by dropping in specific single files.

The specification of the location to retrieve the package is done via
the standard mechanism implemented in L<Perl::Dist::Asset>.

=head1 METHODS

This class inherits from L<Perl::Dist::Asset> and shares its API.

=cut

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
	install_to
};





#####################################################################
# Constructor

=pod

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::Asset::Binary> object.

It inherits all the params described in the L<Perl::Dist::Asset> C<new>
method documentation, and adds some additional params.

=over 4

=item install_to

The required C<install_to> param describes the location that the package
will be installed to.

The C<install_to> param should be a simple string that represents the
entire destination path (including file name).

=back

The C<new> constructor returns a B<Perl::Dist::Asset::File> object,
or throws an exception (dies) if an invalid param is provided.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( _STRING($self->install_to) ) {
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
