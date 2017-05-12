package MouseX::NativeTraits::Str;
use Mouse::Role;

with 'MouseX::NativeTraits';

sub method_provider_class {
    return 'MouseX::NativeTraits::MethodProvider::Str';
}

sub helper_type {
    return 'Str';
}

sub _default_default{ '' }

no Mouse::Role;
1;
__END__

=head1 NAME

MouseX::NativeTraits::Str - Helper trait for Str attributes

=head1 SYNOPSIS

  package MyHomePage;
  use Mouse;

  has 'text' => (
      traits    => ['String'],
      is        => 'rw',
      isa       => 'Str',
      default   => q{},
      handles   => {
          add_text     => 'append',
          replace_text => 'replace',
      },
  );

  my $page = MyHomePage->new();
  $page->add_text("foo"); # same as $page->text($page->text . "foo");

=head1 DESCRIPTION

This module provides a simple string attribute, to which mutating string
operations can be applied more easily (no need to make an lvalue attribute
metaclass or use temporary variables). Additional methods are provided for
completion.

=head1 PROVIDED METHODS

These methods are implemented in
L<MouseX::NativeTraits::MethodProvider::Str>. It is important to
note that all those methods do in place modification of the value stored in
the attribute.

=over 4

=item B<inc>

Increments the value stored in this slot using the magical string autoincrement
operator. Note that Perl doesn't provide analogous behavior in C<-->, so
C<dec> is not available.

=item B<append($string)>

Append a string, like C<.=>.

=item B<prepend($string)>

Prepend a string.

=item B<replace($pattern, $replacement)>

Performs a regexp substitution (L<perlop/s>).
A code references will be accepted for the replacement, causing
the regexp to be modified with a single C<e>. C</smxi> can be applied using the
C<qr> operator.

=item B<replace($pattern, $replacement)>

Performs a regexp substitution (L<perlop/s>) with the C<g> flag.
A code references will be accepted for the replacement, causing
the regexp to be modified with a single C<e>. C</smxi> can be applied using the
C<qr> operator.

=item B<match($pattern)>

Like C<replace> but without the replacement. Provided mostly for completeness.

=item B<chop>

L<perlfunc/chop>

=item B<chomp>

L<perlfunc/chomp>

=item B<clear>

Sets the string to the empty string (not the value passed to C<default>).

=item B<length>

L<perlfunc/length>

=item B<substr>

L<perlfunc/substr>. We go to some lengths to match the different functionality
based on C<substr>'s arity.

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
