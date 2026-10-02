package TUI::Validate::FilterValidator;
# ABSTRACT: character-set validator for input fields

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TFilterValidator
  new_TFilterValidator
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :types
);

use TUI::MsgBox::Const qw(
  mfError
  mfOKButton
);
use TUI::MsgBox::MsgBoxText qw( messageBox );
use TUI::Validate::Validator;

sub TFilterValidator() { __PACKAGE__ }
sub name() { 'TFilterValidator' };
sub new_TFilterValidator { __PACKAGE__->from(@_) }

extends TValidator;

# declare global variables
our $errorMsg = "Invalid character in input";

# protected attributes
has validChars => ( is => 'ro', default => '' );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      validChars => Str, { optional => 1, alias => 'aValidChars' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $obj ($aValidChars|undef)
  state $sig = signature(
    method => 1,
    pos    => [Maybe[Str]],
  );
  my ( $class, $aValidChars ) = $sig->( @_ );
  return $class->new( defined $aValidChars 
    ? ( validChars => $aValidChars ) 
    : ()
  );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{validChars} = undef;
  return;
}

sub error {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  messageBox( mfError | mfOKButton, $errorMsg );
  return;
}

sub isValidInput {    # $bool ($s, $suppressFill)
  state $sig = signature(
    method => Object,
    pos    => [Str, Bool],
  );
  my ( $self, $s, $suppressFill ) = $sig->( @_ );
  my $validChars = $self->{validChars};
  return $s !~ /[^$validChars]/;
}

sub isValid {    # $bool ($s)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $s ) = $sig->( @_ );
  my $validChars = $self->{validChars};
  return $s !~ /[^$validChars]/;
}

1

__END__

=pod

=head1 NAME

TUI::Validate::FilterValidator - character-set validator for input fields

=head1 HIERARCHY

  TObject
    TValidator
      TFilterValidator

=head1 SYNOPSIS

  use TUI::Validate::FilterValidator;

  # allow only decimal digits
  my $v = new_TFilterValidator( '[0-9]' );

  if ( $v->isValid($input) ) {
    # all characters in $input are within the allowed set
  }

  # named-parameter form
  my $v2 = TFilterValidator->new( validChars => '[A-Za-z]' );

=head1 DESCRIPTION

C<TFilterValidator> validates text by comparing each character against a
caller-supplied set of allowed characters.  The set is expressed as a
character-class pattern (without the surrounding C<[...]> brackets if given as
a raw list, or with them if given as a regex fragment).

The validator integrates with input widgets: C<isValidInput> is called
keystroke by keystroke while the user is editing, whereas C<isValid> performs
the final check when the field is committed.  If the check fails, C<error>
displays a message box so the user knows what went wrong.

=head2 Commonly Used Features

The most common use is to create a validator with a character-class string and
attach it to an input line.  For digit-only fields the pattern C<'[0-9]'> is
sufficient.  For alphanumeric fields use C<'[A-Za-z0-9]'>.  The C<validChars>
attribute is read-only after construction, so the allowed set cannot be changed
at runtime.

=head1 VARIABLES

=head2 $errorMsg

  our $errorMsg = "Invalid character in input";

Package-global message displayed by C<error()>.  Override it before
constructing any validator if a different message is needed.

=head1 ATTRIBUTES

=head2 validChars (ro)

  my $pattern = $v->validChars;

Read-only string (I<Str>) holding the character-class pattern used to decide
whether a character is acceptable.  Set once at construction time via the C<validChars>
(or aliased C<aValidChars>) constructor argument.

=head1 CONSTRUCTOR

=head2 new

  my $v = TFilterValidator->new( validChars => $pattern );

Constructs a new filter validator.  C<$pattern> is a string that describes the
accepted characters, e.g. C<'[0-9]'> for digits or C<'[A-Za-z]'> for letters.
The argument is mandatory; omitting it raises an exception.

=head2 new_TFilterValidator

  my $v = new_TFilterValidator( $pattern );

Convenience factory that accepts the character-class pattern as a single
positional argument and delegates to C<new>.  Exported by default.

=head1 METHODS

=head2 DEMOLISH

  # called automatically by the object system

Cleanup hook.  Clears the C<validChars> slot before the object is freed.
Invoked automatically; do not call directly.

=head2 error

  $v->error();

Displays a modal message box (error style with an OK button) using the text
stored in C<$errorMsg>.  Called internally by the input framework when
validation fails.

=head2 isValid

  my $ok = $v->isValid( $string );

Returns true if every character in C<$string> appears in the C<validChars>
pattern, false otherwise.  Intended for the final validation pass when the user
commits the field.

=head2 isValidInput

  my $ok = $v->isValidInput( $string, $suppressFill );

Returns true if every character in C<$string> is within the allowed set.
Called keystroke by keystroke during editing.  C<$suppressFill> is accepted for
interface compatibility but currently has no effect.

=head1 SEE ALSO

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
