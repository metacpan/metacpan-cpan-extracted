package TUI::Objects::Object;
# ABSTRACT: defines the class TObject

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TObject
  new_TObject
);

use Devel::StrictMode;
use Scalar::Util qw(
  weaken
  isweak
);
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

sub TObject() { __PACKAGE__ }
sub new_TObject { __PACKAGE__->from(@_) }

my $unlock_value = sub {
  Internals::SvREADONLY( $_[0] => 0 )
    if exists &Internals::SvREADONLY;
};

sub BUILDARGS {    # \%args ()
  state $sig = signature(
    method => 1,
    named  => [],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return $args ? { %$args } : {};
}

sub from {    # $obj ();
  state $sig = signature(
    method => 1,
    pos => [],
  );
  my ( $class ) = $sig->( @_ );
  return $class->new();
}

sub destroy {    # void ($class|$self, $o|undef)
  my ( $class, $o ) = @_;
  assert ( defined $class );
  assert ( !defined $o or is_Object $o );
  $class = ref $class || $class;
  alias: for $o ( $_[1] ) {
  if ( defined $o ) {
    assert ( is_Object $o );
    $o->shutDown();
    for ( keys %$o ) {
      if ( ref $o->{$_} && !isweak $o->{$_} ) {
        &$unlock_value( $o->{$_} ) if STRICT;
        weaken $o->{$_};
      }
    }
    undef $o;
  }
  return;
  } #/ alias
}

sub shutDown {    # void ($self)
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Objects::Object - root class for all TUI::Vision objects

=head1 HIERARCHY

  TObject
    TView
    TCollection
    TStream
    TStringList
    TStrListMaker
    TResourceFile

=head1 DESCRIPTION

C<TObject> is the root class of the TUI::Vision object hierarchy. Nearly all
objects used by the framework are derived from C<TObject>, and all objects that
can be written to streams must descend from it.

The class defines the basic initialization and destruction semantics shared by
all TUI::Vision objects. Descendant classes are expected to follow these rules
by invoking their parent constructors and destructors appropriately.

C<TObject> itself does not provide visible behavior and is not normally used
directly by application code.

=head1 CONSTRUCTOR

=head2 new

  my $obj = TObject->new();

Creates a new object and performs base initialization.

This constructor corresponds to the Turbo Vision constructor. All
derived classes must ensure that their base class constructor is invoked before
performing class-specific initialization.

=head2 new_TObject

  my $obj = new_TObject();

Factory-style constructor using positional arguments.

This constructor exists for compatibility with traditional Turbo Vision
construction patterns and is primarily used internally.

=head1 DESTRUCTOR

=head2 DEMOLISH

  $self->DEMOLISH($in_global_destruction);

Destroys the object and releases associated resources.

This method corresponds to the Turbo Vision destructor. Descendant
classes should perform their cleanup before delegating to the base
implementation.

=head1 METHODS

=head2 destroy

  TObject->destroy($object);

Destroys an object and releases its internal references.

This method provides an explicit destruction mechanism that is part of the
framework API. It performs controlled shutdown of the object and breaks
internal reference cycles.

The method may be called either as a class method or as an instance method.

=head2 shutDown

  $obj->shutDown();

Performs shutdown processing for the object. Derived classes may override this
method to release internal resources prior to destruction.

=head1 SEE ALSO

L<TUI::Views::View>,
L<TUI::Objects::Collection>,
L<TUI::Objects::Stream>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
