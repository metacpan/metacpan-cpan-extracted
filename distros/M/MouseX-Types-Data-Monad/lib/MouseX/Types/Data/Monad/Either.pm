package MouseX::Types::Data::Monad::Either;

use strict;
use warnings;

use Carp qw( croak );
use Mouse::Util::TypeConstraints;

subtype 'Either', # `Maybe` is already defined by Mouse
  as 'Data::Monad::Either',
  (
    constraint_generator => sub {
      my ($type_parameter) = @_;
      my $check = $type_parameter->_compiled_type_constraint;

      # type_constraints is a ArrayRef that sorted by name,
      # so the first element from valid type constraints must be Left type
      my ($left_t, $right_t) = @{ $type_parameter->{type_constraints} // [] };
      croak 'Either must have Left and Right type constraints'
        unless defined($left_t) && ($left_t =~ m/\ALeft\[?/) && defined($right_t) && ($right_t =~ m/\ARight\[?/);

      return sub {
        my ($either) = @_;
        return $either->is_right ? $right_t->check($either) : $left_t->check($either);
      };
    }
  );

subtype 'Left',
  as 'Data::Monad::Either::Left',
  (
    constraint_generator => sub {
      my ($type_parameter) = @_;
      my $check = $type_parameter->_compiled_type_constraint;

      return sub {
        my ($left) = @_;
        my ($result) = $check->($left->value); # Data::Monad::Either#value is context-aware method
        return $result;
      };
    }
  );

subtype 'Right',
  as 'Data::Monad::Either::Right',
  (
    constraint_generator => sub {
      my ($type_parameter) = @_;
      my $check = $type_parameter->_compiled_type_constraint;

      return sub {
        my ($right) = @_;
        my ($result) = $check->($right->value); # Data::Monad::Either#value is context-aware method
        return $result;
      };
    }
  );

1;

__END__

=encoding utf-8

=head1 NAME

MouseX::Types::Data::Monad::Either - Type constraints for Data::Monad::Either

=head1 SYNOPSIS

    use Data::Monad::Either qw( right left );
    use MouseX::Types::Data::Monad::Either;
    use Smart::Args qw( args );

    sub from_api {
      args my $json => 'Either[Left[Str] | Right[Int]]';
      $json->flat_map(sub {
        # ...
      });
    }

    from_api(right(1));
    from_api(left('some error'));

=head1 DESCRIPTION

MouseX::Types::Data::Monad::Either defines a type constraint for Data::Monad::Either.

C<Either> type requires a union type that consists of C<Left> and C<Right> types.

The reason for this strange requirement is that L<Mouse::Meta::TypeConstraint> cannot have multiple type parameters.

=head1 SEE ALSO

L<Mouse>, L<Data::Monad::Either>

=head1 LICENSE

Copyright (C) aereal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=cut

