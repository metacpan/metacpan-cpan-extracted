=head1 NAME

Pangloss::Search::Filter - abstract search filter

=head1 SYNOPSIS

  # abstract - must be sub-classed for use
  use Pangloss::Search::Filter::Foo;

  my $filter = $Pangloss::Search::Filter::Foo->new;

  do { ... } if $filter->parent( $self )->applies_to( $term );

=cut

package Pangloss::Search::Filter;

use Error;
use OpenFrame::WebApp::Error::Abstract;

use base      qw( Pangloss::Object );
use accessors qw( parent );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.9 $ '))[2];

sub applies_to {
    my $class = shift->class;
    throw OpenFrame::WebApp::Error::Abstract( class => $class );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

An abstract search filter object.

=head1 METHODS

=over 4

=item $bool = $obj->applies_to( $term )

abstract.  test to see if this filter applies to the L<Pangloss::Term> given.
a return value of C<true> indicates that the $term should be added to the
result set.

=item $obj->parent

get/set this filter's parent L<Pangloss::Search>.

=back

=head1 SUB-CLASSING

At the very least, you must do the following:

  package Foo;
  use base qw( Pangloss::Search::Filter );

  sub applies_to {
      my $self = shift;
      my $term = shift;

      # use $term and the collections available
      # via $self->parent to do your test

      return 0 || 1;
  }

L<Pangloss::Search> will set $self->parent() before it calls C<applies_to()>.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Search>,
L<Pangloss::Search::Request>,
L<OpenFrame::WebApp::Error::Abstract>

=head2 Known Sub-Classes

L<Pangloss::Search::Filter::Base>,
L<Pangloss::Search::Filter::Keywords>

=cut

