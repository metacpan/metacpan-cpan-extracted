package Object::Enum;
$Object::Enum::VERSION = '0.075';
use strict;
use warnings;
use 5.006001;

use Carp ();
use Sub::Install ();

use base qw(
            Class::Data::Inheritable
            Class::Accessor::Fast
          );

__PACKAGE__->mk_classdata($_) for (
  '_values',
  '_unset',
  '_default',
  '_readonly',
);

__PACKAGE__->mk_accessors(
  'value',
);

__PACKAGE__->_unset(1);

use overload (
  q{""} => '_stringify',
  fallback => 1,
);

use Sub::Exporter -setup => {
  exports => [ Enum => \&_build_enum ],
};

sub _build_enum { 
  my ($class, undef, $arg) = @_;
  return sub { $class->new({ %$arg, %{shift || {} } }) };
}

=head1 NAME

Object::Enum - replacement for C<< if ($foo eq 'bar') >>

=head1 SYNOPSIS

  use Object::Enum qw(Enum);

  my $color = Enum([ qw(red yellow green) ]);
  # ... later
  if ($color->is_red) {
  # it can't be yellow or green

=head1 EXPORTS

See L<Sub::Exporter> for ways to customize this module's
exports.

=head2 Enum

An optional shortcut for C<< Object::Enum->new >>.

=head1 CLASS METHODS

=head2 new

  my $obj = Object::Enum->new(\@values);
  # or
  $obj = Object::Enum->new(\%arg);

Return a new Object::Enum, with one or more sets of possible
values.

The simplest case is to pass an arrayref, which returns an
object capable of having any one of the given values or of
being unset.

The more complex cases involve passing a hashref, which may
have the following keys:

=over

=item * unset

whether this object can be 'unset' (defaults to true)

=item * default

this object's default value is (defaults to undef)

=item * values

an arrayref, listing the object's possible values (at least
one required)

=item * readonly

boolean value to indicate if the object is read-only. If set
to read-only the objects C<value> and C<set_*> methods become ineffectual.

=back

=cut

my $id = 0;
sub _generate_class {
  my $class = shift;
  no strict 'refs';
  my $gen = sprintf "%s::obj_%08d", $class, ++$id;
  push @{$gen."::ISA"}, $class;
  return $gen;
}

sub _mk_values {
  my $class = shift;
  for my $value (keys %{ $class->_values }) {
    Sub::Install::install_sub({
      into => $class,
      as   => "set_$value",
      code => sub { $_[0]->value($value); return $_[0] },
    });
    Sub::Install::install_sub({
      into => $class,
      as   => "is_$value",
      code => sub { (shift->value || '') eq $value },
    }) unless $class->can("is_$value");
  }
}

sub new {
  my ($class, $arg) = @_;
  $arg ||= [];
  if (ref $arg eq 'ARRAY') {
    $arg = { values => $arg };
  }

  unless (@{$arg->{values} || []}) {
    Carp::croak("at least one possible value must be provided");
  }

  exists $arg->{unset}   or $arg->{unset} = 1;
  exists $arg->{default} or $arg->{default} = undef;
  exists $arg->{readonly} or $arg->{readonly} = 0;

  if (!$arg->{unset} && !defined $arg->{default}) {
    Carp::croak("must supply a defined default for 'unset' to be false");
  }

  if (defined($arg->{default}) && ! grep {
    $_ eq $arg->{default}
  } @{$arg->{values}}) {
    Carp::croak("default value must be listed in 'values' or undef");
  }

  my $gen = $class->_generate_class;
  $gen->_unset($arg->{unset});
  $gen->_default($arg->{default});
  $gen->_readonly($arg->{readonly});
  $gen->_values({ map { $_ => 1 } @{$arg->{values}} });
  $gen->_mk_values;

  # constructors shouldn't call cloners
  #return $gen->spawn;
  return $gen->_curried;
}

sub _stringify {
  my $self = shift;
  return '(undef)' unless defined $self->value;
  return $self->value;
}

=head1 OBJECT METHODS

=head2 spawn

=head2 clone

  my $new = $obj->clone;

  my $new = $obj->clone($value);

Create a new Enum from an existing object, using the same arguments as were
originally passed to C<< new >> when that object was created.

An optional value may be passed in; this is identical to (but more convenient
than) calling C<value> with the same argument on the newly cloned object.

This method was formerly named C<spawn>.  That name will still work but is
deprecated.

=cut

sub _curried {
  my $class = shift;
  my $self = bless {
    value => ref($class)? $class->value : $class->_default,
  } => ref($class) || $class;
  $self->value(@_) if @_;

  return $self;
}

sub clone {
  my $self = shift->_curried(@_);
  $self->_readonly(0)
    if $self->_readonly;

  return $self;
}

BEGIN { *spawn = \&clone }

=head2 readonly

 my $obj = $obj->readonly(\@values, $value)

Creates a read-only enum object, also known as immutable. When enum objects are created
with this C<< set_* >> methods, and the C<value> method will become ineffectual.

If you want a mutable version, simply clone the immutable version

 my $new_obj = $readonly_obj->clone;
 $new_obj->set_red;

=cut

sub readonly {
  my $class = shift;
  my $values = shift;
  my $value = shift;

  $values = []
    unless ref($values) eq 'ARRAY';

  return $class->new({
    values => $values,
    default => $value,
    readonly => 1
  });
}

=head2 value

The current value as a string (or undef)

Note: don't pass in undef; use the L<unset|/unset> method instead.

=cut

sub value {
  my $self = shift;
  if (@_ && !$self->_readonly) {
    my $val = shift;
    Carp::croak("object $self cannot be set to undef") unless defined $val;
    unless ($self->_values->{$val}) {
      Carp::croak("object $self cannot be set to '$val'");
    }
    return $self->_value_accessor($val);
  }
  return $self->_value_accessor;
}

=head2 values

The possible values for this object

=cut

sub values {
  my $self = shift;
  return keys %{ $self->_values };
}

=head2 unset

Unset the object's value (set to undef)

=cut

sub unset {
  my $self = shift;
  unless ($self->_unset) {
    Carp::croak("object $self cannot be unset");
  }
  $self->_value_accessor(undef);
}

=head2 is_*

=head2 set_*

Automatically generated from the values passed into C<< new
>>.

None of these methods take any arguments.

The C<< set_* >> methods are chainable; that is, they return
the object on which they were called.  This lets you do useful things like:

  use Object::Enum Enum => { -as => 'color', values => [qw(red blue)] };

  print color->set_red->value; # prints 'red'

=cut

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-object-enum at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Enum>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Object::Enum

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Object-Enum>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Object-Enum>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Object-Enum>

=item * Search CPAN

L<http://search.cpan.org/dist/Object-Enum>

=item * GitHub

L<https://github.com/jmmills/object-enum/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Object::Enum
