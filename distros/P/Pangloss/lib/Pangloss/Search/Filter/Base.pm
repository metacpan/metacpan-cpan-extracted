=head1 NAME

Pangloss::Search::Filter::Base - base class for collection filters

=head1 SYNOPSIS

  # abstract - must be subclassed for use:
  use Pangloss::Search::Filter::FooBar;
  my $filter = new Pangloss::Search::Filter::FooBar()->set( $baz );

=cut

package Pangloss::Search::Filter::Base;

use Error;
use OpenFrame::WebApp::Error::Abstract;

use base      qw( Pangloss::Search::Filter );
use accessors qw( item_keys );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.7 $ '))[2];

sub init {
    shift->reset();
}

sub applies_to {
    my $class = shift->class;
    throw OpenFrame::WebApp::Error::Abstract( class => $class );
}

sub set {
    my $self = shift;
    $self->item_keys->{$_} = 1 for @_;
    return $self;
}

sub unset {
    my $self = shift;
    delete $self->item_keys->{$_} for @_;
    return $self;
}

sub reset {
    shift->item_keys( {} );
}

sub is_set {
    exists shift->item_keys->{shift()};
}

sub not_set {
    ! shift->is_set( @_ );
}

sub toggle {
    my $self = shift;
    my $key  = shift;
    if ($self->exists( $key )) {
	$self->unset( $key );
	return 0;
    }
    $self->set( $key );
    return 1;
}

sub add { shift->set( @_ ); }
sub del { shift->unset( @_ ); }
sub exists { shift->is_set( @_ ); }

sub keys {
    return CORE::keys( %{ shift->item_keys } );
}

sub size {
    return scalar CORE::keys( %{ shift->item_keys } );
}

sub is_empty {
    return shift->size ? 0 : 1;
}

sub not_empty {
    return ! shift->is_empty;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

An abstract search filter object for use with <Pangloss::Collection::Item>s.

=head1 METHODS

=over 4

=item $obj->item_keys

get/set this filter's hash of collection-item keys (see sub-classes for usage).

=item $obj->keys

get the keys as a list.

=item $bool = $obj->toggle( $key )

toggle given key, returns current state true => on, false => off.

=item $obj = $obj->set( $key [, $key2 ... ] )

set given keys to on.

=item $obj = $obj->unset( $key [, $key2 ... ] )

set given keys to off.

=item $bool = $obj->is_set( $key )

test to see if the given key is set.

=item $obj = $obj->reset

clear all set keys.

=item $size = $obj->size

get number of keys currently set.

=item $bool = $obj->is_empty

test to see if no keys are currently set.

=item $bool = $obj->not_empty

test to see if any keys are currently set.

=back

=head1 DEPRECATED

=over 4

=item $obj = $obj->add( $key [, $key2 ... ] )

=item $obj = $obj->del( $key [, $key2 ... ] )

=item $bool = $obj->exists( $key )

deprecated aliases to set, unset & is_set.

=back

=head1 SUB-CLASSING

At the very least, you must do the following:

  package Foo;
  use base qw( Pangloss::Search::Filter::Base );

  sub applies_to {
      my $self = shift;
      my $term = shift;

      # use $term, $self->item_keys and the collections
      # available via $self->parent to do your test

      return 0 || 1;
  }

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Search>

=head2 Known Sub-Classes

L<Pangloss::Search::Filter::Category>,
L<Pangloss::Search::Filter::Concept>,
L<Pangloss::Search::Filter::Language>,
L<Pangloss::Search::Filter::Proofreader>,
L<Pangloss::Search::Filter::Translator>,
L<Pangloss::Search::Filter::Status>,
L<Pangloss::Search::Filter::DateRange>

=cut

