package TUI::Views::ListViewer;
# ABSTRACT: Base class for list viewers

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TListViewer
  new_TListViewer
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

use TUI::Const qw( EOS );
use TUI::Drivers::Const qw(
  :evXXXX
  kbUp
  kbDown
  kbLeft
  kbRight
  kbPgDn
  kbPgUp
  kbHome
  kbEnd
  kbCtrlPgDn
  kbCtrlPgUp
  meDoubleClick
);
use TUI::Drivers::Util qw(
  ctrlToArrow
);
use TUI::Objects::Point;
use TUI::Views::Const qw(
  cmScrollBarChanged
  cmScrollBarClicked
  cmListItemSelected
  cpListViewer
  ofFirstClick
  ofSelectable
  :sfXXXX
);
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::View;
use TUI::Views::Util qw( message );

sub TListViewer() { __PACKAGE__ }
sub name() { 'TListViewer' }
sub new_TListViewer { __PACKAGE__->from(@_) }

# import global variables
use vars qw(
  $showMarkers
  $specialChars
  $emptyText
);
{
  no strict 'refs';
  *showMarkers  = \${ TView . '::showMarkers'  };
  *specialChars = \${ TView . '::specialChars' };
}

extends TView;

# declare global variables
our $emptyText = "<empty>";

# declare attributes
has hScrollBar => ( is => 'rw' );
has vScrollBar => ( is => 'rw' );
has numCols    => ( is => 'rw' );
has topItem    => ( is => 'rw', default => 0 );
has focused    => ( is => 'rw', default => 0 );
has range      => ( is => 'rw', default => 0 );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      numCols    => PositiveOrZeroInt, { alias => 'aNumCols' },
      hScrollBar => Maybe[Object],     { alias => 'aHScrollBar' },
      vScrollBar => Maybe[Object],     { alias => 'aVScrollBar' },
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
  my ( $arStep, $pgStep );
  $self->{options}   |= ofFirstClick | ofSelectable;
  $self->{eventMask} |= evBroadcast;
  if ( $self->{vScrollBar} ) {
    if ( $self->{numCols} == 1 ) {
      $pgStep = $self->{size}{y} - 1;
      $arStep = 1;
    }
    else {
      $pgStep = $self->{size}{y} * $self->{numCols};
      $arStep = $self->{size}{y};
    }
    $self->{vScrollBar}->setStep( $pgStep, $arStep );
  } #/ if ( $self->{vScrollBar...})

  if ( $self->{hScrollBar} ) {
    $self->{hScrollBar}->setStep(
      int( $self->{size}{x} / $self->{numCols} ), 
      1
    );
  }
  return;
}

sub from {    # $obj ($bounds, $aNumCols, $aHScrollBar|undef, $aVScrollBar|undef)
  state $sig = signature(
    method => 1,
    pos    => [Object, PositiveOrZeroInt, Maybe[Object], Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], numCols => $args[1], 
    hScrollBar => $args[2], vScrollBar => $args[3] );
}

sub changeBounds {    # void ($bounds)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $bounds ) = $sig->( @_ );
  $self->SUPER::changeBounds( $bounds );
  if ( $self->{hScrollBar} ) {
    $self->{hScrollBar}->setStep(
      int( $self->{size}{x} / $self->{numCols} ), 
      $self->{hScrollBar}{arStep}
    );
  }
  if ( $self->{vScrollBar} ) {
    $self->{vScrollBar}->setStep( 
      $self->{size}{y}, 
      $self->{vScrollBar}{arStep}
    );
  }
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my ( $i, $j, $item );
  my ( $normalColor, $selectedColor, $focusedColor, $color );
  my ( $colWidth, $curCol, $indent );
  my $b = TDrawBuffer->new;
  my $scOff;

  if ( ( $self->{state} & ( sfSelected | sfActive ) ) 
      == ( sfSelected | sfActive )
  ) {
    $normalColor   = $self->getColor( 1 );
    $focusedColor  = $self->getColor( 3 );
    $selectedColor = $self->getColor( 4 );
  }
  else {
    $normalColor   = $self->getColor( 2 );
    $selectedColor = $self->getColor( 4 );
  }

  if ( $self->{hScrollBar} ) {
    $indent = $self->{hScrollBar}{value};
  }
  else {
    $indent = 0;
  }

  $colWidth = int( $self->{size}{x} / $self->{numCols} ) + 1;
  for ( $i = 0 ; $i < $self->{size}{y} ; $i++ ) {
    for ( $j = 0 ; $j < $self->{numCols} ; $j++ ) {
      $item   = $j * $self->{size}{y} + $i + $self->{topItem};
      $curCol = $j * $colWidth;
      if ( ( ( $self->{state} & ( sfSelected | sfActive ) ) 
            == ( sfSelected | sfActive ) )
        && $self->{focused} == $item
        && $self->{range} > 0 )
      {
        $color = $focusedColor;
        $self->setCursor( $curCol + 1, $i );
        $scOff = 0;
      }
      elsif ( $item < $self->{range} && $self->isSelected( $item ) ) {
        $color = $selectedColor;
        $scOff = 2;
      }
      else {
        $color = $normalColor;
        $scOff = 4;
      }
      $b->moveChar( $curCol, ' ', $color, $colWidth );
      if ( $item < $self->{range} ) {
        my $text;
        $self->getText( \$text, $item, $colWidth + $indent );
        my $buf = substr( $text, $indent, $colWidth );
        $b->moveStr( $curCol + 1, $buf, $color );
        if ( $showMarkers ) {
          $b->putChar( $curCol, $specialChars->[$scOff] );
          $b->putChar( $curCol + $colWidth - 2, $specialChars->[ $scOff + 1 ] );
        }
      } #/ if ( $item < $self->{range...})
      elsif ( $i == 0 && $j == 0 ) {
        $b->moveStr( $curCol + 1, $emptyText, $self->getColor( 1 ) );
      }

      $b->moveChar( $curCol + $colWidth - 1, chr 179, $self->getColor( 5 ), 1 );
    } #/ for ( $j = 0 ; $j < $self...)

    $self->writeLine( 0, $i, $self->{size}{x}, 1, $b );
  } #/ for ( $i = 0 ; $i < $self...)

  return;
} #/ sub draw

sub focusItem {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  $self->{focused} = $item;
  if ( $self->{vScrollBar} ) {
    $self->{vScrollBar}->setValue( $item );
  }
  else {
    $self->drawView;
  }
  if ( $item < $self->{topItem} ) {
    if ( $self->{numCols} == 1 ) {
      $self->{topItem} = $item;
    }
    else {
      $self->{topItem} = $item - ( $item % $self->{size}{y} );
    }
  }
  else {
    if ( $item >= $self->{topItem} + $self->{size}{y} * $self->{numCols} ) {
      if ( $self->{numCols} == 1 ) {
        $self->{topItem} = $item - $self->{size}{y} + 1;
      }
      else {
        $self->{topItem} = $item - ( $item % $self->{size}{y} ) -
          ( $self->{size}{y} * ( $self->{numCols} - 1 ) );
      }
    } #/ if ( $item >= $self->{...})
  } #/ else [ if ( $item < $self->{topItem...})]
  return;
} #/ sub focusItem

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpListViewer, 
    size => length( cpListViewer ),
  );
  return $palette->clone();
}

sub getText {    # void (\$dest, $item, $width)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef, Int, Int],
  );
  my ( $self, $dest, $item, $width ) = $sig->( @_ );
  $$dest = EOS;
  return;
}

sub isSelected {    # $bool ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  return $item == $self->{focused};
}

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );

  my $mouse;
  my $colWidth;
  my ($oldItem, $newItem );
  my $count;
  my $mouseAutosToSkip = 4;

  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evMouseDown ) {
    $colWidth = int( $self->{size}{x} / $self->{numCols} ) + 1;
    $oldItem  = $self->{focused};
    $mouse = $self->makeLocal( $event->{mouse}{where} );
    if ( $self->mouseInView( $event->{mouse}{where} ) ) {
      $newItem = $mouse->{y} 
        + ( $self->{size}{y} * int( $mouse->{x} / $colWidth ) ) 
          + $self->{topItem};
    }
    else {
      $newItem = $oldItem;
    }
    $count = 0;
    DO: { do {
      if ( $newItem != $oldItem ) {
        $self->focusItemNum( $newItem );
        $self->drawView();
      }
      $oldItem = $newItem;
      $mouse = $self->makeLocal( $event->{mouse}{where} );
      if ( $self->mouseInView( $event->{mouse}{where} ) ) {
        $newItem = $mouse->{y} 
          + ( $self->{size}{y} * int( $mouse->{x} / $colWidth ) ) 
            + $self->{topItem};
      }
      else {
        if ( $self->{numCols} == 1 ) {
          if ( $event->{what} == evMouseAuto ) {
            $count++;
          }
          if ( $count == $mouseAutosToSkip ) {
            $count = 0;
            if ( $mouse->{y} < 0 ) {
              $newItem = $self->{focused} - 1;
            }
            elsif ( $mouse->{y} >= $self->{size}{y} ) {
              $newItem = $self->{focused} + 1;
            }
          }
        } #/ if ( $self->{numCols} ...)
        else {
          if ( $event->{what} == evMouseAuto ) {
            $count++;
          }
          if ( $count == $mouseAutosToSkip ) {
            $count = 0;
            if ( $mouse->{x} < 0 ) {
              $newItem = $self->{focused} - $self->{size}{y};
            }
            elsif ( $mouse->{x} >= $self->{size}{x} ) {
              $newItem = $self->{focused} + $self->{size}{y};
            }
            elsif ( $mouse->{y} < 0 ) {
              $newItem = $self->{focused} 
                - ( $self->{focused} % $self->{size}{y} );
            }
            elsif ( $mouse->{y} > $self->{size}{y} ) {
              $newItem = $self->{focused} 
                - ( $self->{focused} % $self->{size}{y} ) 
                  + $self->{size}{y} - 1;
            }
          } #/ if ( $count == $mouseAutosToSkip)
        } #/ else [ if ( $self->{numCols} ...)]
      } #/ else [ if ( $self->mouseInView...)]
      last DO
        if $event->{mouse}{eventFlags} & meDoubleClick;

    } while ( $self->mouseEvent( $event, evMouseMove | evMouseAuto ) ) }
    $self->focusItemNum( $newItem );
    $self->drawView;
    if ( ( $event->{mouse}{eventFlags} & meDoubleClick )
      && $self->{range} > $newItem
    ) {
      $self->selectItem( $newItem );
    }
    $self->clearEvent( $event );
  } #/ if ( $event->{what} ==...)

  elsif ( $event->{what} == evKeyDown ) {
    if ( $event->{keyDown}{charScan}{charCode} eq ' '
      && $self->{focused} < $self->{range}
    ) {
      $self->selectItem( $self->{focused} );
      $newItem = $self->{focused};
    }
    else {
      SWITCH: for ( ctrlToArrow( $event->{keyDown}{keyCode} ) ) {
        kbUp == $_ and do {
          $newItem = $self->{focused} - 1;
          last;
        };
        kbDown == $_ and do {
          $newItem = $self->{focused} + 1;
          last;
        };
        kbRight == $_ and do {
          if ( $self->{numCols} > 1 ) {
            $newItem = $self->{focused} + $self->{size}{y};
          }
          else {
            return;
          }
          last;
        };
        kbLeft == $_ and do {
          if ( $self->{numCols} > 1 ) {
            $newItem = $self->{focused} - $self->{size}{y};
          }
          else {
            return;
          }
          last;
        };
        kbPgDn == $_ and do {
          $newItem = $self->{focused} + $self->{size}{y} * $self->{numCols};
          last;
        };
        kbPgUp == $_ and do {
          $newItem = $self->{focused} - $self->{size}{y} * $self->{numCols};
          last;
        };
        kbHome == $_ and do {
          $newItem = $self->{topItem};
          last;
        };
        kbEnd == $_ and do {
          $newItem =
            $self->{topItem} + ( $self->{size}{y} * $self->{numCols} ) - 1;
          last;
        };
        kbCtrlPgDn == $_ and do {
          $newItem = $self->{range} - 1;
          last;
        };
        kbCtrlPgUp == $_ and do {
          $newItem = 0;
          last;
        };
        DEFAULT: {
          return;
        }
      } #/ SWITCH: for ( ctrlToArrow( $event...))
    } #/ else [ if ( $event->{keyDown}...)]
    $self->focusItemNum( $newItem );
    $self->drawView();
    $self->clearEvent( $event );
  } #/ elsif ( $event->{what} ==...)

  elsif ( $event->{what} == evBroadcast ) {
    if ( $self->{options} & ofSelectable ) {
      if ( $event->{message}{command} == cmScrollBarClicked 
        && ( $event->{message}{infoPtr} == $self->{hScrollBar}
          || $event->{message}{infoPtr} == $self->{vScrollBar} )
      ) {
        $self->focus();    # BUG FIX <<----- Change
      }
      elsif ( $event->{message}{command} == cmScrollBarChanged ) {
        if ( $self->{vScrollBar} == $event->{message}{infoPtr} ) {
          $self->focusItemNum( $self->{vScrollBar}{value} );
          $self->drawView();
        }
        elsif ( $self->{hScrollBar} == $event->{message}{infoPtr} ) {
          $self->drawView();
        }
      }
    } #/ if ( $self->{options} ...)
  } #/ elsif ( $event->{what} ==...)
  return;
} #/ sub handleEvent

sub selectItem {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  message( $self->{owner}, evBroadcast, cmListItemSelected, $self );
  return;
}

sub setRange {    # void ($aRange)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $aRange ) = $sig->( @_ );
  $self->{range} = $aRange;

  # BUG FIX - EFW - Tue 06/26/95
  if ( $self->{focused} >= $aRange ) {
    $self->{focused} = ( $aRange - 1 >= 0 ) ? $aRange - 1 : 0;
  }

  if ( $self->{vScrollBar} ) {
    $self->{vScrollBar}->setParams( $self->{focused}, 0, $aRange - 1,
      $self->{vScrollBar}{pgStep}, $self->{vScrollBar}{arStep} );
  }
  else {
    $self->drawView();
  }
  return;
} #/ sub setRange

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );
  $self->SUPER::setState( $aState, $enable );
  if ( $aState & (sfSelected | sfActive | sfVisible) ) {
    if ( $self->{hScrollBar} ) {
      if ( $self->getState(sfActive) && $self->getState(sfVisible) ) {
        $self->{hScrollBar}->show();
      } 
      else {
        $self->{hScrollBar}->hide();
      }
    }
    if ( $self->{vScrollBar} ) {
      if ( $self->getState(sfActive) && $self->getState(sfVisible) ) {
        $self->{vScrollBar}->show();
      } 
      else {
        $self->{vScrollBar}->hide();
      }
    }
    $self->drawView();
  }
  return;
} #/ sub setState

sub focusItemNum {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  if ( $item < 0 ) {
    $item = 0;
  }
  elsif ( $item >= $self->{range} && $self->{range} > 0 ) {
    $item = $self->{range} - 1;
  }
  $self->focusItem( $item )
    if $self->{range};
  return;
} #/ sub focusItemNum

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{hScrollBar} = undef;
  $self->{vScrollBar} = undef;
  $self->SUPER::shutDown();
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Views::ListViewer - base class for list viewers

=head1 HIERARCHY

  TObject
    TView
      TListViewer
        TListBox

=head1 SYNOPSIS

  use TUI::Views;

  # Subclass TListViewer and override getText to supply your own data
  package MyListViewer;
  use Moo;
  use TUI::Views;
  extends TListViewer;

  sub getText {
    my ( $self, $dest, $item, $maxChars ) = @_;
    my @data = ( 'alpha', 'beta', 'gamma' );
    $$dest = substr( $data[$item] // '', 0, $maxChars );
  }

  package main;

  my $hbar = TScrollBar->new(
    bounds => TRect->new( ax => 0, ay => 10, bx => 20, by => 11 ) );
  my $vbar = TScrollBar->new(
    bounds => TRect->new( ax => 20, ay => 0, bx => 21, by => 10 ) );

  my $lv = MyListViewer->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 20, by => 10 ),
    numCols    => 1,
    hScrollBar => $hbar,
    vScrollBar => $vbar,
  );
  $lv->setRange( 3 );

=head1 DESCRIPTION

C<TListViewer> is the TUI::Vision base class for list viewer controls. It
implements the generic behavior required to display a list of items arranged
in one or more columns, including keyboard navigation, mouse interaction, and
scroll bar synchronization.

C<TListViewer> does not store the actual data being displayed. Subclasses are
expected to provide the data by overriding C<getText()> and typically also
C<selectItem()>.

List viewers may be equipped with horizontal and/or vertical scroll bars. When
attached, the list viewer keeps the scroll bars synchronized with the current
focus and range.

=head2 Commonly Used Features

Because C<TListViewer> does not manage any data itself, the primary task when
using it is to subclass it and override C<getText>, which is called once per
visible row to retrieve the display string for a given item index. After
construction, call C<setRange> to tell the viewer how many items exist. When
the list viewer is placed in a group other than a dialog, C<getPalette> will
almost certainly need to be overridden as well so that the color mapping works
correctly.

=head1 VARIABLES

The following global variable defines the placeholder text used by
C<TListViewer>.

=head2 $emptyText

Text displayed when the list contains no items.

=head1 ATTRIBUTES

The following attributes are implemented as read/write accessors and are also
used internally by the list viewer.

=over

=item hScrollBar

Horizontal scroll bar associated with the list viewer.

=item vScrollBar

Vertical scroll bar associated with the list viewer.

=item numCols

Number of columns used to display items.

=item topItem

Index of the first visible item.

=item focused

Index of the currently focused item.

=item range

Total number of items in the list.

=back

=head1 CONSTRUCTOR

=head2 new

  my $lv = TListViewer->new(
    bounds     => $bounds,
    numCols    => $numCols,
    hScrollBar => $hScrollBar,
    vScrollBar => $vScrollBar
  );

Creates a new list viewer.

=over

=item bounds

Bounding rectangle of the list viewer (I<TRect>).

=item numCols

Number of columns used to display items (I<PositiveOrZeroInt>).

=item hScrollBar

Optional horizontal scroll bar (I<TScrollBar>).

=item vScrollBar

Optional vertical scroll bar (I<TScrollBar>).

=back

=head2 new_TListViewer

  my $lv = new_TListViewer($bounds, $numCols, $hScrollBar, $vScrollBar);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 changeBounds

  $lv->changeBounds($bounds);

Adjusts the list viewer to a new bounding rectangle and recalculates scroll bar
parameters.

=head2 draw

  $lv->draw();

Draws the list viewer contents using C<getText()>.

=head2 focusItem

  $lv->focusItem($index);

Moves the focus to the specified item index.

=head2 focusItemNum

  $lv->focusItemNum($index);

Like C<focusItem>, but clamps the index to the valid range.

=head2 getPalette

  my $palette = $lv->getPalette();

Returns the color palette used to draw the list viewer.

=head2 getText

  $lv->getText(\$dest, $item, $maxChars);

Returns the text representation of an item.

Subclasses are expected to override this method to provide the actual data to be
displayed by the list viewer.

=head2 handleEvent

  $lv->handleEvent($event);

Handles keyboard, mouse, and broadcast events.

=head2 isSelected

  my $bool = $lv->isSelected($index);

Returns true if the specified item is selected.

Subclasses may override this method to implement multi-selection or alternative
selection policies.

=head2 selectItem

  $lv->selectItem($index);

Called when an item is activated.

Subclasses typically override this method to implement application-specific
activation behavior.

=head2 setRange

  $lv->setRange($count);

Sets the number of items in the list and updates scroll bar state.

=head2 setState

  $lv->setState($state, $enable);

Updates the view state and shows or hides scroll bars accordingly.

=head2 shutDown

  $lv->shutDown();

Releases scroll bar references and shuts down the view.

=head1 SEE ALSO

L<TUI::Dialogs::ListBox>,
L<TUI::Views::ScrollBar>,
L<TUI::Views::View>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

=over

=item * Eric Woodruff

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 1995, 2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
