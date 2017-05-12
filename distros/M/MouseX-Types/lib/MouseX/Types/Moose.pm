package MouseX::Types::Moose;

use MouseX::Types;
use Mouse::Util::TypeConstraints ();

use constant type_storage => {
    map { $_ => $_ } Mouse::Util::TypeConstraints->list_all_builtin_type_constraints
};

1;
__END__

=head1 NAME

MouseX::Types::Moose - MouseX::Types::Mouse plus drop-in compatibility with Any::Moose

=head1 SYNOPSIS

  package Foo;
  use Any::Moose;
  use Any::Moose '::Types::Moose' => [qw( Int ArrayRef )];

  has name => (
    is  => 'rw',
    isa => Str;
  );

  has ids => (
    is  => 'rw',
    isa => ArrayRef[Int],
  );

  1;

=head1 SEE ALSO

L<MouseX::Types::Mouse>

=cut
