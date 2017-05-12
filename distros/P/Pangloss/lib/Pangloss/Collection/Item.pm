=head1 NAME

Pangloss::Collection::Item - base class for items stored in a collection.

=head1 SYNOPSIS

  # abstract - cannot be used
  use base qw( Pangloss::Collection::Item );

  my $key = $obj->key();

=cut

package Pangloss::Collection::Item;

use strict;
use warnings::register;

use Error;
use OpenFrame::WebApp::Error::Abstract;

use base      qw( Pangloss::Object );
use accessors qw( error );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.6 $ '))[2];

sub key {
    my $class = shift->class;
    throw OpenFrame::WebApp::Error::Abstract( class => $class );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Base class for Items stored in a L<Pangloss::Collection>.

=head1 METHODS

=over 4

=item $obj->key()

abstract.  get/set this object's key.

=item $obj->error

set/get the L<Pangloss::Error> associated with this object.

I<NOTE:> watch out if inheriting from L<OpenFrame::Object> - it has an
C<error()> method too.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>,
L<OpenFrame::WebApp::Error::Abstract>

=cut

