package MouseX::NativeTraits::Num;
use Mouse::Role;

with 'MouseX::NativeTraits';

sub method_provider_class {
    return 'MouseX::NativeTraits::MethodProvider::Num';
}

sub helper_type {
    return 'Num';
}

no Mouse::Role;
1;
__END__

=pod

=head1 NAME

MouseX::NativeTraits::Num - Helper trait for Num attributes

=head1 SYNOPSIS

  package Real;
  use Mouse;

  has 'integer' => (
      traits    => ['Number'],
      is        => 'ro',
      isa       => 'Num',
      default   => 5,
      handles   => {
          set => 'set',
          add => 'add',
          sub => 'sub',
          mul => 'mul',
          div => 'div',
          mod => 'mod',
          abs => 'abs',
      },
  );

  my $real = Real->new();
  $real->add(5); # same as $real->integer($real->integer + 5);
  $real->sub(2); # same as $real->integer($real->integer - 2);

=head1 DESCRIPTION

This provides a simple numeric attribute, which supports most of the
basic math operations.

=head1 PROVIDED METHODS

It is important to note that all those methods do in place modification of the
value stored in the attribute. These methods are implemented within this
package.

=over 4

=item B<add($value)>

Adds the current value of the attribute to C<$value>.

=item B<sub($value)>

Subtracts C<$value> from the current value of the attribute.

=item B<mul($value)>

Multiplies the current value of the attribute by C<$value>.

=item B<div($value)>

Divides the current value of the attribute by C<$value>.

=item B<mod($value)>

Returns the current value of the attribute modulo C<$value>.

=item B<abs>

Sets the current value of the attribute to its absolute value.

=back

=head1 METHODS

=over 4

=item B<meta>

=item B<method_provider_class>

=item B<helper_type>

=back

=head1 SEE ALSO

L<MouseX::NativeTraits>

=cut
