package MouseX::Types::Data::Monad::Maybe;

use strict;
use warnings;

use Mouse::Util::TypeConstraints;

subtype 'MaybeM', # `Maybe` is already defined by Mouse
  as 'Data::Monad::Maybe',
  (
    constraint_generator => sub {
      my ($type_parameter) = @_;
      my $check = $type_parameter->_compiled_type_constraint;

      return sub {
        my ($maybe) = @_;
        return $maybe->is_nothing ? 1 : $check->($maybe->value);
      };
    }
  );

1;

__END__

=encoding utf-8

=head1 NAME

MouseX::Types::Data::Monad::Maybe - A type constraint for Data::Monad::Maybe

=head1 SYNOPSIS

  use Data::Monad::Maybe qw( just nothing );
  use MouseX::Types::Data::Monad::Maybe;
  use Smart::Args qw( args );

  sub from_api {
    args my $json => 'MaybeM[HashRef]';
    $json->flat_map(sub {
      # ...
    });
  }

  from_api(just +{ ok => 1 });
  from_api(nothing);

=head1 DESCRIPTION

MouseX::Types::Data::Monad::Maybe defines a type constraint for Data::Monad::Maybe.

=head1 SEE ALSO

L<Mouse>, L<Data::Monad::Maybe>

=head1 LICENSE

Copyright (C) aereal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=cut

