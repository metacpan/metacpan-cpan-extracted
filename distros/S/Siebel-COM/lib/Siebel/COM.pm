package Siebel::COM;

use warnings;
use strict;
use Moose::Role 2.1604;
our $VERSION = '0.3'; # VERSION

has '_ole' => (
    is       => 'ro',
    isa      => 'Win32::OLE',
    reader   => 'get_ole',
    writer   => '_set_ole',
    required => 0
);

sub get_ole {

    my $self = shift;

    if ( $self->{_ole} ) {

        return $self->{_ole};

    }
    else {

        die '_ole attribute must be setup during object creation';

    }

}

1;

__END__

=head1 NAME

Siebel::COM - Perl extension to access Siebel application through Microsoft COM 

=head1 SYNOPSIS

  package Siebel::COM::App;

  use Moose;
  use namespace::autoclean;

  with 'Siebel::COM';

  sub BUILD {

      my $self = shift;

      my $app = Win32::OLE->new( $self->get_ole_class() )
        or confess( 'failed to load ' . $self->get_ole_class() . ': ' . $! );

      $self->_set_ole($app);

  }

=head1 DESCRIPTION

Siebel::COM was developed to make it easier to use Microsoft COM to access a Siebel application, 
either a Siebel Enterprise or a Siebel Client, without having to go down the details of L<Win32::OLE>.

Inspiration for this distribution came from the article (L<http://jbrazile.blogspot.com.br/2008/03/siebel-com-programming-with-perl.html>) wrote by
Jason Brazile and the despicable information in the documentation (L<http://docs.oracle.com/cd/E14004_01/books/OIRef/OIRef_About_Object_Interfaces_and_Programming_Environment6.html#wp1026164>) 
of Oracle saying that Perl cannot be used to connected to Siebel with COM.

Siebel::COM should be used directly only for maintenance or extensions since it is a L<Moose> role. You probably want to look for subclasses of
L<Siebel::COM::App> to start connecting to a Siebel environment.

This roles provides the C<_ole> attribute, with the accessors C<get_ole> and the "private" C<_set_ole>, which holds a reference to the L<Win32::OLE>
object that is used to really provide functionality from Siebel DLL's.

=head2 EXPORT

None by default.

=head2 METHODS

=head3 get_ole

Expects no parameter. Returns the L<Win32::OLE> associated with the class.

=head1 CAVEATS

A known issue is that this distribution only works with Microsoft Windows OS (which should be garanteed by L<Devel::AssertOS>).

Having a full Siebel Client setup in the OS is also required. It is also known that Siebel COM is not supported in 64 bits systems due
incompability of the required Siebel DLLs.

=head1 SEE ALSO

=over

=item *

L<Siebel::COM::App::DataServer>

=item *

L<Siebel::COM::App::DataControl>

=item *

Project website: L<https://github.com/glasswalk3r/siebel-com>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

This file is part of Siebel COM project.

Siebel COM is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel COM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel COM.  If not, see <http://www.gnu.org/licenses/>.

=cut
