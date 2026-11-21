package TUI::Editors::Editor;
# ABSTRACT: multi-line text editor view

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TEditor
  new_TEditor
);

use Class::Struct;
use English qw( $INPUT_RECORD_SEPARATOR );
use List::Util qw( max min );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  is_Str
  :types
);

use TUI::Drivers::Const qw(
  :evXXXX
  :kbXXXX
  meDoubleClick
);
use TUI::Editors::Const qw(
  :cmXXXX
  :edXXXX
  :efXXXX
  cpEditor
  maxLineLength
  sfSearchFailed
  smDouble
  smExtend
  ufLine
  ufUpdate
  ufView
);
use TUI::Editors::Editor::Edits;
use TUI::Editors::Util qw(
  countLines
  scan
  iScan
);
use TUI::Objects::Point;
use TUI::Objects::Rect;
use TUI::Views::CommandSet;
use TUI::Views::DrawBuffer;
use TUI::Views::Const qw(
  :cmXXXX
  :sfXXXX
  gfGrowHiX
  gfGrowHiY
  ofSelectable
);
use TUI::Views::Palette;
use TUI::Views::View;

struct TFindDialogRec => [
  find    => '$',
  options => '$',
];

struct TReplaceDialogRec => [
  find    => '$',
  replace => '$',
  options => '$',
];

sub TEditor() { __PACKAGE__ }
sub name() { 'TEditor' }
sub new_TEditor { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $editorDialog = sub {    # $command ($dialog, @_)
  return cmCancel;
};
our $editorFlags  = efBackupFiles | efPromptOnReplace;
our $findStr      = '';
our $replaceStr   = '';
our $clipboard    = undef;

# public attributes
has hScrollBar => ( is => 'rw' );
has vScrollBar => ( is => 'rw' );
has indicator  => ( is => 'rw' );
has buffer     => ( is => 'rw' );
has bufSize    => ( is => 'rw',   default => 0 );
has bufLen     => ( is => 'bare', default => 0 );
has gapLen     => ( is => 'ro',   default => 0 );
has selStart   => ( is => 'rw',   default => 0 );
has selEnd     => ( is => 'rw',   default => 0 );
has curPtr     => ( is => 'rw',   default => 0 );
has curPos     => ( is => 'rw',   default => sub { TPoint->new() } );
has delta      => ( is => 'rw',   default => sub { TPoint->new() } );
has limit      => ( is => 'rw',   default => sub { TPoint->new() } );
has drawLine   => ( is => 'rw',   default => 0 );
has drawPtr    => ( is => 'rw',   default => 0 );
has delCount   => ( is => 'rw',   default => 0 );
has insCount   => ( is => 'rw',   default => 0 );
has isValid    => ( is => 'rw',   default => false );
has canUndo    => ( is => 'rw',   default => true );
has delBuf     => ( is => 'bare', default => '' );
has modified   => ( is => 'rw',   default => false );
has selecting  => ( is => 'rw',   default => false );
has overwrite  => ( is => 'rw',   default => false );
has autoIndent => ( is => 'rw',   default => false );

has lockCount   => ( is => 'rw', default => 0 );
has updateFlags => ( is => 'rw', default => 0 );
has keyState    => ( is => 'rw', default => 0 );

# C++ inserted number of pairs at the beginning of the table, Perl does not 
# need it to indicate the number of pairs, so we use 0 as a placeholder
my @firstKeys = ( 0,
	kbCtrlA()     => cmWordLeft,
	kbCtrlC()     => cmPageDown,
	kbCtrlD()     => cmCharRight,
	kbCtrlE()     => cmLineUp,
	kbCtrlF()     => cmWordRight,
	kbCtrlG()     => cmDelChar,
	kbCtrlH()     => cmBackSpace,
	kbCtrlK()     => 0xFF02,
	kbCtrlL()     => cmSearchAgain,
	kbCtrlM()     => cmNewLine,
	kbCtrlO()     => cmIndentMode,
	kbCtrlQ()     => 0xFF01,
	kbCtrlR()     => cmPageUp,
	kbCtrlS()     => cmCharLeft,
	kbCtrlT()     => cmDelWord,
	kbCtrlU()     => cmUndo,
	kbCtrlV()     => cmInsMode,
	kbCtrlX()     => cmLineDown,
	kbCtrlY()     => cmDelLine,
	kbLeft()      => cmCharLeft,
	kbRight()     => cmCharRight,
	kbCtrlLeft()  => cmWordLeft,
	kbCtrlRight() => cmWordRight,
	kbHome()      => cmLineStart,
	kbEnd()       => cmLineEnd,
	kbUp()        => cmLineUp,
	kbDown()      => cmLineDown,
	kbPgUp()      => cmPageUp,
	kbPgDn()      => cmPageDown,
	kbCtrlPgUp()  => cmTextStart,
	kbCtrlPgDn()  => cmTextEnd,
	kbIns()       => cmInsMode,
	kbDel()       => cmDelChar,
	kbShiftIns()  => cmPaste,
	kbShiftDel()  => cmCut,
	kbCtrlIns()   => cmCopy,
	kbCtrlDel()   => cmClear,
);
my @quickKeys = ( 0,
  ord( 'A' ) => cmReplace,
  ord( 'C' ) => cmTextEnd,
  ord( 'D' ) => cmLineEnd,
  ord( 'F' ) => cmFind,
  ord( 'H' ) => cmDelStart,
  ord( 'R' ) => cmTextStart,
  ord( 'S' ) => cmLineStart,
  ord( 'Y' ) => cmDelEnd,
);
my @blockKeys = ( 0,
  ord( 'B' ) => cmStartSelect,
  ord( 'C' ) => cmPaste,
  ord( 'H' ) => cmHideSelect,
  ord( 'K' ) => cmCopy,
  ord( 'Y' ) => cmCut,
);
my @keyMap = ( \@firstKeys, \@quickKeys, \@blockKeys );

my $scanKeyMap = sub {    # $command ($keyMap, $keyCode)
  state $sig = signature(
    pos => [ArrayRef, Int],
  );
  my ( $keyMap, $keyCode ) = $sig->( @_ );
  my $codeLow = $keyCode & 0xFF;
  my $codeHi  = $keyCode >> 8;
  for ( my $i = 1; $i < @$keyMap; $i += 2 ) {
    my $mapLow = $keyMap->[$i] & 0xFF;
    my $mapHi  = $keyMap->[$i] >> 8;
    return $keyMap->[ $i + 1 ]
      if $mapLow == $codeLow && ( $mapHi == 0 || $mapHi == $codeHi );
  }
  return 0;
};

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds      => Object,
      hScrollBar  => Maybe[Object],     { alias => 'aHScrollBar' },
      vScrollBar  => Maybe[Object],     { alias => 'aVScrollBar' },
      indicator   => Maybe[Object],     { alias => 'aIndicator' },
      bufSize     => PositiveOrZeroInt, { alias => 'aBufSize' },
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
  $self->{growMode}  |= gfGrowHiX | gfGrowHiY;
  $self->{options}   |= ofSelectable;
  $self->{eventMask} |= evBroadcast;
  $self->showCursor();
  $self->initBuffer();
  $self->{isValid} = true;
  $self->setBufLen( 0 );
  return;
}

sub from {    # $obj ($bounds, $aHScrollBar|undef, $aVScrollBar|undef, $aIndicator|undef, $aBufSize)
  state $sig = signature(
    method => 1,
    pos    => [
      Object, 
      Maybe[Object], 
      Maybe[Object], 
      Maybe[Object], 
      PositiveOrZeroInt
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], hScrollBar => $args[1],
    vScrollBar => $args[2], indicator => $args[3], bufSize => $args[4] );
}

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->doneBuffer();
  $self->SUPER::shutDown();
  return;
}

sub changeBounds {    # void ($bounds)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $bounds ) = $sig->( @_ );
  $self->setBounds( $bounds );
  $self->{delta}{x} = max( 0,
    min( $self->{delta}{x}, $self->{limit}{x} - $self->{size}{x} ) );
  $self->{delta}{y} = max( 0,
    min( $self->{delta}{y}, $self->{limit}{y} - $self->{size}{y} ) );
  $self->update( ufView );
  return;
}

sub convertEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  return if $event->{what} != evKeyDown;

  my $kd = $event->{keyDown};
  if ( ( $kd->{controlKeyState} & kbShift ) != 0
    && $kd->{charScan}{scanCode} >= 0x47
    && $kd->{charScan}{scanCode} <= 0x51 )
  {
    $kd->{charScan}{charCode} = 0;
  }

  my $key = $kd->{keyCode};
  if ( $self->{keyState} != 0 ) {
    $key += 0x40 if ( $key & 0xFF ) >= 0x01 && ( $key & 0xFF ) <= 0x1A;
    $key -= 0x20 if ( $key & 0xFF ) >= 0x61 && ( $key & 0xFF ) <= 0x7A;
  }
  $key = &$scanKeyMap( $keyMap[ $self->{keyState} ], $key );
  $self->{keyState} = 0;
  if ( $key != 0 ) {
    if ( ( $key & 0xFF00 ) == 0xFF00 ) {
      $self->{keyState} = $key & 0xFF;
      $self->clearEvent( $event );
    }
    else {
      $event->{what} = evCommand;
      $event->{message}{command} = $key;
    }
  }
  return;
}

sub cursorVisible {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{curPos}{y} >= $self->{delta}{y}
    && $self->{curPos}{y} < $self->{delta}{y} + $self->{size}{y};
}

sub deleteSelect {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->insertText( '', 0, false );
  return;
}

sub doneBuffer {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  undef $self->{buffer};
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( $self->{drawLine} != $self->{delta}{y} ) {
    $self->{drawPtr} = lineMove( $self, $self->{drawPtr},
      $self->{delta}{y} - $self->{drawLine} );
    $self->{drawLine} = $self->{delta}{y};
  }
  $self->drawLines( 0, $self->{size}{y}, $self->{drawPtr} );
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpEditor,
    size => length( cpEditor ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );

  my $centerCursor = !$self->cursorVisible();
  my $selectMode   = 0;
  if ( $self->{selecting}
    || ( ( $event->{what} & evMouse )
      && ( $event->{mouse}{controlKeyState} & kbShift ) )
    || ( ( $event->{what} & evKeyDown )
      && ( $event->{keyDown}{controlKeyState} & kbShift ) ) )
  {
    $selectMode = smExtend;
  }

  $self->convertEvent( $event );

  SWITCH: for ( $event->{what} ) {
    evMouseDown == $_ and do {
      $selectMode |= smDouble 
        if $event->{mouse}{eventFlags} & meDoubleClick;
      do {
        $self->lock();
        if ( $event->{what} == evMouseAuto ) {
          my $mouse = $self->makeLocal( $event->{mouse}{where} );
          my ( $dx, $dy ) = ( $self->{delta}{x}, $self->{delta}{y} );
          $dx-- if $mouse->{x} < 0;
          $dx++ if $mouse->{x} >= $self->{size}{x};
          $dy-- if $mouse->{y} < 0;
          $dy++ if $mouse->{y} >= $self->{size}{y};
          $self->scrollTo( $dx, $dy );
        }
        $self->setCurPtr( $self->getMousePtr( $event->{mouse}{where} ),
          $selectMode );
        $selectMode |= smExtend;
        $self->unlock();
      } while ( $self->mouseEvent( $event, evMouseMove | evMouseAuto ) );
      last;
    };

    evKeyDown == $_ and do {
      my $ch = $event->{keyDown}{charScan}{charCode};
      return 
        unless $ch == 9 || ( $ch >= 32 && $ch < 255 );
      $self->lock();
      if ( $self->{overwrite} && !$self->hasSelection() ) {
        if ( $self->{curPtr} != $self->lineEnd( $self->{curPtr} ) ) {
          $self->{selEnd} = $self->nextChar( $self->{curPtr} );
        }
      }
      $self->insertText( chr( $ch ), 1, false );
      $self->trackCursor( $centerCursor );
      $self->unlock();
      last;
    };

    evCommand == $_ and do {
      SWITCH: for ( $event->{message}{command} ) {
        cmFind == $_ and do {
          $self->find();
          last;
        };
        cmReplace == $_ and do {
          $self->replace();
          last;
        };
        cmSearchAgain == $_ and do {
          $self->doSearchReplace();
          last;
        };
        DEFAULT: {
          $self->lock();
          SWITCH: for ( $event->{message}{command} ) {

            cmCharLeft == $_ and do {
              $self->setCurPtr( 
                $self->prevChar( $self->{curPtr} ), 
                $selectMode
              );
              last;
            };
            cmCharRight == $_ and do {
              $self->setCurPtr( 
                $self->nextChar( $self->{curPtr} ), 
                $selectMode 
              );
              last;
            };
            cmWordLeft == $_ and do {
              $self->setCurPtr( 
                $self->prevWord( $self->{curPtr} ), 
                $selectMode 
              );
              last;
            };
            cmWordRight == $_ and do {
              $self->setCurPtr( 
                $self->nextWord( $self->{curPtr} ), 
                $selectMode 
              );
              last;
            };
            cmLineStart == $_ and do {
              $self->setCurPtr( 
                $self->lineStart( $self->{curPtr} ), 
                $selectMode 
              );
              last;
            };
            cmLineEnd == $_ and do {
              $self->setCurPtr( 
                $self->lineEnd( $self->{curPtr} ), 
                $selectMode 
              );
              last;
            };
            cmLineUp == $_ and do {
              $self->setCurPtr( 
                $self->lineMove( $self->{curPtr}, -1 ), 
                $selectMode 
              );
              last;
            };
            cmLineDown == $_ and do {
              $self->setCurPtr( 
                $self->lineMove( $self->{curPtr}, 1 ), 
                $selectMode 
              );
              last;
            };
            cmPageUp == $_ and do {
              $self->setCurPtr( 
                $self->lineMove( $self->{curPtr}, 1 - $self->{size}{y} ), 
                $selectMode 
              );
              last;
            };
            cmPageDown == $_ and do {
              $self->setCurPtr(
                $self->lineMove( $self->{curPtr}, $self->{size}{y} - 1 ), 
                $selectMode
              );
              last;
            };
            cmTextStart == $_ and do { 
              $self->setCurPtr( 0, $selectMode ); 
              last; 
            };
            cmTextEnd == $_ and do {
              $self->setCurPtr( length( $self->{buffer} ), $selectMode );
              last;
            };
            cmNewLine == $_ and do {
              $self->newLine();
              last;
            };
            cmBackSpace == $_ and do {
              $self->deleteRange( 
                $self->prevChar( $self->{curPtr} ), 
                $self->{curPtr}, 
                true
              );
              last;
            };
            cmDelChar == $_ and do {
              $self->deleteRange( 
                $self->{curPtr}, 
                $self->nextChar( $self->{curPtr} ), 
                true
              );
              last;
            };
            cmDelWord == $_ and do {
              $self->deleteRange(
                $self->{curPtr}, 
                $self->nextWord( $self->{curPtr} ), 
                false
              );
              last;
            };
            cmDelStart == $_ and do {
              $self->deleteRange( 
                $self->lineStart( $self->{curPtr} ), 
                $self->{curPtr}, 
                false 
              );
              last;
            };
            cmDelEnd == $_ and do {
              $self->deleteRange( 
                $self->{curPtr}, 
                $self->lineEnd( $self->{curPtr} ), 
                false 
              );
              last;
            };
            cmDelLine == $_ and do {
              $self->deleteRange(
                $self->lineStart( $self->{curPtr} ), 
                $self->nextLine( $self->{curPtr} ), 
                false 
              );
              last;
            };
            cmInsMode == $_ and do {
              $self->toggleInsMode();
              last; 
            };
            cmStartSelect == $_ and do {
              $self->startSelect(); 
              last; 
            };
            cmHideSelect == $_ and do {
              $self->hideSelect(); 
              last; 
            };
            cmIndentMode == $_ and do {
              $self->{autoIndent} = !$self->{autoIndent};
              last;
            };
            cmClear == $_ and do { 
              $self->deleteSelect(); 
              last; 
            };
            cmCut == $_ and do {
              $self->clipCut();
              last;
            };
            cmCopy == $_ and do {
              $self->clipCopy();
              last;
            };
            cmPaste == $_ and do {
              $self->clipPaste();
              last;
            };
            cmUndo == $_ and do {
              $self->undo();
              last;
            };
            DEFAULT: {
              $self->unlock();
              return;
            }
          }
          $self->trackCursor( $centerCursor );
          $self->unlock();
        }
        last;
      }
      last;
    };

    evBroadcast == $_ and do {
      no warnings 'uninitialized';
      return 
        if $event->{message}{command} != cmScrollBarChanged;
      return 
        unless ( $event->{message}{infoPtr} == $self->{hScrollBar} ) 
            || ( $event->{message}{infoPtr} == $self->{vScrollBar} );
      $self->checkScrollBar( $event, $self->{hScrollBar}, $self->{delta}{x} );
      $self->checkScrollBar( $event, $self->{vScrollBar}, $self->{delta}{y} );
      last;
    };
  }

  $self->clearEvent( $event );
  return;
}

sub initBuffer {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{buffer} = '';
  return;
}

sub insertBuffer {    # $bool ($text, $offset, $length, $allowUndo, $selectText)
  state $sig = signature(
    method => Object,
    pos    => [Str, PositiveOrZeroInt, PositiveOrZeroInt, Bool, Bool],
  );
  my ( $self, $text, $offset, $length, $allowUndo, $selectText )
    = $sig->( @_ );
  assert ( $offset + $length <= length( $text ) );
  my $insert = substr( $text, $offset, $length );
  $self->{selecting} = false;
  my $selLen = $self->{selEnd} - $self->{selStart};
  return true if $selLen == 0 && $length == 0;

  my $delLen = 0;
  if ( $allowUndo ) {
    if ( $self->{curPtr} == $self->{selStart} ) {
      $delLen = $selLen;
    }
    elsif ( $selLen > $self->{insCount} ) {
      $delLen = $selLen - $self->{insCount};
    }
  }

  my $buf      = \$self->{buffer};
  my $deleted  = substr( $$buf, $self->{selStart}, $delLen );
  my $selLines = countLines( substr( $$buf, $self->{selStart}, $selLen ) );
  if ( $self->{curPtr} == $self->{selEnd} ) {
    if ( $allowUndo ) {
      $self->{delBuf}  = $deleted . $self->{delBuf};
      $self->{insCount} -= $selLen - $delLen;
    }
    $self->{curPtr} = $self->{selStart};
    $self->{curPos}{y} -= $selLines;
  }
  elsif ( $allowUndo ) {
    $self->{delBuf} .= $deleted;
  }
  if ( $self->{delta}{y} > $self->{curPos}{y} ) {
    $self->{delta}{y} -= $selLines;
    $self->{delta}{y} = $self->{curPos}{y}
      if $self->{delta}{y} < $self->{curPos}{y};
  }

  substr( $$buf, $self->{selStart}, $selLen, $insert );
  my $lines = countLines( $insert );
  $self->{curPtr} += $length;
  $self->{curPos}{y} += $lines;
  $self->{drawLine} = $self->{curPos}{y};
  $self->{drawPtr}  = $self->lineStart( $self->{curPtr} );
  $self->{curPos}{x} = $self->charPos( $self->{drawPtr}, $self->{curPtr} );
  $self->{selStart} = $self->{curPtr} unless $selectText;
  $self->{selEnd}   = $self->{curPtr};
  $self->{limit}{y} += $lines - $selLines;
  $self->{delta}{y} = max( 0,
    min( $self->{delta}{y}, $self->{limit}{y} - $self->{size}{y} ) );
  if ( $allowUndo ) {
    $self->{delCount} += $delLen;
    $self->{insCount} += $length;
  }
  $self->{modified} = true unless $self->isClipboard();
  $self->update( $selLines == 0 && $lines == 0 ? ufLine : ufView );
  return true;
}

sub insertFrom {    # $bool ($editor)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $editor ) = $sig->( @_ );
  my $length = $editor->{selEnd} - $editor->{selStart};
  return $self->insertBuffer(
    $editor->{buffer},
    $editor->{selStart},
    $length,
    $self->{canUndo},
    $self->isClipboard(),
  );
}

sub insertText {    # $bool ($text, $length, $selectText)
  state $sig = signature(
    method => Object,
    pos    => [Str, PositiveOrZeroInt, Bool],
  );
  my ( $self, $text, $length, $selectText ) = $sig->( @_ );
  assert ( length( $text ) == $length );
  return $self->insertBuffer(
    $text, 0, $length, $self->{canUndo}, $selectText );
}

sub scrollTo {    # void ($x, $y)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int],
  );
  my ( $self, $x, $y ) = $sig->( @_ );
  $x = max( 0, min( $x, $self->{limit}{x} - $self->{size}{x} ) );
  $y = max( 0, min( $y, $self->{limit}{y} - $self->{size}{y} ) );
  if ( $x != $self->{delta}{x} || $y != $self->{delta}{y} ) {
    $self->{delta}{x} = $x;
    $self->{delta}{y} = $y;
    $self->update( ufView );
  }
  return;
}

sub search {    # $bool ($findStr, $opts)
  state $sig = signature(
    method => Object,
    pos    => [Str, PositiveOrZeroInt],
  );
  my ( $self, $findStr, $opts ) = $sig->( @_ );
  my $len = length $findStr;
  my $pos = $self->{curPtr};
  while ( true ) {
    my $size = $self->{bufLen} - $pos;
    my $block = substr( $self->{buffer}, $self->bufPtr( $pos ) );
    my $i = $opts & efCaseSensitive
      ? scan( $block, $size, $findStr )
      : iScan( $block, $size, $findStr );
    last if $i == sfSearchFailed;

    $i += $pos;
    my $end = $i + $len;
    my $wordBreak = ( $i > 0 && $self->bufChar( $i - 1 ) =~ /\w/ )
      || ( $end != $self->{bufLen} && $self->bufChar( $end ) =~ /\w/ );
    if ( !( $opts & efWholeWordsOnly ) || !$wordBreak ) {
      $self->lock();
      $self->setSelect( $i, $end, false );
      $self->trackCursor( !$self->cursorVisible() );
      $self->unlock();
      return true;
    }
    $pos = $i + 1;
  }
  return false;
}

sub setBufSize {    # $bool ($newSize)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $newSize ) = $sig->( @_ );
  # The Perl buffer grows as needed, so bufSize is not a capacity limit.
  return true;
}

sub setCmdState {    # void ($command, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $command, $enable ) = $sig->( @_ );
  my $commands = new_TCommandSet();
  $commands += $command;
  if ( $enable && ( $self->{state} & sfActive ) ) {
    $self->enableCommands( $commands );
  }
  else {
    $self->disableCommands( $commands );
  }
  return;
}

sub setSelect {    # void ($newStart, $newEnd, $curStart)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, PositiveOrZeroInt, Bool],
  );
  my ( $self, $newStart, $newEnd, $curStart ) = $sig->( @_ );
  my $p = $curStart ? $newStart : $newEnd;

  my $flags = ufUpdate;
  if ( $newStart != $self->{selStart} || $newEnd != $self->{selEnd} ) {
    if ( $newStart != $newEnd || $self->{selStart} != $self->{selEnd} ) {
      $flags = ufView;
    }
  }

  if ( $p != $self->{curPtr} ) {
    if ( $p > $self->{curPtr} ) {
      $self->{curPos}{y} += countLines(
        substr( $self->{buffer}, $self->{curPtr}, $p - $self->{curPtr} ) );
    }
    else {
      $self->{curPos}{y} -= countLines(
        substr( $self->{buffer}, $p, $self->{curPtr} - $p ) );
    }
    $self->{curPtr}   = $p;
    $self->{drawLine} = $self->{curPos}{y};
    $self->{drawPtr}  = $self->lineStart( $p );
    $self->{curPos}{x} = $self->charPos( $self->{drawPtr}, $p );
    $self->{delCount}  = 0;
    $self->{insCount}  = 0;
  }
  $self->{selStart} = $newStart;
  $self->{selEnd}   = $newEnd;
  $self->update( $flags );
  return;
}

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );
  $self->SUPER::setState( $aState, $enable );
  if ( $aState == sfActive ) {
    $_->setState( sfVisible, $enable )
      for grep { defined } @{$self}{qw(hScrollBar vScrollBar indicator)};
    $self->updateCommands();
  }
  elsif ( $aState == sfExposed ) {
    $self->unlock() if $enable;
  }
  return;
}

sub trackCursor {    # void ($center)
  state $sig = signature(
    method => Object,
    pos    => [Bool],
  );
  my ( $self, $center ) = $sig->( @_ );
  my ( $cx, $cy ) = ( $self->{curPos}{x}, $self->{curPos}{y} );
  my ( $sx, $sy ) = ( $self->{size}{x}, $self->{size}{y} );
  if ( $center ) {
    $self->scrollTo( $cx - $sx + 1, $cy - int( $sy / 2 ) );
  }
  else {
    $self->scrollTo(
      max( $cx - $sx + 1, min( $self->{delta}{x}, $cx ) ),
      max( $cy - $sy + 1, min( $self->{delta}{y}, $cy ) ),
    );
  }
  return;
}

sub undo {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( $self->{delCount} != 0 || $self->{insCount} != 0 ) {
    $self->{selStart} = $self->{curPtr} - $self->{insCount};
    $self->{selEnd}   = $self->{curPtr};
    my $text = $self->{delBuf};
    $self->{delBuf}   = '';
    $self->{delCount} = 0;
    $self->{insCount} = 0;
    $self->insertBuffer( $text, 0, length( $text ), false, true );
  }
  return;
}

sub updateCommands {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->setCmdState( cmUndo,
    $self->{delCount} != 0 || $self->{insCount} != 0 ? true : false );
  if ( !$self->isClipboard() ) {
    $self->setCmdState( cmCut, $self->hasSelection() );
    $self->setCmdState( cmCopy, $self->hasSelection() );
    $self->setCmdState( cmPaste,
      ( defined $clipboard && $clipboard->hasSelection() ) ? true : false );
  }
  $self->setCmdState( cmClear, $self->hasSelection() );
  $self->setCmdState( cmFind, true );
  $self->setCmdState( cmReplace, true );
  $self->setCmdState( cmSearchAgain, true );
  return;
}

sub valid {    # $bool ($command)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $command ) = $sig->( @_ );
  return $self->{isValid};
}

sub charPos {    # $col ($p, $target)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, PositiveOrZeroInt],
  );
  my ( $self, $p, $target ) = $sig->( @_ );
  my $pos = 0;
  while ( $p < $target ) {
    $pos |= 7
      if $self->bufChar( $p ) eq "\t";
    $pos++;
    $p++;
  }
  return $pos;
}

sub charPtr {    # $pos ($p, $target)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Int],
  );
  my ( $self, $p, $target ) = $sig->( @_ );
  my $pos = 0;
  my $len = $self->bufLen;
  while ( $pos < $target && $p < $len && $self->bufChar( $p ) !~ /\R/ ) {
    $pos |= 7
      if $self->bufChar( $p ) eq "\t";
    $pos++;
    $p++;
  }
  $p--
    if $pos > $target;
  return $p;
}

sub clipCopy {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $res = false;
  if ( defined $clipboard && $clipboard != $self ) {
    $res = $clipboard->insertFrom( $self );
    $self->{selecting} = false;
    $self->update( ufUpdate );
  }
  return $res;
}

sub clipCut {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->deleteSelect() if $self->clipCopy();
  return;
}

sub clipPaste {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->insertFrom( $clipboard )
    if defined $clipboard && $clipboard != $self;
  return;
}

sub deleteRange {    # void ($startPtr, $endPtr, $delSelect)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, PositiveOrZeroInt, Bool],
  );
  my ( $self, $startPtr, $endPtr, $delSelect ) = $sig->( @_ );
  if ( $self->hasSelection() && $delSelect ) {
    $self->deleteSelect();
  }
  else {
    $self->setSelect( $self->{curPtr}, $endPtr, true );
    $self->deleteSelect();
    $self->setSelect( $startPtr, $self->{curPtr}, false );
    $self->deleteSelect();
  }
  return;
}

sub doUpdate {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return if $self->{updateFlags} == 0;

  $self->setCursor( $self->{curPos}{x} - $self->{delta}{x},
                    $self->{curPos}{y} - $self->{delta}{y} );
  if ( $self->{updateFlags} & ufView ) {
    $self->drawView();
  }
  elsif ( $self->{updateFlags} & ufLine ) {
    $self->drawLines( $self->{curPos}{y} - $self->{delta}{y}, 1,
      $self->lineStart( $self->{curPtr} ) );
  }
  if ( $self->{hScrollBar} ) {
    $self->{hScrollBar}->setParams( $self->{delta}{x}, 0,
      $self->{limit}{x} - $self->{size}{x}, int( $self->{size}{x} / 2 ), 1 );
  }
  if ( $self->{vScrollBar} ) {
    $self->{vScrollBar}->setParams( $self->{delta}{y}, 0,
      $self->{limit}{y} - $self->{size}{y}, $self->{size}{y} - 1, 1 );
  }
  if ( $self->{indicator} ) {
    $self->{indicator}->setValue(
      TPoint->new( x => $self->{curPos}{x}, y => $self->{curPos}{y} ),
      $self->{modified} );
  }
  if ( $self->{state} & sfActive ) {
    $self->updateCommands();
  }
  $self->{updateFlags} = 0;
  return;
}

sub doSearchReplace {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $i;
  do {
    $i = cmCancel;
    if ( !$self->search( $findStr, $editorFlags ) ) {
      my $both = efReplaceAll | efDoReplace;
      &$editorDialog( edSearchFailed )
        if ( $editorFlags & $both ) != $both;
    }
    elsif ( $editorFlags & efDoReplace ) {
      $i = cmYes;
      if ( $editorFlags & efPromptOnReplace ) {
        my $c = $self->makeGlobal( $self->{cursor} );
        $i = &$editorDialog( edReplacePrompt, $c );
      }
      if ( $i == cmYes ) {
        $self->lock();
        $self->insertText( $replaceStr, length( $replaceStr ), false );
        $self->trackCursor( false );
        $self->unlock();
      }
    }
  } while ( $i != cmCancel && ( $editorFlags & efReplaceAll ) );
  return;
}

sub drawLines {    # void ($y, $count, $linePtr)
  state $sig = signature(
    method => Object,
    pos    => [Int, Int, PositiveOrZeroInt],
  );
  my ( $self, $y, $count, $linePtr ) = $sig->( @_ );
  my $color = $self->getColor( 0x0201 );
  my $dx    = $self->{delta}{x};
  my $width = $self->{size}{x};
  while ( $count-- > 0 ) {
    my $b = TDrawBuffer->new();
    $self->formatLine( $b, $linePtr, $dx + $width, $color );
    alias: $b = sub { \@_ }->( @$b[ $dx .. $#$b ] ) if $dx;
    $self->writeBuf( 0, $y, $width, 1, $b );
    $linePtr = $self->nextLine( $linePtr );
    $y++;
  }
  return;
}

sub find {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $findRec = TFindDialogRec->new(
    find    => $findStr, 
    options => $editorFlags 
  );
  if ( &$editorDialog( edFind, $findRec ) != cmCancel ) {
    $findStr     = $findRec->find;
    $editorFlags = $findRec->options & ~efDoReplace;
    $self->doSearchReplace();
  }
  return;
}

sub getMousePtr {    # $index ($where)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $where ) = $sig->( @_ );
  my $mouse = $self->makeLocal( $where );
  my $mx = max( 0, min( $mouse->{x}, $self->{size}{x} - 1 ) );
  my $my = max( 0, min( $mouse->{y}, $self->{size}{y} - 1 ) );
  return $self->charPtr(
    lineMove( $self, $self->{drawPtr},
      $my + $self->{delta}{y} - $self->{drawLine} ),
    $mx + $self->{delta}{x} );
}

sub hasSelection {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{selStart} != $self->{selEnd};
}

sub hideSelect {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{selecting} = false;
    $self->setSelect( $self->{curPtr}, $self->{curPtr}, false );
  return;
}

sub isClipboard {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return ( defined $clipboard && $clipboard == $self ) ? true : false;
}

sub lineMove {    # $pos ($p, $count)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Int],
  );
  my ( $self, $p, $count ) = $sig->( @_ );
  my $i   = $p;
  $p      = $self->lineStart( $p );
  my $pos = $self->charPos( $p, $i );
  while ( $count != 0 ) {
    $i = $p;
    if ( $count < 0 ) {
      $p = $self->prevLine( $p );
      $count++;
    }
    else {
      $p = $self->nextLine( $p );
      $count--;
    }
  }
  $p = $self->charPtr( $p, $pos )
    if $p != $i;
  return $p;
}

sub lock {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{lockCount}++;
  return;
}

sub newLine {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $p = $self->lineStart( $self->{curPtr} );
  my $i = $p;
  while ( $i < $self->{curPtr}
    && substr( $self->{buffer}, $i, 1 ) =~ /[ \t]/ ) {
    $i++;
  }
  $self->insertText( $INPUT_RECORD_SEPARATOR,
    length( $INPUT_RECORD_SEPARATOR ), false );
  if ( $self->{autoIndent} ) {
    $self->insertText( substr( $self->{buffer}, $p, $i - $p ),
      $i - $p, false );
  }
  return;
}

sub nextWord {    # $pos ($p)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $p ) = $sig->( @_ );
  my $len = $self->bufLen;
  while ( $p < $len && $self->bufChar( $p ) =~ /\w/ ) {
    $p = $self->nextChar( $p );
  }
  while ( $p < $len && $self->bufChar( $p ) !~ /\w/ ) {
    $p = $self->nextChar( $p );
  }
  return $p;
}

sub prevWord {    # $pos ($p)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $p ) = $sig->( @_ );
  while ( $p > 0 && $self->bufChar( $self->prevChar( $p ) ) !~ /\w/ ) {
    $p = $self->prevChar( $p );
  }
  while ( $p > 0 && $self->bufChar( $self->prevChar( $p ) ) =~ /\w/ ) {
    $p = $self->prevChar( $p );
  }
  return $p;
}

sub replace {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $replaceRec = TReplaceDialogRec->new(
    find    => $findStr,
    replace => $replaceStr,
    options => $editorFlags,
  );
  if ( &$editorDialog( edReplace, $replaceRec ) != cmCancel ) {
    $findStr     = $replaceRec->find;
    $replaceStr  = $replaceRec->replace;
    $editorFlags = $replaceRec->options | efDoReplace;
    $self->doSearchReplace();
  }
  return;
}

sub setBufLen {    # void ($length)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $length ) = $sig->( @_ );
  $self->{bufLen}   = $length;
  $self->{gapLen}   = 0;
  $self->{selStart} = 0;
  $self->{selEnd}   = 0;
  $self->{curPtr}   = 0;
  $self->{delta}{x} = 0;
  $self->{delta}{y} = 0;
  %{ $self->{curPos} } = %{ $self->{delta} };
  $self->{limit}{x} = maxLineLength;
  $self->{limit}{y} = countLines( $self->{buffer}, $self->{bufLen} ) + 1;
  $self->{drawLine} = 0;
  $self->{drawPtr}  = 0;
  $self->{delCount} = 0;
  $self->{insCount} = 0;
  $self->{delBuf}   = '';
  $self->{modified} = false;
  $self->update( ufView );
  return;
}

sub setCurPtr {    # void ($p, $selectMode)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Int],
  );
  my ( $self, $p, $selectMode ) = $sig->( @_ );
  my $anchor;
  if ( ( $selectMode & smExtend ) == 0 ) {
    $anchor = $p;
  }
  elsif ( $self->{curPtr} == $self->{selStart} ) {
    $anchor = $self->{selEnd};
  }
  else {
    $anchor = $self->{selStart};
  }

  if ( $p < $anchor ) {
    if ( $selectMode & smDouble ) {
      $p      = $self->prevLine( $self->nextLine( $p ) );
      $anchor = $self->nextLine( $self->prevLine( $anchor ) );
    }
    $self->setSelect( $p, $anchor, true );
  }
  else {
    if ( $selectMode & smDouble ) {
      $p      = $self->nextLine( $p );
      $anchor = $self->prevLine( $self->nextLine( $anchor ) );
    }
    $self->setSelect( $anchor, $p, false );
  }
  return;
}

sub startSelect {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->hideSelect();
  $self->{selecting} = true;
  return;
}

sub toggleInsMode {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{overwrite} = !$self->{overwrite};
  $self->setState( sfCursorIns, !$self->getState( sfCursorIns ) );
  return;
}

sub unlock {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( $self->{lockCount} > 0 ) {
    $self->{lockCount}--;
    $self->doUpdate() if $self->{lockCount} == 0;
  }
  return;
}

sub update {    # void ($aFlags)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $aFlags ) = $sig->( @_ );
  $self->{updateFlags} |= $aFlags;
  $self->doUpdate() if $self->{lockCount} == 0;
  return;
}

sub checkScrollBar {    # void ($event, $p, $d)
  no warnings 'uninitialized';
  state $sig = signature(
    method => Object,
    pos    => [Object, Maybe[Object], Int],
  );
  my ( $self, $event, $p, $d ) = $sig->( @_ );
  alias: for $d ( $_[3] ) {
  if ( $event->{message}{infoPtr} == $p && $p->{value} != $d ) {
    $d = $p->{value};
    $self->update( ufView );
  }
  return;
  } #/ alias: for $d
}

sub bufLen {    # $len ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{bufLen} = length( $self->{buffer} ) // 0;
  return $self->{bufLen};
}

sub write :method {    # void ($os)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $os ) = $sig->( @_ );
  $self->SUPER::write( $os );
  $os->put(
    $self->{hScrollBar}, $self->{vScrollBar}, $self->{indicator},
    $self->{bufSize},    $self->{canUndo},
  );

  return;
}

sub read :method {    # $self ($is)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $is ) = $sig->( @_ );
  $self->SUPER::read( $is );
  $self->{hScrollBar} = $is->get();
  $self->{vScrollBar} = $is->get();
  $self->{indicator}  = $is->get();
  $self->{bufSize}    = $is->get();
  $self->{canUndo}    = $is->get();

  $self->{selecting}  = false;
  $self->{overwrite}  = false;
  $self->{autoIndent} = false;
  $self->{lockCount}  = 0;
  $self->{keyState}   = 0;
  $self->initBuffer();
  $self->{isValid}    = true;
  $self->{lockCount}  = 0;
  $self->lock();
  $self->setBufLen( 0 );

  return $self;
}

sub build {    # $obj ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  assert ( Storable::is_retrieving );
  return $class->new(
    bounds     => TRect->new(),
    hScrollBar => undef,
    vScrollBar => undef,
    indicator  => undef,
    bufSize    => 0,
  );
}

1

__END__

=pod

=head1 NAME

TUI::Editors::Editor - multi-line text editor view

=head1 HIERARCHY

  TObject
    TView
      TEditor

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Editors;

  my $editor = new_TEditor(
    TRect->new( ax => 0, ay => 0, bx => 80, by => 24 ),
    undef,
    undef,
    undef,
    1024,
  );

  $editor->insertText( 'Hello, world!', 13, 0 );

=head1 DESCRIPTION

C<TEditor> is a view that edits a text buffer. Lines may end with CR, LF or
CR LF (a CR LF pair counts as one line break for cursor movement). The buffer
is a native Perl string; positions are character positions.

Undo, clipboard (C<clipCopy>, C<clipCut>, C<clipPaste>) and search and replace
(C<find>, C<replace>, C<search>) are available. The C<bufSize> argument is stored but not enforced, because the
Perl buffer grows as needed.

The buffer and line helpers (C<bufChar>, C<bufPtr>, C<formatLine>, C<lineEnd>,
C<lineStart>, C<nextChar>, C<nextLine>, C<prevChar>, C<prevLine>) are documented
in L<TUI::Editors::Editor::Edits>.

=head1 VARIABLES

The following global variables hold the search, replace and clipboard state
shared by all editors.

=head2 $clipboard

The editor that holds the clipboard contents.

=head2 $editorDialog

Dialog callback, a dummy until TEditorDialog is ported.

=head2 $editorFlags

Search and replace option flags.

=head2 $findStr

Last search text.

=head2 $replaceStr

Last replacement text.

=head1 ATTRIBUTES

=head2 buffer

Text buffer (I<Str>).

=head2 bufSize

Size of the buffer (I<Int>). It is stored but not enforced, because the Perl
buffer grows as needed.

=head2 hScrollBar

Horizontal scroll bar (L<TScrollBar|TUI::Views::ScrollBar> or C<undef>).

=head2 vScrollBar

Vertical scroll bar (L<TScrollBar|TUI::Views::ScrollBar> or C<undef>).

=head2 indicator

Position indicator (L<TIndicator|TUI::Editors::Indicator> or C<undef>).

=head2 selStart

Start of the selection (I<PositiveOrZeroInt>).

=head2 selEnd

End of the selection (I<PositiveOrZeroInt>).

=head2 curPtr

Current cursor position (I<PositiveOrZeroInt>).

=head2 curPos

Current cursor position as a point (L<TPoint|TUI::Objects::Point>).

=head2 delta

Delta for scrolling (L<TPoint|TUI::Objects::Point>).

=head2 limit

Limit for scrolling (L<TPoint|TUI::Objects::Point>).

=head2 drawLine

Line to draw (I<Int>).

=head2 drawPtr

Draw pointer (I<PositiveOrZeroInt>).

=head2 delCount

Delete count (I<PositiveOrZeroInt>).

=head2 insCount

Insert count (I<Int>).

=head2 isValid

Indicates whether the editor is valid (I<Bool>).

=head2 canUndo

Indicates whether undo is enabled (I<Bool>).

=head2 modified

Indicates whether the buffer has been modified (I<Bool>).

=head2 selecting

Indicates whether text is being selected (I<Bool>).

=head2 overwrite

Indicates whether overwrite mode is enabled (I<Bool>).

=head2 autoIndent

Indicates whether auto-indent is enabled (I<Bool>).

=head2 lockCount

Lock count (I<PositiveOrZeroInt>).

=head2 updateFlags

Update flags (I<PositiveOrZeroInt>).

=head2 keyState

Key state (I<Int>).

=head1 CONSTRUCTOR

=head2 new

  my $editor = TEditor->new(
    bounds     => $bounds,
    hScrollBar => $hScrollBar,    # or undef
    vScrollBar => $vScrollBar,    # or undef
    indicator  => $indicator,     # or undef,
    bufSize    => $bufSize,
  );

Creates a new editor with the specified buffer size.

=over

=item bounds

Bounding rectangle of the view (L<TRect|TUI::Objects::Rect>).

=item hScrollBar

Optional horizontal scroll bar (L<TScrollBar|TUI::Views::ScrollBar> or 
C<undef>).

=item vScrollBar

Optional vertical scroll bar (L<TScrollBar|TUI::Views::ScrollBar> or C<undef>).

=item indicator

Optional position indicator (L<TIndicator|TUI::Editors::Indicator> or C<undef>).

=item bufSize

Buffer size (I<PositiveOrZeroInt>).

=back

=head2 new_TEditor

  my $editor = new_TEditor(
    $bounds,
    $hScrollBar,    # or undef
    $vScrollBar,    # or undef
    $indicator,     # or undef
    $bufSize,
  );

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 bufLen

  my $len = $editor->bufLen;

Returns the length of the buffer in characters.

=head2 changeBounds

  $editor->changeBounds($bounds);

Sets new bounds and clamps the scroll position to the new size.

=head2 charPos

  my $col = $editor->charPos($p, $target);

Returns the display column of the character at buffer position C<$p> when the
line is read up to C<$target>. Tabs advance to the next tab stop.

=head2 charPtr

  my $pos = $editor->charPtr($p, $target);

Returns the buffer position of the display column C<$target> on the line that
starts at C<$p>.

=head2 checkScrollBar

  $editor->checkScrollBar($event, $scrollBar, $value);

Checks whether the scroll bar C<$scrollBar> was moved by the event C<$event>.
If so, C<$value> is set to the new position of the scroll bar and the view is
marked for redrawing. C<$value> is passed by alias, so pass a variable, not a
literal.

=head2 clipCopy

  my $ok = $editor->clipCopy;

Copies the selection into the clipboard editor. Returns false if no clipboard
is set or if this editor is the clipboard itself.

=head2 clipCut

  $editor->clipCut;

Copies the selection to the clipboard and deletes it.

=head2 clipPaste

  $editor->clipPaste;

Inserts the contents of the clipboard at the cursor.

=head2 convertEvent

  $editor->convertEvent($event);

Converts key events into command events, including the Ctrl-Q quick keys and
the Ctrl-K block keys.

=head2 cursorVisible

  my $bool = $editor->cursorVisible;

Returns true if the cursor lies inside the visible part of the editor.

=head2 deleteRange

  $editor->deleteRange($startPtr, $endPtr, $delSelect);

Deletes the text between the two buffer positions. If C<$delSelect> is true,
the selection is cleared as well.

=head2 deleteSelect

  $editor->deleteSelect;

Deletes the selected text.

=head2 doneBuffer

  $editor->doneBuffer;

Releases the buffer; the buffer is set to C<undef>.

=head2 doSearchReplace

  $editor->doSearchReplace;

Performs a search for C<$findStr> with the options in C<$editorFlags>. If the
replace options are set, it also replaces the match, asking through
C<$editorDialog> when prompting is enabled. It repeats while C<efReplaceAll>
is set.

=head2 doUpdate

  $editor->doUpdate;

Redraws the parts of the view marked in C<updateFlags>, updates the scroll bars
and the indicator, and clears the flags. C<update> calls it when the editor is
not locked.

=head2 draw

  $editor->draw;

Draws the visible part of the editor.

=head2 drawLines

  $editor->drawLines($y, $count, $linePtr);

Draws C<$count> lines starting at row C<$y> of the view. The first line starts
at buffer position C<$linePtr>.

=head2 find

  $editor->find;

Asks the user for a search string and searches for it.

=head2 getMousePtr

  my $index = $editor->getMousePtr($where);

Returns the buffer position under the mouse location C<$where>.

=head2 getPalette

  my $palette = $editor->getPalette;

Returns the palette used by the editor.

=head2 handleEvent

  $editor->handleEvent($event);

Handles keyboard, mouse and command events.

=head2 hasSelection

  my $bool = $editor->hasSelection;

Returns true if some text is selected.

=head2 hideSelect

  $editor->hideSelect;

Clears the selection and keeps the cursor at its position.

=head2 initBuffer

  $editor->initBuffer;

Initializes an empty buffer.

=head2 insertBuffer

  my $ok = $editor->insertBuffer(
    $text, $offset, $length, $allowUndo, $selectText);

Inserts the C<$length> characters of C<$text> starting at C<$offset> at the
cursor. C<assert> checks that the slice lies within C<$text>. If
C<$selectText> is true, the inserted text becomes the selection.

=head2 insertFrom

  my $ok = $editor->insertFrom($editor);

Inserts the selected text of another editor at the cursor.

=head2 insertText

  my $ok = $editor->insertText($text, $length, $selectText);

Inserts C<$text> at the cursor, using undo information if C<canUndo> is set.
C<$length> is the length of C<$text>, which is checked with C<assert>.

=head2 isClipboard

  my $bool = $editor->isClipboard;

Returns true if this editor is the clipboard editor.

=head2 lineMove

  my $pos = $editor->lineMove($p, $count);

Moves C<$count> lines up or down from buffer position C<$p>, keeping the
column, and returns the new position.

=head2 lock

  $editor->lock;

Increments the lock count. See C<unlock>.

=head2 newLine

  $editor->newLine;

Inserts a line break at the cursor, using the indentation of the current line
when auto-indent is on.

=head2 nextWord

  my $pos = $editor->nextWord($p);

Returns the position of the start of the next word after C<$p>.

=head2 prevWord

  my $pos = $editor->prevWord($p);

Returns the position of the start of the previous word before C<$p>.

=head2 replace

  $editor->replace;

Asks the user for a search and replace string and replaces the matches.

=head2 scrollTo

  $editor->scrollTo($x, $y);

Scrolls the visible area so that the position C<($x, $y)> is shown, within the
limits of the buffer.

=head2 search

  my $bool = $editor->search($findStr, $opts);

Searches for C<$findStr> from the cursor position. C<$opts> is a bit mask of
search options. Returns true if a match was found and selected.

=head2 setBufLen

  $editor->setBufLen($length);

Sets the buffer length and resets the cursor, the selection and the
scroll position.

=head2 setBufSize

  my $bool = $editor->setBufSize($newSize);

Stores the buffer size. It always returns true, because the buffer is not
limited by a capacity.

=head2 setCmdState

  $editor->setCmdState($command, $enable);

Enables or disables a single command. Commands are enabled only while the
editor is active (C<sfActive>); otherwise they are disabled. Use this instead
of the C<TView> variant, which takes a command set.

=head2 setCurPtr

  $editor->setCurPtr($p, $selectMode);

Moves the cursor to buffer position C<$p>. If C<$selectMode> is true, the
selection is extended.

=head2 setSelect

  $editor->setSelect($newStart, $newEnd, $curStart);

Sets the selection range and the cursor. Moving the cursor resets the undo
counters.

=head2 setState

  $editor->setState($aState, $enable);

Sets or clears a state flag. Changing C<sfActive> shows or hides the scroll
bars and the indicator and updates the commands. Enabling C<sfExposed>
unlocks the editor.

=head2 shutDown

  $editor->shutDown;

Releases the buffer and shuts down the view.

=head2 startSelect

  $editor->startSelect;

Starts a selection at the cursor position.

=head2 toggleInsMode

  $editor->toggleInsMode;

Toggles between insert and overwrite mode.

=head2 trackCursor

  $editor->trackCursor($center);

Scrolls the view so that the cursor is visible. If C<$center> is true, the
cursor is centered.

=head2 undo

  $editor->undo;

Undoes the last change, if undo is enabled.

=head2 unlock

  $editor->unlock;

Decrements the lock count and updates the view when it reaches zero.

=head2 update

  $editor->update($aFlags);

Marks the view for redrawing according to the update flags C<$aFlags>.

=head2 updateCommands

  $editor->updateCommands;

Enables or disables the editing commands according to the editor state.

=head2 valid

  my $bool = $editor->valid($command);

Returns the validity flag of the editor.

=head1 STRUCTURES

C<TFindDialogRec> and C<TReplaceDialogRec> are the data records of the search
and replace dialogs. They are built with L<Class::Struct> as array references,
and they are used by the C<find> and C<replace> methods.

=over

=item * C<TFindDialogRec> has the attributes C<find> (the search text) and
C<options> (the editor flags).

=item * C<TReplaceDialogRec> has the attributes C<find> (the search text),
C<replace> (the replacement text) and C<options> (the editor flags).

=back

  my $findRec = TFindDialogRec->new( find => 'text', options => 0 );

=head1 SEE ALSO

L<TUI::Editors>,
L<TUI::Editors::Editor::Edits>,
L<TView|TUI::Views::View>

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
