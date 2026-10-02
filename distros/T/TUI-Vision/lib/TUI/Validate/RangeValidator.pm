package TUI::Validate::RangeValidator;
# ABSTRACT: integer range validator for numeric input

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TRangeValidator
  new_TRangeValidator
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::MsgBox::Const qw(
  mfError
  mfOKButton
);
use TUI::MsgBox::MsgBoxText qw( messageBox );
use TUI::Validate::Const qw(
  voTransfer
  vtGetData
  vtSetData
);
use TUI::Validate::FilterValidator;

sub TRangeValidator() { __PACKAGE__ }
sub name() { 'TRangeValidator' };
sub new_TRangeValidator { __PACKAGE__->from(@_) }

extends TFilterValidator;

# declare global variables
our $errorMsg           = "Value not in the range %d to %d";
our $validUnsignedChars = "+0123456789";
our $validSignedChars   = "+-0123456789";

# protected attributes
has min => ( is => 'ro', default => sub { die 'required' } );
has max => ( is => 'ro', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      min => Int, { alias => 'aMin' },
      max => Int, { alias => 'aMax' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( $self->{min} <= $self->{max} );
  $self->{validChars} = $self->{min} >= 0
                      ? $validUnsignedChars 
                      : $validSignedChars;
  return;
}

sub from {    # $obj ($aMin, $aMax)
  state $sig = signature(
    method => 1,
    pos    => [Int, Int],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( min => $args[0], max => $args[1] );
}

sub error {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  messageBox( mfError | mfOKButton, $errorMsg, $self->{min}, $self->{max} );
  return;
}

sub isValid {    # $bool ($s)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $s ) = $sig->( @_ );
  if ( $self->SUPER::isValid( $s ) ) {
    if ( $s =~ /\A([+-]?\d+)\z/ ) {
      my $value = int( $1 );
      return $value >= $self->{min} && $value <= $self->{max};
    }
  }
  return false;
}

sub transfer {    # $n ($s, $buffer, $flags)
  state $sig = signature(
    method => Object,
    pos    => [Str, Any, PositiveOrZeroInt],
  );
  my ( $self, $s, $buffer, $flags ) = $sig->( @_ );

  if ( $self->{options} & voTransfer ) {
    if ( $flags == vtGetData ) {
      if ( $s =~ /\A([+-]?\d+)\z/ ) {
        $_[2] = int( $1 );
        return 1;
      }
    }
    elsif ( $flags == vtSetData ) {
      if ( defined $buffer ) {
        $_[1] = sprintf( "%d", $buffer );
        return 1;
      }
    }
  } 
  return 0;
}

1

__END__

=pod

=head1 NAME

TUI::Validate::RangeValidator - integer range validator for numeric input

=head1 HIERARCHY

  TObject
    TValidator
      TFilterValidator
        TRangeValidator

=head1 SYNOPSIS

  use TUI::Validate::RangeValidator;

  my $vUnsigned = new_TRangeValidator( 1, 100 );

  if ( $vUnsigned->isValid($input) ) {
    # integer string is in range
  }

  my $vSigned = TRangeValidator->new( min => -10, max => 10 );

=head1 DESCRIPTION

C<TRangeValidator> validates integer text input against an inclusive minimum
and maximum bound.  It inherits character filtering behavior from
L<TFilterValidator|TUI::Validate::FilterValidator> and then applies a numeric 
range check in L</isValid>.

At construction time, the module configures the accepted character set from
the selected range: non-negative ranges allow C<+0123456789>, while ranges
that include negative numbers allow C<+-0123456789>.

=head2 Commonly Used Features

Typical usage is to create a validator with L</min> and L</max>, assign it to 
an input field, and let the framework call
L<isValidInput|TUI::Validate::FilterValidator/isValidInput> while typing and
L</isValid> on commit.  If the committed value is outside the configured range,
L</error> shows a formatted message with both limits.

=head1 VARIABLES

=head2 $errorMsg

  our $errorMsg = "Value not in the range %d to %d";

Package-global error template used by C<error()>.  The placeholders receive the
current C<min> and C<max> values.

=head2 $validUnsignedChars

  our $validUnsignedChars = "+0123456789";

Character set applied when C<min> is non-negative.

=head2 $validSignedChars

  our $validSignedChars = "+-0123456789";

Character set applied when C<min> is negative.

=head1 ATTRIBUTES

=head2 min

Inclusive lower bound for accepted integer values (I<Int>, read-only).

=head2 max

Inclusive upper bound for accepted integer values (I<Int>, read-only).

=head1 CONSTRUCTOR

=head2 new

  my $v = TRangeValidator->new( min => $min, max => $max );

Creates a range validator with mandatory bounds.  C<min> must be less than or
equal to C<max>; otherwise construction fails an assertion in C<BUILD>.

=head2 new_TRangeValidator

  my $v = new_TRangeValidator( $aMin, $aMax );

Convenience factory with positional arguments.  Exported by default.

=head1 METHODS

=head2 error

  $v->error();

Displays a modal error message using C<$errorMsg>, formatted with the current
minimum and maximum bounds.

=head2 isValid

  my $ok = $v->isValid( $s );

Returns true only when all of the following are true:

=over

=item *

the input passes the inherited character filter,

=item *

the input matches an integer literal C<[+-]?\d+>,

=item *

the parsed integer is between C<min> and C<max> (inclusive).

=back

Otherwise it returns false.

=head2 transfer

  my $ok = $v->transfer( $s, $buffer, $flag );

Transfers numeric data between the field string and an external buffer when
the validator option C<voTransfer> is enabled.

For C<vtGetData>, it parses C<$s> as an integer and writes the number to the
buffer slot.  For C<vtSetData>, it formats the provided buffer value back into
the field string.

Returns C<1> on successful transfer and C<0> otherwise.

=head1 SEE ALSO

L<TFilterValidator|TUI::Validate::FilterValidator>,
L<TValidator|TUI::Validate::Validator>,
L<TUI::Validate::Const>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
