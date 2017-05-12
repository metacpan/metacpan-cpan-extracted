package MouseX::NativeTraits::Counter;
use Mouse::Role;

with 'MouseX::NativeTraits';

sub method_provider_class {
    return 'MouseX::NativeTraits::MethodProvider::Counter';
}

sub helper_type {
    return 'Int';
}

sub _default_default { 0 }

no Mouse::Role;
1;
__END__

=head1 NAME

MouseX::NativeTraits::Counter - Helper trait for counter attributes

=head1 SYNOPSIS

  package MyHomePage;
  use Mouse;

  has 'counter' => (
      traits    => ['Counter'],
      is        => 'ro',
      isa       => 'Num',
      default   => 0,
      handles   => {
          inc_counter   => 'inc',
          dec_counter   => 'dec',
          reset_counter => 'reset',
      },
  );

  my $page = MyHomePage->new();
  $page->inc_counter; # same as $page->counter( $page->counter + 1 );
  $page->dec_counter; # same as $page->counter( $page->counter - 1 );

=head1 DESCRIPTION

This module provides a simple counter attribute, which can be
incremented and decremented.

If your attribute definition does not include any of I<is>, I<isa>,
I<default> or I<handles> but does use the C<Counter> trait,
then this module applies defaults as in the L</SYNOPSIS>
above. This allows for a very basic counter definition:

  has 'foo' => (traits => ['Counter']);
  $obj->inc_foo;

=head1 PROVIDED METHODS

These methods are implemented in
L<MouseX::NativeTraits::MethodProvider::Counter>. It is important to
note that all those methods do in place modification of the value stored in
the attribute.

=over 4

=item B<set($value)>

Set the counter to the specified value.

=item B<inc>

Increments the value stored in this slot by 1. Providing an argument will
cause the counter to be increased by specified amount.

=item B<dec>

Decrements the value stored in this slot by 1. Providing an argument will
cause the counter to be increased by specified amount.

=item B<reset>

Resets the value stored in this slot to it's default value.

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
