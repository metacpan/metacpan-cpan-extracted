package TUI::Validate::PXPictureValidator;
# ABSTRACT: Validator for picture-based input validation with auto-fill support

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TPXPictureValidator
  new_TPXPictureValidator
);

use Scalar::Util qw( readonly );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::MsgBox::Const qw(
  mfError
  mfOKButton
);
use TUI::MsgBox::MsgBoxText qw( messageBox );
use TUI::Validate::Const qw(
  :TPicResult
  vsSyntax
  voFill
);
use TUI::Validate::Validator;

sub TPXPictureValidator() { __PACKAGE__ }
sub name() { 'TPXPictureValidator' };
sub new_TPXPictureValidator { __PACKAGE__->from(@_) }

extends TValidator;

# declare global variables
our $errorMsg = "Error in picture format.\n %s";

# private attributes
has index => ( is => 'bare' );
has jndex => ( is => 'bare' );

# protected attributes
has pic => ( is => 'ro', default => sub { die 'required '} );

# private methods
my (
  $consume,
  $toGroupEnd,
  $skipToComma,
  $calcTerm,
  $iteration,
  $group,
  $checkComplete,
  $scan,
  $process,
  $syntaxCheck,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      pic      => Str, { alias => 'aPic' },
      autoFill => Bool,
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
  assert ( is_HashRef $args );
  $self->{options} |= voFill
    if ( $args->{autoFill} );
  my $s = '';
  $self->{status} = vsSyntax
    if $self->picture( $s, false ) != prEmpty;
  return;
}

sub from {    # $obj ($aPic, $autoFill)
  state $sig = signature(
    method => 1,
    pos    => [Str, Bool],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( pic => $args[0], autoFill => $args[1] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{pic} = undef;
  return;
}

sub error {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  messageBox( mfError | mfOKButton, $errorMsg, $self->{pic} );
  return;
}

sub isValidInput {    # $bool ($s, $suppressFill)
  state $sig = signature(
    method => Object,
    pos    => [Str, Bool],
  );
  my ( $self, $s, $suppressFill ) = $sig->( @_ );
  alias: for $s ( $_[1] ) {
  my $doFill = ( $self->{options} & voFill ) && !$suppressFill;
  return $self->{pic} eq '' || $self->picture( $s, $doFill ) != prError;
  } #/ alias:
}

sub isValid {    # $bool ($s)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $s ) = $sig->( @_ );
  return $self->{pic} eq '' || $self->picture( $s, false ) == prComplete;
}

my $toUpper      = sub { length( uc( $_[0] ) ) == 1 ? uc( $_[0] ) : $_[0] };
my $isNumber     = sub { $_[0] =~ /^\d$/ };
my $isLetter     = sub { $_[0] =~ /^[[:alpha:]]$/ };
my $isSpecial    = sub { length $_[0] == 1 && index( $_[1], $_[0] ) != -1 };
my $numChar      = sub { return () = ( $_[1] =~ /\Q$_[0]\E/g ) };
my $isComplete   = sub { $_[0] == prComplete   || $_[0] == prAmbiguous };
my $isIncomplete = sub { $_[0] == prIncomplete || $_[0] == prIncompNoFill };

sub picture {    # $picResult ($input, $autoFill)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Str], Bool],
  );
  my ( $self, $input, $autoFill ) = $sig->( @_ );
  alias: for $input ( $_[1] ) {

  my $reprocess;
  my $rslt;

  if ( !$self->$syntaxCheck() ) {
    return prSyntax;
  }

  if ( !defined( $input ) || !length( $input ) ) {
    return prEmpty;
  }

  $self->{jndex} = 0;
  $self->{index} = 0;

  $rslt = $self->$process( $input, length( $self->{pic} ) );

  if ( $rslt != prError && $self->{jndex} < length( $input ) ) {
    $rslt = prError;
  }

  if ( ( $rslt == prIncomplete ) && $autoFill ) {
    $reprocess = false;

    while ( ( $self->{index} < length( $self->{pic} ) )
      && !&$isSpecial( substr($self->{pic}, $self->{index}, 1), "#?&!@*{}[]," )
    ) {
      my $pchar = substr( $self->{pic}, $self->{index}, 1 );
      if ( $pchar eq ';' ) {
        $self->{index}++;
        last if $self->{index} >= length( $self->{pic} );
        $pchar = substr( $self->{pic}, $self->{index}, 1 );
      }

      $input .= $pchar;
      $self->{index}++;
      $reprocess = true;
    }

    $self->{jndex} = 0;
    $self->{index} = 0;
    if ( $reprocess ) {
      $rslt = $self->$process( $input, length( $self->{pic} ) );
    }
  } #/ if ( ( $rslt == prIncomplete...))

  if ( $rslt == prAmbiguous ) {
    return prComplete;
  }
  elsif ( $rslt == prIncompNoFill ) {
    return prIncomplete;
  }
  else {
    return $rslt;
  }
  } #/ alias:
}; #/ $picture = sub

# Consume input
$consume = sub {    # void ($ch, $input)
  my ( $self, $ch, $input ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_Str $ch );
  assert ( is_Str $input );
  alias: for $input ( $_[2] ) {
  assert ( !readonly $input );

  substr( $input, $self->{jndex}, 1 ) = $ch;
  $self->{index}++;
  $self->{jndex}++;
  return;

  } #/ alias:
};

# Skip a character or a picture group
$toGroupEnd = sub {    # void (\$i, $termCh)
  my ( $self, $i, $termCh ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_ScalarRef $i );
  assert ( is_Int $termCh );

  my $brkLevel = 0;
  my $brcLevel = 0;
  do {
    return if $$i == $termCh;
    SWITCH: for ( substr( $self->{pic}, $$i, 1 ) ) {
      $_ eq '[' and do { $brkLevel++; last };
      $_ eq ']' and do { $brkLevel--; last };
      $_ eq '{' and do { $brcLevel++; last };
      $_ eq '}' and do { $brcLevel--; last };
      $_ eq ';' and do { $$i++;       last };
    }
    $$i++;
  } while ( !( $brkLevel == 0 && $brcLevel == 0 ) );
  return;
}; #/ $toGroupEnd = sub

# Find a comma separator
$skipToComma = sub {    # $bool ($termCh)
  my ( $self, $termCh ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Int $termCh );
  do {
    $self->$toGroupEnd( \$self->{index}, $termCh );
  } while ( !( $self->{index} == $termCh 
          || substr( $self->{pic}, $self->{index}, 1 ) eq ',' ) );

  $self->{index}++
    if substr( $self->{pic}, $self->{index}, 1 ) eq ',';
  return $self->{index} < $termCh;
};

# Calculate the end of a group 
$calcTerm = sub {    # $int ($termCh)
  my ( $self, $termCh ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Int $termCh );
  my $k = $self->{index};
  $self->$toGroupEnd( \$k, $termCh );
  return $k;
};

# The next group is repeated X times
$iteration = sub {    # $picResult ($input, $inTerm)
  my ( $self, $input, $inTerm ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_Str $input );
  assert ( is_Int $inTerm );
  for $input ( $_[1] ) {
  assert ( !readonly $input );

  my $itr  = 0;
  my $rslt = prError;
  my $termCh;

  $self->{index}++;    # Skip '*'

  # Retrieve number
  while ( &$isNumber( substr( $self->{pic}, $self->{index}, 1 ) ) ) {
    my $digit = substr( $self->{pic}, $self->{index}, 1 );
    $itr = $itr * 10 + ( ord( $digit ) - ord( '0' ) );
    $self->{index}++;
  }

  my $k = $self->{index};
  $termCh = $self->$calcTerm( $inTerm );

  # If $itr is 0 allow any number, otherwise enforce the number
  if ( $itr != 0 ) {
    for ( my $l = 1 ; $l <= $itr ; $l++ ) {
      $self->{index} = $k;
      $rslt = $self->$process( $input, $termCh );

      if ( !&$isComplete( $rslt ) ) {

        # Empty means incomplete since all are required
        if ( $rslt == prEmpty ) {
          $rslt = prIncomplete;
        }
        return $rslt;
      }
    }
  }
  else {
    do {
      $self->{index} = $k;
      $rslt = $self->$process( $input, $termCh );
    } while ( $rslt == prComplete );

    if ( $rslt == prEmpty || $rslt == prError ) {
      $self->{index}++;
      $rslt = prAmbiguous;
    }
  }

  $self->{index} = $termCh;
  return $rslt;
  } #/ alias:
}; #/ $iteration = sub

# Process a picture group
$group = sub {    # $picResult ($input, $inTerm)
  my ( $self, $input, $inTerm ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_Str $input );
  assert ( is_Int $inTerm );
  alias: for $input ( $_[1] ) {
  assert ( !readonly $input );

  my $rslt;
  my $termCh;

  $termCh = $self->$calcTerm( $inTerm );
  $self->{index}++;
  $rslt = $self->$process( $input, $termCh - 1 );

  if ( !&$isIncomplete( $rslt ) ) {
    $self->{index} = $termCh;
  }

  return $rslt;
  } #/ alias:
};

$checkComplete = sub {    # $picResult ($rslt, $termCh)
  my ( $self, $rslt, $termCh ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $rslt );
  assert ( is_Int $termCh );

  my $j      = $self->{index};
  my $status = true;

  if ( &$isIncomplete( $rslt ) ) {

    # Skip optional pieces
    while ( $status ) {
      my $ch = substr( $self->{pic}, $j, 1 );

      if ( $ch eq '[' ) {
        $self->$toGroupEnd( \$j, $termCh );
      }
      elsif ( $ch eq '*' ) {
        if ( !&$isNumber( substr( $self->{pic}, $j + 1, 1 ) ) ) {
          $j++;
        }
        $self->$toGroupEnd( \$j, $termCh );
      }
      else {
        $status = false;
      }
    }

    if ( $j == $termCh ) {
      $rslt = prAmbiguous;
    }
  } #/ if ( $self->isIncomplete...)

  return $rslt;
}; #/ $checkComplete = sub

$scan = sub {    # $picResult ($input, $termCh)
  my ( $self, $input, $termCh ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_Str $input );
  assert ( is_Int $termCh );
  alias: for $input ( $_[1] ) {
  assert ( !readonly $input );

  my $ch;
  my ( $rslt, $rScan );

  $rScan = prError;
  $rslt  = prEmpty;

  while ( ( $self->{index} != $termCh )
    && ( substr( $self->{pic}, $self->{index}, 1 ) ne ',' ) )
  {
    if ( $self->{jndex} >= length( $input ) ) {
      return $self->$checkComplete( $rslt, $termCh );
    }

    $ch = substr( $input, $self->{jndex}, 1 );

    SWITCH: for ( substr( $self->{pic}, $self->{index}, 1 ) ) {

      $_ eq '#' and do {
        if ( !&$isNumber( $ch ) ) {
          return prError();
        }
        else {
          $self->$consume( $ch, $input );
        }
        last;
      };

      $_ eq '?' and do {
        if ( !&$isLetter( $ch ) ) {
          return prError;
        }
        else {
          $self->$consume( $ch, $input );
        }
        last;
      };

      $_ eq '&' and do {
        if ( !&$isLetter( $ch ) ) {
          return prError();
        }
        else {
          $self->$consume( &$toUpper( $ch ), $input );
        }
        last;
      };

      $_ eq '!' and do {
        $self->$consume( &$toUpper( $ch ), $input );
        last;
      };

      $_ eq '@' and do {
        $self->$consume( $ch, $input );
        last;
      };

      $_ eq '*' and do {
        $rslt = $self->$iteration( $input, $termCh );
        if ( !&$isComplete( $rslt ) ) {
          return $rslt;
        }

        if ( $rslt == prError ) {
          $rslt = prAmbiguous;
        }
        last;
      };

      $_ eq '{' and do {
        $rslt = $self->$group( $input, $termCh );
        if ( !&$isComplete( $rslt ) ) {
          return $rslt;
        }
        last;
      };

      $_ eq '[' and do {
        $rslt = $self->$group( $input, $termCh );
        if ( &$isIncomplete( $rslt ) ) {
          return $rslt;
        }
        if ( $rslt == prError ) {
          $rslt = prAmbiguous;
        }
        last;
      };

      DEFAULT: {
        my $p = substr( $self->{pic}, $self->{index}, 1 );

        if ( $p eq ';' ) {
          $self->{index}++;
          $p = substr( $self->{pic}, $self->{index}, 1 );
        }

        if ( &$toUpper( $p ) ne &$toUpper( $ch ) ) {
          if ( $ch ne ' ' ) {
            return $rScan;
          }
        }

        $self->$consume( $p, $input );
      }
    } #/ SWITCH: for ( substr( $self->{pic...}))

    if ( $rslt == prAmbiguous ) {
      $rslt = prIncompNoFill;
    }
    else {
      $rslt = prIncomplete;
    }
  } #/ while ( ( $self->{index} ...))

  if ( $rslt == prIncompNoFill ) {
    return prAmbiguous;
  }
  else {
    return prComplete;
  }
  } #/ alias:
}; #/ $scan = sub

$process = sub {    # $picResult ($input, $termCh)
  my ( $self, $input, $termCh ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_Str $input );
  assert ( is_Int $termCh );
  alias: for $input ( $_[1] ) {
  assert ( !readonly $input );

  my ( $rslt, $rProcess );
  my $incomp;
  my ( $oldI, $oldJ, $incompJ, $incompI );

  $incomp  = false;
  $oldI    = $self->{index};
  $oldJ    = $self->{jndex};
  $incompJ = 0;

  do {
    $rslt = $self->$scan( $input, $termCh );

    # Only accept completes if they make it farther in the input stream
    # from the last incomplete
    if ( $rslt == prComplete && $incomp && $self->{jndex} < $incompJ ) {
      $rslt = prIncomplete;
      $self->{jndex} = $incompJ;
    }

    if ( $rslt == prError || $rslt == prIncomplete ) {
      $rProcess = $rslt;

      if ( !$incomp && $rslt == prIncomplete ) {
        $incomp  = true;
        $incompI = $self->{index};
        $incompJ = $self->{jndex};
      }

      $self->{index} = $oldI;
      $self->{jndex} = $oldJ;

      if ( !$self->$skipToComma( $termCh ) ) {
        if ( $incomp ) {
          $rProcess      = prIncomplete;
          $self->{index} = $incompI;
          $self->{jndex} = $incompJ;
        }
        return $rProcess;
      }

      $oldI = $self->{index};
    } #/ if ( ( $rslt == prError...))

  } while ( $rslt == prError || $rslt == prIncomplete );

  if ( $rslt == prComplete && $incomp ) {
    return prAmbiguous;
  }
  else {
    return $rslt;
  }
  } #/ alias:
}; #/ $process = sub

$syntaxCheck = sub {    # $bool ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );

  if ( !defined $self->{pic} || length( $self->{pic} ) == 0 ) {
    return false;
  }

  if ( substr( $self->{pic}, -1, 1 ) eq ';' ) {
    return false;
  }

  my $i        = 0;
  my $brkLevel = 0;
  my $brcLevel = 0;

  my $len = length( $self->{pic} );
  while ( $i < $len ) {
    SWITCH: for ( substr( $self->{pic}, $i, 1 ) ) {
      $_ eq '[' and do { $brkLevel++; last };
      $_ eq ']' and do { $brkLevel--; last };
      $_ eq '{' and do { $brcLevel++; last };
      $_ eq '}' and do { $brcLevel--; last };
      $_ eq ';' and do { $i++;        last };
    }
    $i++;
  }

  return $brkLevel == 0 && $brcLevel == 0;
}; #/ $syntaxCheck = sub

1

__END__

=pod

=head1 NAME

TUI::Validate::PXPictureValidator - Picture-based validator for structured input

=head1 HIERARCHY

  TObject
    TValidator
      TPXPictureValidator

=head1 SYNOPSIS

  use TUI::Validate::PXPictureValidator;

  my $validator = new_TPXPictureValidator( '##-??', true );

  my $value = '12ab';
  my $ok_partial = $validator->isValidInput( $value, false );
  my $ok_final   = $validator->isValid($value);

  $validator->error() if !$ok_final;

=head1 DESCRIPTION

C<TPXPictureValidator> checks text against a picture pattern.

The picture string defines allowed character classes and grouping rules.
During validation, the parser returns status codes from 
L<TPicResult|TUI::Validate::Const> to describe whether the current input is 
complete, incomplete, syntactically invalid, or incompatible with the pattern.

If auto-fill is enabled, literal characters from the picture can be inserted
while parsing incremental input.

=head2 Commonly Used Features

Typical usage combines L</isValidInput> for live, per-keystroke checks and
L</isValid> for final acceptance checks.

When C<autoFill> is enabled, picture literals are inserted during parsing so
input can be normalized to the target format while the user types.

For integration points that need direct parser state, L</picture> returns the
underlying L<TPicResult|TUI::Validate::Const> status codes.

=head1 VARIABLES

=head2 $errorMsg

Message template used by C<error>.

=head1 ATTRIBUTES

=head2 pic

Read-only picture string (I<Str>) used as the validation mask.

=head1 CONSTRUCTOR

=head2 new

  my $obj = TPXPictureValidator->new(
    pic      => $picture,
    autoFill => $bool,
  );

Creates a validator instance.

=over

=item * C<pic> (required): picture mask (I<Str>).

=item * C<autoFill> (required): enables fill behavior via C<voFill>.

=back

=head2 new_TPXPictureValidator

  my $obj = new_TPXPictureValidator( $picture, $autoFill );

Positional factory equivalent to C<< ->new(pic => ..., autoFill => ...) >>.

=head1 METHODS

=head2 error

Displays an error message box for invalid picture definitions.

=head2 isValid

  my $ok = $obj->isValid($s);

Returns true only if C<$s> is a complete match for the picture.

=head2 isValidInput

  my $ok = $obj->isValidInput( $s, $suppressFill );

Checks whether C<$s> is acceptable as in-progress input. Depending on
fill settings, C<$s> may be normalized in place.

=head2 picture

  my $result = $obj->picture( $input, $autoFill );

Evaluates C<$input> and returns a L<TPicResult|TUI::Validate::Const> status.

The parser recognizes the following control tokens in C<pic>:

=over

=item * C<#> digit

=item * C<?> letter

=item * C<&> letter, force uppercase

=item * C<!> any character, force uppercase

=item * C<@> any character

=item * C<;> escape next character as literal

=item * C<*> repetition of next token or group

=item * C<[]> optional group

=item * C<{}> group

=item * C<,> alternatives inside a group

=back

=head1 PRACTICAL VALIDATION EXAMPLES

=over

=item * US Phone Number: C<(###)###-####>

Enforces exactly 10 digits wrapped in standard telephone punctuation.

=item * US Zip Code: C<#####[-####]>

Requires 5 digits, but allows an optional hyphen and 4-digit extension.

=item * State Abbreviation: C<&&>

Requires exactly two letters and forces them into capital letters.

=item * Boolean Choice: C<{Yes,No,Maybe}>

Restricts data entry strictly to one of the three words in the
comma-separated list.

=back

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

