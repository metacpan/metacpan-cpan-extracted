package Number::Object;

use strict;
use warnings;
our $VERSION = '0.03';

use Class::Component;
use Carp ();
use Scalar::Util ();
use Storable ();

use Number::Object::Filter;

use overload (
    q{""}    => \&to_s,
    q{0+}    => \&to_n,
    q{++}    => sub { Carp::croak '"++"(mutators) is unsupported operation' },
    q{--}    => sub { Carp::croak '"--"(mutators) is unsupported operation' },
    fallback => 1,
);

sub new {
    my $class = shift;
    my $value = shift;
    my $self  = $class->NEXT( new => @_ );

    $self->value($value);

    $self;
}

sub clone {
    my($self, $value) = @_;
    my $clone = Storable::dclone($self);
    $clone->value($value) if defined $value;
    $clone;
}

sub value {
    my($self, $value) = @_;
    return $self->{value} unless defined $value;
    $self->run_hook( 'value.set' => { value => $value } );
    $self->{value} = $value;
}

sub filtered {
    my $self = shift;
    my $value = $self->value;
    Number::Object::Filter->execute($self, $value, @_);
}

sub to_s { shift->value }
*to_n = *to_s;

1;
__END__

=head1 NAME

Number::Object - pluggable number object

=head1 SYNOPSIS

  use Number::Object;
  my $num = Number::Object->new(1000);
  print $num->filtered('comma');# 1,000

  $num->value(20000);
  print $num;# 20000

  $num->value(100);
  my $clone1 = $num->clone;
  my $clone2 = $num->clone(300);
  print "$num, $clone1, $clone2";# 100, 100, 300

using component and plugin

  use Number::Object;
  Number::Object->load_components(qw/ Autocall::Autoload /);
  Number::Object->load_plugins(qw/ Tax::JP /);

  my $num = Number::Object->new(10000);

  print $num->tax;# 500
  print $num->include_tax;# 10500
  print $num->include_tax->filtered('comma');# 10,500

using component and plugin # simple

  use Number::Object components => [qw/ Simple /], plugins => [qw/ Tax::JP /];
  my $num = Number::Object->new(10000);

  print $num->tax;# 500
  print $num->include_tax;# 10500
  print $num->include_tax->filtered('comma');# 10,500

in your module

  package MyClass;
  use base 'Number::Object';
  __PACKAGE__->load_components(qw/ Autocall::InjectMethod DisableDynamicPlugin /);
  __PACKAGE__->load_plugins(qw/ Tax /);

  package main;
  MyClass->load_plugins(qw/ ArithmeticOperation /);
  my $num = MyClass->new(10000);

  print $num->tax->mul(2);# 1000



=head1 DESCRIPTION

Number::Object is pluggable number object.

the method that want to be added to number can be added to pluggable.
original number object can be made by succeeding to Number::Object.

please refer to L<Class::Component> for the method of making plugin and component.

=head1 FILTER

filter used by the filtered method can be added.
please refer to mounting Number::Object::Filter::Comma .

=head1 OVERLOAD

when the arithmetic operation and comparing it, it is converted into an automatically usual numerical value.

  my $num = Number::Object->new(100);
  print (ref($num) || $num);# Number::Object

  my $cast = $num + 10;
  print (ref($cast) || $cast);# 110

but, the object is returned by the clone method as for same methods of the plugin.

  my $price = Number::Object->new(100, {
    load_plugins => [qw/ Tax /],
    config => {
        Tax => { rate => 1.5 }
    }
  });
  print (ref($price) || $price);# Number::Object

  my $tax = $price->include_tax;
  print (ref($tax) || $tax);# Number::Object
  print $tax;# 150

with ++ and -- the operator cannot be used.

  my $counter = Number::Object->new(0);
  $counter++;# Died
  $counter--;# Died
  ++$counter;# Died
  --$counter;# Died

former object disappears when operator such as += is used.

  my $assign = Number::Object->new(100);
  $assign += 100;
  print (ref($assign) || $assign);# 200


=head1 METHODS

=over 4

=item new

=item clone

=item value

=item filtered

=back

=head1 HOOKS

=over 4

=item value.set

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<Class::Component>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
