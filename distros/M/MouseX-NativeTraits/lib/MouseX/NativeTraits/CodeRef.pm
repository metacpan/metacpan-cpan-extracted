package MouseX::NativeTraits::CodeRef;
use Mouse::Role;

with 'MouseX::NativeTraits';

sub method_provider_class {
    return 'MouseX::NativeTraits::MethodProvider::CodeRef';
}

sub helper_type {
    return 'CodeRef';
}

1;
__END__

=head1 NAME

MouseX::NativeTraits::CodeRef - Helper trait for CodeRef attributes

=head1 SYNOPSIS

  package Foo;
  use Mouse;

  has 'callback' => (
      traits    => ['Code'],
      is        => 'ro',
      isa       => 'CodeRef',
      default   => sub { sub { print "called" } },
      handles   => {
          call => 'execute',
      },
  );

  my $foo = Foo->new;
  $foo->call; # prints "called"


=head1 DESCRIPTION

This provides operations on coderef attributes.

=head1 PROVIDED METHODS

=over 4

=item B<execute(@args)>

Calls the coderef with the given args.

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
