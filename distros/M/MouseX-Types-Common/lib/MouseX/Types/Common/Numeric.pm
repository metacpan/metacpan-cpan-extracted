package MouseX::Types::Common::Numeric;

use strict;
use warnings;

our $VERSION = '0.001000';

use MouseX::Types -declare => [
  qw(PositiveNum PositiveInt NegativeNum NegativeInt SingleDigit)
];

use MouseX::Types::Mouse qw/Num Int/;

subtype PositiveNum,
  as Num,
  where { $_ >= 0 },
  message { "Must be a positive number" };

subtype PositiveInt,
  as Int,
  where { $_ >= 0 },
  message { "Must be a positive integer" };

subtype NegativeNum,
  as Num,
  where { $_ <= 0 },
  message { "Must be a negative number" };

subtype NegativeInt,
  as Int,
  where { $_ <= 0 },
  message { "Must be a negative integer" };

subtype SingleDigit,
  as PositiveInt,
  where { $_ <= 9 },
  message { "Must be a single digit" };


1;
__END__

=head1 NAME

MouseX::Types::Common::Numeric - A set of commonly-used numeric type constraints

=head1 SYNOPSIS

    use MouseX::Types::Common::Numeric qw/PositiveInt/;
    has count => (is => 'rw', isa => PositiveInt);

    ...
    #this will fail
    $object->count(-33);

=head1 DESCRIPTION

A set of commonly-used numeric type constraints that do not ship with Mouse by
default.

=over

=item * PositiveNum

=item * PositiveInt

=item * NegativeNum

=item * Int

=item * SingleDigit

=back

=head1 SEE ALSO

=over

=item * L<MouseX::Types::Common::String>

=back

=head1 AUTHORS

Please see:: L<MouseX::Types::Common>

=cut
