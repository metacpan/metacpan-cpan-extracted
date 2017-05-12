package MouseX::NativeTraits::Bool;
use Mouse::Role;

with 'MouseX::NativeTraits';

sub method_provider_class {
    return 'MouseX::NativeTraits::MethodProvider::Bool';
}

sub helper_type {
    return 'Bool';
}

1;
__END__

=head1 NAME

MouseX::NativeTraits::Bool - Helper trait for Bool attributes

=head1 SYNOPSIS

  package Room;
  use Mouse;

  has 'is_lit' => (
      traits    => ['Bool'],
      is        => 'rw',
      isa       => 'Bool',
      default   => 0,
      handles   => {
          illuminate  => 'set',
          darken      => 'unset',
          flip_switch => 'toggle',
          is_dark     => 'not',
      },
  );

  my $room = Room->new();
  $room->illuminate;     # same as $room->is_lit(1);
  $room->darken;         # same as $room->is_lit(0);
  $room->flip_switch;    # same as $room->is_lit(not $room->is_lit);
  return $room->is_dark; # same as !$room->is_lit

=head1 DESCRIPTION

This provides a simple boolean attribute, which supports most of the
basic math operations.

=head1 PROVIDED METHODS

These methods are implemented in
L<MouseX::NativeTraits::MethodProvider::Bool>. It is important to
note that all those methods do in place modification of the value stored in
the attribute.

=over 4

=item B<set>

Sets the value to true.

=item B<unset>

Set the value to false.

=item B<toggle>

Toggles the value. If it's true, set to false, and vice versa.

=item B<not>

Equivalent of 'not C<$value>'.

=back

=head1 METHODS

=over 4

=item B<meta>

=item B<method_provider_class>

=item B<helper_type>

=back

=head1 SEE ALSO

L<MouseX::NativeTraits>.

=cut
