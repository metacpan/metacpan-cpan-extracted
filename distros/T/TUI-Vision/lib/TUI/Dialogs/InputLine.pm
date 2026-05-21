package TUI::Dialogs::InputLine;
# ABSTRACT: Editable single-line text input control for dialogs.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TInputLine
  new_TInputLine
);

use List::Util qw( min max );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Const qw( EOS );
use TUI::Dialogs::Const qw( cpInputLine );
use TUI::Drivers::Const qw(
  :evXXXX
  kbShift
  kbLeft
  kbRight
  kbHome
  kbEnd
  kbBack
  kbDel
  kbIns
  meDoubleClick
);
use TUI::Drivers::Util qw( ctrlToArrow );
use TUI::Validate::Const qw( :vtXXXX );
use TUI::Views::Const qw(
  ofSelectable
  ofFirstClick
  :sfXXXX
);
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::View;

sub TInputLine() { __PACKAGE__ }
sub name() { 'TInputLine' }
sub new_TInputLine { __PACKAGE__->from(@_) }

extends TView;

use constant CONTROL_Y => 25;

# declare global variables
our $rightArrow = "\x10";
our $leftArrow  = "\x11";

# public attributes
has data        => ( is => 'rw', default => '' );
has maxLen      => ( is => 'ro', default => sub { die 'required' } );
has curPos      => ( is => 'rw', default => 0 );
has firstPos    => ( is => 'rw', default => 0 );
has selStart    => ( is => 'ro', default => 0 );
has selEnd      => ( is => 'ro', default => 0 );

# private attributes
has validator   => ( is => 'bare' );
has anchor      => ( is => 'bare', default => -1 );
has oldAnchor   => ( is => 'bare', default => -1 );    # New to save state info
has oldData     => ( is => 'bare', default => '' );
has oldCurPos   => ( is => 'bare' );
has oldFirstPos => ( is => 'bare' );
has oldSelStart => ( is => 'bare' );
has oldSelEnd   => ( is => 'bare' );

# predeclare private methods
my (
  $canScroll,
  $mouseDelta,
  $mousePos,
  $deleteSelect,
  $adjustSelectBlock,
  $saveState,
  $restoreState,
  $checkValid,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds    => Object,
      maxLen    => Int,    { alias => 'aMaxLen' },
      validator => Object, { alias => 'aValid', optional => 1 },
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
  $self->{state} |= sfCursorVis;
  $self->{options} |= ofSelectable | ofFirstClick;
  return;
}

sub from {    # $obj ($bounds, $aMaxLen, |$aValid)
  state $sig = signature(
    method => 1,
    pos    => [
      Object,
      Int,
      Object, { optional => 1 }
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  SWITCH: for ( scalar @args ) {
    $_ == 2 and return $class->new( bounds => $args[0], maxLen => $args[1] );
    $_ == 3 and return $class->new( bounds => $args[0], maxLen => $args[1], 
      validator => $args[2] );
  }
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{data} = undef;
  $self->{oldData} = undef;
  $self->destroy( $self->{validator} );
  return;
}

sub dataSize {    # $dSize ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $dSize = 0;

  if ( $self->{validator} ) {
    $dSize = $self->{validator}->transfer( $self->{data}, undef, vtDataSize );
  }
  if ( $dSize == 0 ) {
    $dSize = 1;    # In Perl, this must be the number of entries in the list
  }
  return $dSize;
} #/ sub dataSize

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my ( $l, $r );
  my $b = TDrawBuffer->new();
  my $color = $self->{state} & sfFocused
            ? $self->getColor( 2 )
            : $self->getColor( 1 );

  $b->moveChar( 0, ' ', $color, $self->{size}{x} );
  my $buf = substr( $self->{data}, $self->{firstPos}, $self->{size}{x} - 2 );
  $b->moveStr( 1, $buf, $color );

  if ( $self->$canScroll( 1 ) ) {
    $b->moveChar( $self->{size}{x} - 1, $rightArrow, $self->getColor( 4 ), 1 );
  }
  if ( $self->{state} & sfSelected ) {
    if ( $self->$canScroll( -1 ) ) {
      $b->moveChar( 0, $leftArrow, $self->getColor( 4 ), 1 );
    }
    $l = $self->{selStart} - $self->{firstPos};
    $r = $self->{selEnd} - $self->{firstPos};
    $l = max( 0, $l );
    $r = min( $self->{size}{x} - 2, $r );
    if ( $l < $r ) {
      $b->moveChar( $l + 1, 0, $self->getColor( 3 ), $r - $l );
    }
  } #/ if ( ( $self->{state} ...))
  $self->writeLine( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  $self->setCursor( $self->{curPos} - $self->{firstPos} + 1, 0 );
  return;
} #/ sub draw

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  if ( !$self->{validator}
    || !$self->{validator}->transfer( $self->{data}, $rec, vtGetData )
  ) {
    assert ( $self->dataSize() );
    $rec->[0] = $self->{data};
  }
  return;
} #/ sub getData

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpInputLine, 
    size => length( cpInputLine ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  # Home, Left Arrow, Right Arrow, End, Ctrl-Left Arrow, Ctrl-Right Arrow
  my @padKeys = ( 0x47, 0x4b, 0x4d, 0x4f, 0x73, 0x74 );
  $self->SUPER::handleEvent( $event );

  my ( $delta, $i );
  return unless ( $self->{state} & sfSelected );
  SWITCH: for ( $event->{what} ) {
    evMouseDown == $_ and do {
      if ( $self->$canScroll( $delta = $self->$mouseDelta( $event ) ) ) {
        do {
          if ( $self->$canScroll( $delta ) ) {
            $self->{firstPos} += $delta;
            $self->drawView();
          }
        } while $self->mouseEvent( $event, evMouseAuto );
      } #/ if ( $self->$canScroll(...))
      elsif ( $event->{mouse}{eventFlags} & meDoubleClick ) {
        $self->selectAll( 1 );
      }
      else {
        $self->{anchor} = $self->$mousePos( $event );
        do {
          if ( $event->{what} == evMouseAuto ) {
            $delta = $self->$mouseDelta( $event );
            if ( $self->$canScroll( $delta ) ) {
              $self->{firstPos} += $delta;
            }
          }
          $self->{curPos} = $self->$mousePos( $event );
          $self->$adjustSelectBlock();
          $self->drawView();
        } while $self->mouseEvent( $event, evMouseMove | evMouseAuto );
      } #/ else [ if ( $self->$canScroll(...))]
      $self->clearEvent( $event );
      last;
    };

    evKeyDown == $_ and do {
      $self->$saveState();
      $event->{keyDown}{keyCode} =
        ctrlToArrow( $event->{keyDown}{keyCode} );
      my $scanCode  = $event->{keyDown}{charScan}{scanCode};
      my $isPad    = grep { $_ == $scanCode } @padKeys;
      my $hasShift = $event->{keyDown}{controlKeyState} & kbShift;
      if ( $isPad && $hasShift ) {
        $event->{keyDown}{charScan}{charCode} = 0;
        if ( $self->{anchor} < 0 ) {
          $self->{anchor} = $self->{curPos};
        }
      }
      else {
        $self->{anchor} = -1;
      }
      SWITCH: for ( $event->{keyDown}{keyCode} ) {
        kbLeft == $_ and do {
          if ( $self->{curPos} > 0 ) {
            $self->{curPos}--;
          }
          last;
        };
        kbRight == $_ and do {
          if ( $self->{curPos} < length( $self->{data} ) ) {
            $self->{curPos}++;
          }
          last;
        };
        kbHome == $_ and do {
          $self->{curPos} = 0;
          last;
        };
        kbEnd == $_ and do {
          $self->{curPos} = length( $self->{data} );
          last;
        };
        kbBack == $_ and do {
          if ( $self->{curPos} > 0 ) {
            substr( $self->{data}, $self->{curPos} - 1, 1, '' );
            $self->{curPos}--;
            if ( $self->{firstPos} > 0 ) {
              $self->{firstPos}--;
            }
            $self->$checkValid( true );
          } #/ if ( $self->{curPos} >...)
          last;
        };
        kbDel == $_ and do {
          if ( $self->{selStart} == $self->{selEnd} ) {
            if ( $self->{curPos} < length( $self->{data} ) ) {
              $self->{selStart} = $self->{curPos};
              $self->{selEnd}   = $self->{curPos} + 1;
            }
          }
          $self->$deleteSelect();
          $self->$checkValid( true );
          last;
        };
        kbIns == $_ and do {
          $self->setState( sfCursorIns, !( $self->{state} & sfCursorIns ) );
          last;
        };
        DEFAULT: {
          my $ch = $event->{keyDown}{charScan}{charCode};
          if ( defined $ch && $ch >= ord( ' ' ) ) {
            $self->$deleteSelect();
            if ( $self->{state} & sfCursorIns ) {
              # The following is always a signed comparison in Perl!
              if ( $self->{curPos} < length( $self->{data} ) ) {
                substr( $self->{data}, $self->{curPos}, 1, '' );
              }
            }
            if ( $self->$checkValid( true ) ) {
              my $strlen = length( $self->{data} );
              if ( $strlen < $self->{maxLen} ) {
                if ( $self->{firstPos} > $self->{curPos} ) {
                  $self->{firstPos} = $self->{curPos};
                }
                # In Perl, only move the data if the insertion is not at end
                if ( $self->{curPos} < $strlen ) {
                  substr( $self->{data}, $self->{curPos} + 1 ) =
                    substr( $self->{data}, $self->{curPos} )
                }
                substr( $self->{data}, $self->{curPos}, 1 ) = chr( $ch );
                $self->{curPos}++;
              }
              $self->$checkValid( false );
            } #/ if ( $self->$checkValid...)
          } #/ if ( defined $ch && $ch...)
          elsif ( defined $ch && $ch == CONTROL_Y ) {
            $self->{data}   = EOS;
            $self->{curPos} = 0;
          }
          else {
            return;
          }
          last;
        };
      } #/ SWITCH: for ( $event->{keyDown}...)

      $self->$adjustSelectBlock();
      if ( $self->{firstPos} > $self->{curPos} ) {
        $self->{firstPos} = $self->{curPos};
      }
      $i = $self->{curPos} - $self->{size}{x} + 2;
      if ( $self->{firstPos} < $i ) {
        $self->{firstPos} = $i;
      }
      $self->drawView();
      $self->clearEvent( $event );
      last;
    };
  } #/ SWITCH: for ( $event->{what} )
  return;
} #/ sub handleEvent

sub selectAll {    # void ($enable)
  state $sig = signature(
    method => Object,
    pos    => [Bool],
  );
  my ( $self, $enable ) = $sig->( @_ );
  $self->{selStart} = 0;
  if ( $enable ) {
    my $len = length( $self->{data} );
    $self->{curPos} = $self->{selEnd} = $len;
  }
  else {
    $self->{curPos} = $self->{selEnd} = 0;
  }
  $self->{firstPos} = max( 0, $self->{curPos} - $self->{size}{x} + 2 );
  $self->{anchor} = 0;    # This sets anchor to avoid deselect on init selection
  $self->drawView();
  return;
} #/ sub selectAll

sub setData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  if ( !$self->{validator}
    || !$self->{validator}->transfer( $self->{data}, $rec, vtSetData )
  ) {
    assert ( $self->dataSize() );
    assert ( defined $rec->[0] and !ref $rec->[0] );
    $self->{data} = substr( $rec->[0], 0, $self->{maxLen} );
  } #/ if ( !$self->{validator...})
  $self->selectAll( true );
  return;
} #/ sub setData

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );
  $self->SUPER::setState( $aState, $enable );
  if ( $aState == sfSelected
    || ( $aState == sfActive && ( $self->{state} & sfSelected ) )
  ) {
    $self->selectAll( $enable );
  }
  return;
} #/ sub setState

sub setValidator {    # void ($aValid|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $aValid ) = $sig->( @_ );
  if ( $self->{validator} ) {
    $self->destroy( $self->{validator} );
  }
  $self->{validator} = $aValid;
  return;
} #/ sub setValidator

$canScroll = sub {    # bool ($delta)
  my ( $self, $delta ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Int $delta );
  if ( $delta < 0 ) {
    return $self->{firstPos} > 0;
  }
  elsif ( $delta > 0 ) {
    return length( $self->{data} ) - $self->{firstPos} + 2 > $self->{size}{x};
  }
  else {
    return false;
  }
};

$mouseDelta = sub {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $event );
  my $mouse = $self->makeLocal( $event->{mouse}{where} );

  if ( $mouse->{x} <= 0 ) {
    return -1;
  }
  else {
    $mouse->{x} >= $self->{size}{x} - 1 ? 1 : 0;
  }
};

$mousePos = sub {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $event );
  my $mouse = $self->makeLocal( $event->{mouse}{where} );
  $mouse->{x} = max( $mouse->{x}, 1 );
  my $pos = $mouse->{x} + $self->{firstPos} - 1;
  $pos = max( $pos, 0 );
  $pos = min( $pos, length( $self->{data} ) );
  return $pos;
};

$deleteSelect = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  if ( $self->{selStart} < $self->{selEnd} ) {
    substr( $self->{data}, $self->{selStart} ) =
      substr( $self->{data}, $self->{selEnd} );
    $self->{curPos} = $self->{selStart};
  } #/ if ( $self->{selStart}...)
  return;
};

$adjustSelectBlock = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  if ( $self->{anchor} < 0 ) {
    $self->{selStart} = 0;
    $self->{selEnd}   = 0;
  }
  elsif ( $self->{anchor} > $self->{curPos} ) {
    $self->{selStart} = $self->{curPos};
    $self->{selEnd}   = $self->{anchor};
  }
  else {
    $self->{selStart} = $self->{anchor};
    $self->{selEnd}   = $self->{curPos};
  }
  return;
};

$saveState = sub {   # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  if ( $self->{validator} ) {
    $self->{oldData}     = $self->{data};
    $self->{oldCurPos}   = $self->{curPos};
    $self->{oldFirstPos} = $self->{firstPos};
    $self->{oldSelStart} = $self->{selStart};
    $self->{oldSelEnd}   = $self->{selEnd};
    $self->{oldAnchor}   = $self->{anchor};
  } #/ if ( $self->{validator...})
  return;
};

$restoreState = sub {   # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  if ( $self->{validator} ) {
    $self->{data}     = $self->{oldData};
    $self->{curPos}   = $self->{oldCurPos};
    $self->{firstPos} = $self->{oldFirstPos};
    $self->{selStart} = $self->{oldSelStart};
    $self->{selEnd}   = $self->{oldSelEnd};
    $self->{anchor}   = $self->{oldAnchor};
  } #/ if ( $self->{validator...})
  return;
};

$checkValid = sub {   # $bool ($noAutoFill)
  my ( $self, $noAutoFill ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Bool $noAutoFill );
  return true unless $self->{validator};
  my $oldLen = length( $self->{data} );
  my $newData = $self->{data};
  if ( !$self->{validator}->isValidInput( $newData, $noAutoFill ) ) {
    $self->$restoreState();
    return false;
  }
  else {
    if ( length( $newData ) > $self->{maxLen} ) {
      substr( $newData, $self->{maxLen} ) = '';
    }
    $self->{data} = $newData;
    if ( $self->{curPos} >= $oldLen && length( $self->{data} ) > $oldLen ) {
      $self->{curPos} = length( $self->{data} );
    }
    return true;
  } #/ else [ if ( !$self->{validator...})]
};

1

__END__

=pod

=head1 NAME

TUI::Dialogs::InputLine - editable single-line text input control for dialogs

=head1 HIERARCHY

  TObject
    TView
      TInputLine

=head1 SYNOPSIS

  use TUI::Dialogs;

  my $input = new_TInputLine($bounds, 64);
  my $data = ['Hello'];
  $input->setData($data);

=head1 DESCRIPTION

C<TInputLine> implements a single-line editable text field for use in dialog
boxes. It provides cursor movement, text insertion and deletion, selection,
and horizontal scrolling when the visible field is smaller than the maximum
allowed input length.

The control automatically handles keyboard and mouse input when it has focus.
It is typically used for entering filenames, identifiers, or other short text
values.

C<TInputLine> supports optional validation through validator objects. By
deriving from C<TInputLine> and overriding validation and data transfer
methods, applications can implement specialized input controls such as numeric
or formatted fields.

=head1 VARIABLES

The following global variables affect the visual rendering of C<TInputLine>.

=head2 $rightArrow

Defines the character used to indicate hidden text to the right of the
visible input area. The default value is a CP437 character.

=head2 $leftArrow

Defines the character used to indicate hidden text to the left of the
visible input area. The default value is a CP437 character.

=head1 ATTRIBUTES

The following attributes are part of the public state of the input line.
Internal and private attributes are intentionally not documented.

=over

=item data

Current text stored in the input field (I<Str>).

=item maxLen

Maximum allowed length of the input text (I<Int>).

=item curPos

Current cursor position within the text (I<Int>).

=item firstPos

Index of the first visible character, used for horizontal scrolling (I<Int>).

=item selStart

Start index of the current selection (I<Int>).

=item selEnd

End index of the current selection (I<Int>).

=back

=head1 CONSTRUCTOR

=head2 new

  my $input = TInputLine->new(
    bounds => $bounds,
    maxLen => $maxLen,
    validator => $validator
  );

Creates a new input line control.

=over

=item bounds

Bounding rectangle of the input field (I<TRect>).  
The rectangle must describe a single-line area.

=item maxLen

Maximum number of characters the input field can hold (I<Int>).

=item validator

Optional validator object used for input checking and data transfer
(I<TValidator>). This parameter may be omitted.

=back

=head2 new_TInputLine

  my $input = new_TInputLine($bounds, $maxLen, | $validator);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and is
provided for compatibility with traditional Turbo Vision construction patterns.

=head1 DESTRUCTOR

=head2 DEMOLISH

  $self->DEMOLISH($in_global_destruction);

Destroys the input line and releases associated resources. This method
corresponds to the Turbo Vision destructor and is normally invoked
automatically.

=head1 METHODS

=head2 dataSize

  my $size = $input->dataSize();

Returns the number of elements required to store the control's data.

For C<TInputLine>, this value is C<1>, since the input text is transferred as a
single element when using C<getData> and C<setData>.

=head2 draw

  $input->draw();

Draws the input line, including text, cursor, selection, and scroll indicators.

=head2 getData

  $input->getData(\$record);

Copies the current input text into the supplied record.

=head2 getPalette

  my $palette = $input->getPalette();

Returns the color palette used to draw the input line.

=head2 handleEvent

  $input->handleEvent($event);

Processes keyboard and mouse events for editing, selection, and navigation.

=head2 selectAll

  $input->selectAll($enable);

Selects or clears the entire input text depending on C<$enable>.

=head2 setData

  $input->setData(\$record);

Replaces the current input text using the supplied record and selects the text.

=head2 setState

  $input->setState($state, $enable);

Updates the view state and performs additional processing specific to input
lines.

=head2 setValidator

  $input->setValidator($validator);

Installs or replaces the validator object used for input checking.

=head1 SEE ALSO

L<TUI::Dialogs::Dialog>,
L<TUI::Dialogs::Label>,
L<TUI::Dialogs::History>,
L<TUI::Validators::Validator>

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
