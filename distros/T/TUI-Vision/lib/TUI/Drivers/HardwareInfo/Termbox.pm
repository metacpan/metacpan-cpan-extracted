package TUI::Drivers::HardwareInfo::Termbox;
# ABSTRACT: Termbox driver for TUI::Drivers::HardwareInfo

# -------------------------------------------------------------------------
# Boilerplate
# -------------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

# -------------------------------------------------------------------------
# Import modules
# -------------------------------------------------------------------------

use constant PERL_ONLY => ( exists $ENV{PERL_ONLY} && $ENV{PERL_ONLY} )
  || not eval { require Termbox; Termbox->VERSION(2); 1 };

use PerlX::Assert::PP;
use English qw( -no_match_vars );
use Errno qw( EINTR );
use List::Util qw( min max );
use Scalar::Util qw(
  blessed
  looks_like_number
  readonly
);
use if PERL_ONLY, 'Termbox::PP';
use Termbox qw( :all );
use Time::HiRes qw( time );
use TUI::toolkit::boolean;

use TUI::Drivers::Const qw(
  evCommand
  evKeyDown
  :smXXXX
  :kbXXXX
  :meXXXX
  :mbXXXX
);
use TUI::Drivers::ScreenCharacter;
use TUI::Drivers::ColorAttr;
use TUI::Drivers::Colors qw(
  BIOStoXTerm16
  RGBtoXTerm16
  RGBtoXTerm256
  XTerm256toXTerm16
);
use TUI::Drivers::ScreenCell;
use TUI::Memory qw(
  disposeCache
  newCache
);
use TUI::Views::Const qw( cmScreenChanged );

# -------------------------------------------------------------------------
# Define constants
# -------------------------------------------------------------------------

use constant TB_NONE => 0;

# Do not delay too much on ESC key presses, as the Alt modifier works well
# in most modern terminals. Still, this delay helps Termbox::PP distinguish
# special key sequences.
use constant ESCDELAY => exists $ENV{ESCDELAY} ? 0+ $ENV{ESCDELAY} : 100;

# The Termbox FFI version doesn't define all keys and attributes, 
# so we define it here for use in the translation tables.
use if !PERL_ONLY, constant => {
  TB_KEY_CTRL_A     => 0x01,
  TB_KEY_CTRL_B     => 0x02,
  TB_KEY_CTRL_C     => 0x03,
  TB_KEY_CTRL_D     => 0x04,
  TB_KEY_CTRL_E     => 0x05,
  TB_KEY_CTRL_F     => 0x06,
  TB_KEY_CTRL_G     => 0x07,
  TB_KEY_BACKSPACE  => 0x08,
  TB_KEY_CTRL_H     => 0x08,
  TB_KEY_TAB        => 0x09,
  TB_KEY_CTRL_I     => 0x09,
  TB_KEY_CTRL_J     => 0x0a,
  TB_KEY_CTRL_K     => 0x0b,
  TB_KEY_CTRL_L     => 0x0c,
  TB_KEY_ENTER      => 0x0d,
  TB_KEY_CTRL_M     => 0x0d,
  TB_KEY_CTRL_N     => 0x0e,
  TB_KEY_CTRL_O     => 0x0f,
  TB_KEY_CTRL_P     => 0x10,
  TB_KEY_CTRL_Q     => 0x11,
  TB_KEY_CTRL_R     => 0x12,
  TB_KEY_CTRL_S     => 0x13,
  TB_KEY_CTRL_T     => 0x14,
  TB_KEY_CTRL_U     => 0x15,
  TB_KEY_CTRL_V     => 0x16,
  TB_KEY_CTRL_W     => 0x17,
  TB_KEY_CTRL_X     => 0x18,
  TB_KEY_CTRL_Y     => 0x19,
  TB_KEY_CTRL_Z     => 0x1a,
  TB_KEY_ESC        => 0x1b,
  TB_KEY_SPACE      => 0x20,
  TB_KEY_BACKSPACE2 => 0x7f,
  # That's strange, the following attributes do not rely on truecolor
  TB_HI_BLACK       => 0x2000,
  TB_BRIGHT         => 0x4000,
};

BEGIN {
  *TB_OUTPUT_TRUECOLOR = sub (){ 5 }
    unless defined &TB_OUTPUT_TRUECOLOR;
}

# -------------------------------------------------------------------------
# Declare global variables
# -------------------------------------------------------------------------

our $insertState  = true;
our $platform     = '';
our $pendingEvent = 0;

# Track mouse button state.
our $lastButtons = 0;

# -------------------------------------------------------------------------
# Import global variables
# -------------------------------------------------------------------------

use vars qw(
  $ctrlBreakHit
);
{
  no warnings 'once';
  *ctrlBreakHit = \$TUI::Drivers::SystemError::ctrlBreakHit;
}

# -------------------------------------------------------------------------
# Local variables
# -------------------------------------------------------------------------

my $screenMode  = 0;
my $outputMode  = 0;
my $initialized = false;
my $cursorSize  = 15;
my @lastSize    = ( 0, 0 );
my $tb_event    = Termbox::Event->new();

# Codepage 437 to Unicode translation map.
my @CP437_TO_UTF8 = (
  ord "\x{2007}", ord "\x{263a}", ord "\x{263b}", ord "\x{2665}",
  ord "\x{2666}", ord "\x{2663}", ord "\x{2660}", ord "\x{2022}",
  ord "\x{25d8}", ord "\x{25cb}", ord "\x{25d9}", ord "\x{2642}",
  ord "\x{2640}", ord "\x{266a}", ord "\x{266b}", ord "\x{263c}",
  # Termius has 25b6 and 25c0 here, which are better unicode equivalents.
  # ord "\x{25ba}", ord "\x{25c4}", ord "\x{2195}", ord "\x{203c}",
  ord "\x{25b6}", ord "\x{25c0}", ord "\x{2195}", ord "\x{203c}",
  ord "\x{00b6}", ord "\x{00a7}", ord "\x{25ac}", ord "\x{21a8}",
  ord "\x{2191}", ord "\x{2193}", ord "\x{2192}", ord "\x{2190}",
  ord "\x{221f}", ord "\x{2194}", ord "\x{25b2}", ord "\x{25bc}",
  ord "\x{0020}", ord "\x{0021}", ord "\x{0022}", ord "\x{0023}",
  ord "\x{0024}", ord "\x{0025}", ord "\x{0026}", ord "\x{0027}",
  ord "\x{0028}", ord "\x{0029}", ord "\x{002a}", ord "\x{002b}",
  ord "\x{002c}", ord "\x{002d}", ord "\x{002e}", ord "\x{002f}",
  ord "\x{0030}", ord "\x{0031}", ord "\x{0032}", ord "\x{0033}",
  ord "\x{0034}", ord "\x{0035}", ord "\x{0036}", ord "\x{0037}",
  ord "\x{0038}", ord "\x{0039}", ord "\x{003a}", ord "\x{003b}",
  ord "\x{003c}", ord "\x{003d}", ord "\x{003e}", ord "\x{003f}",
  ord "\x{0040}", ord "\x{0041}", ord "\x{0042}", ord "\x{0043}",
  ord "\x{0044}", ord "\x{0045}", ord "\x{0046}", ord "\x{0047}",
  ord "\x{0048}", ord "\x{0049}", ord "\x{004a}", ord "\x{004b}",
  ord "\x{004c}", ord "\x{004d}", ord "\x{004e}", ord "\x{004f}",
  ord "\x{0050}", ord "\x{0051}", ord "\x{0052}", ord "\x{0053}",
  ord "\x{0054}", ord "\x{0055}", ord "\x{0056}", ord "\x{0057}",
  ord "\x{0058}", ord "\x{0059}", ord "\x{005a}", ord "\x{005b}",
  ord "\x{005c}", ord "\x{005d}", ord "\x{005e}", ord "\x{005f}",
  ord "\x{0060}", ord "\x{0061}", ord "\x{0062}", ord "\x{0063}",
  ord "\x{0064}", ord "\x{0065}", ord "\x{0066}", ord "\x{0067}",
  ord "\x{0068}", ord "\x{0069}", ord "\x{006a}", ord "\x{006b}",
  ord "\x{006c}", ord "\x{006d}", ord "\x{006e}", ord "\x{006f}",
  ord "\x{0070}", ord "\x{0071}", ord "\x{0072}", ord "\x{0073}",
  ord "\x{0074}", ord "\x{0075}", ord "\x{0076}", ord "\x{0077}",
  ord "\x{0078}", ord "\x{0079}", ord "\x{007a}", ord "\x{007b}",
  ord "\x{007c}", ord "\x{007d}", ord "\x{007e}", ord "\x{2302}",
  ord "\x{00c7}", ord "\x{00fc}", ord "\x{00e9}", ord "\x{00e2}",
  ord "\x{00e4}", ord "\x{00e0}", ord "\x{00e5}", ord "\x{00e7}",
  ord "\x{00ea}", ord "\x{00eb}", ord "\x{00e8}", ord "\x{00ef}",
  ord "\x{00ee}", ord "\x{00ec}", ord "\x{00c4}", ord "\x{00c5}",
  ord "\x{00c9}", ord "\x{00e6}", ord "\x{00c6}", ord "\x{00f4}",
  ord "\x{00f6}", ord "\x{00f2}", ord "\x{00fb}", ord "\x{00f9}",
  ord "\x{00ff}", ord "\x{00d6}", ord "\x{00dc}", ord "\x{00a2}",
  ord "\x{00a3}", ord "\x{00a5}", ord "\x{20a7}", ord "\x{0192}",
  ord "\x{00e1}", ord "\x{00ed}", ord "\x{00f3}", ord "\x{00fa}",
  ord "\x{00f1}", ord "\x{00d1}", ord "\x{00aa}", ord "\x{00ba}",
  ord "\x{00bf}", ord "\x{2310}", ord "\x{00ac}", ord "\x{00bd}",
  ord "\x{00bc}", ord "\x{00a1}", ord "\x{00ab}", ord "\x{00bb}",
  ord "\x{2591}", ord "\x{2592}", ord "\x{2593}", ord "\x{2502}",
  ord "\x{2524}", ord "\x{2561}", ord "\x{2562}", ord "\x{2556}",
  ord "\x{2555}", ord "\x{2563}", ord "\x{2551}", ord "\x{2557}",
  ord "\x{255d}", ord "\x{255c}", ord "\x{255b}", ord "\x{2510}",
  ord "\x{2514}", ord "\x{2534}", ord "\x{252c}", ord "\x{251c}",
  ord "\x{2500}", ord "\x{253c}", ord "\x{255e}", ord "\x{255f}",
  ord "\x{255a}", ord "\x{2554}", ord "\x{2569}", ord "\x{2566}",
  ord "\x{2560}", ord "\x{2550}", ord "\x{256c}", ord "\x{2567}",
  ord "\x{2568}", ord "\x{2564}", ord "\x{2565}", ord "\x{2559}",
  ord "\x{2558}", ord "\x{2552}", ord "\x{2553}", ord "\x{256b}",
  ord "\x{256a}", ord "\x{2518}", ord "\x{250c}", ord "\x{2588}",
  ord "\x{2584}", ord "\x{258c}", ord "\x{2590}", ord "\x{2580}",
  ord "\x{03b1}", ord "\x{00df}", ord "\x{0393}", ord "\x{03c0}",
  ord "\x{03a3}", ord "\x{03c3}", ord "\x{00b5}", ord "\x{03c4}",
  ord "\x{03a6}", ord "\x{0398}", ord "\x{03a9}", ord "\x{03b4}",
  ord "\x{221e}", ord "\x{03c6}", ord "\x{03b5}", ord "\x{2229}",
  ord "\x{2261}", ord "\x{00b1}", ord "\x{2265}", ord "\x{2264}",
  ord "\x{2320}", ord "\x{2321}", ord "\x{00f7}", ord "\x{2248}",
  ord "\x{00b0}", ord "\x{2219}", ord "\x{00b7}", ord "\x{221a}",
  ord "\x{207f}", ord "\x{00b2}", ord "\x{25a0}", ord "\x{00a0}",
);
my @UTF8_TO_CP437 = map { chr } @CP437_TO_UTF8;

# Key Event conversion
my (
  $convertCharCode,
  $convertKeyCode,
);

# Attribute conversion
my $TB_ATTR;
my (
  $convertColor,
  $convertNoColor,
  $convertIndexed8,
  $convertIndexed16,
  $convertIndexed256,
  $convertDirect,
);

# -------------------------------------------------------------------------
# Initialization and cleanup
# -------------------------------------------------------------------------

INIT {
  if ( eval { require Perl::OSType; 1 } ) {
    $platform = Perl::OSType::os_type( $OSNAME );
  } elsif ( $OSNAME eq 'MSWin32' ) {
    $platform = 'Windows';
  }
  $platform ||= 'Unix';
  __PACKAGE__->resume();
}

sub resume {     # void ($class)
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( $class and !ref $class );

  return if $initialized;
  newCache( $TB_ATTR, 256 );

  # https://github.com/neovim/neovim/issues/36635
  $ENV{TERM} //= 'xterm-256color' if $^O eq 'MSWin32';

  # Initialize Termbox and set the input/output modes.
  my $err = tb_init();
  return if $err != TB_OK;
  $err = tb_set_input_mode( TB_INPUT_ALT | TB_INPUT_MOUSE );
  return if $err != TB_OK;
  $outputMode = $class->getColorCount() >= 16
              ? TB_OUTPUT_256 
              : TB_OUTPUT_NORMAL;
  $err = tb_set_output_mode( $outputMode );
  return if $err != TB_OK;
  my $cols = tb_width();
  return if $cols <= 0;
  my $rows = tb_height();
  return if $rows <= 0;

  @lastSize = ( $cols, $rows );

  # NOTE: The following workaround for detecting a single TB_KEY_ESC relies 
  # on deprecated function tb_set_func() and Termbox::PP internals. 
  # The tb_set_func() API itself is backend-independent, but the access to 
  # raw input buffer is currently only available in the PP backend.
  if ( PERL_ONLY ) {
    no warnings 'deprecated';
    $err = tb_set_func( TB_FUNC_EXTRACT_PRE, sub {
      my ( $event, $consumed_ref ) = @_;

      state $esc_seen_at;
      if ( $Termbox::global->{inbuf} eq "\e" ) {
        my $now = int(( time() - $BASETIME ) * 1000);
        $esc_seen_at //= $now;
        my $elapsed = $now - $esc_seen_at;

        return TB_ERR_NEED_MORE
          if $elapsed < ESCDELAY;

        $$consumed_ref = 1;

        $event->{type} = TB_EVENT_KEY;
        $event->{mod}  = TB_NONE;
        $event->{key}  = TB_KEY_ESC;
        $event->{ch}   = 0;

        $esc_seen_at = undef;
        return TB_OK;
      }
      $esc_seen_at = undef;
      return TB_ERR;
    });
    return tb_strerror( $err ) if $err != TB_OK;
  }

  $initialized = true;
  return;
}

END {
  __PACKAGE__->suspend();
}

sub suspend {    # void ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );

  return unless $initialized;

  # Restore the cursor style on exit
  # https://unix.stackexchange.com/q/697650
  {
    my $term = $ENV{TERM} // '';
    if ( $term eq 'linux' ) {
      tb_send( $_ = "\x1B[?0c", bytes::length( $_ ) );
    } elsif ( $term ) {
      tb_send( $_ = "\x1B[0 q", bytes::length( $_ ) );
    }
  }
  tb_set_func( TB_FUNC_EXTRACT_PRE, undef ) if PERL_ONLY;
  tb_shutdown();

  disposeCache( $TB_ATTR );
  $initialized = false;
  return;
}

# -------------------------------------------------------------------------
# General system functions
# -------------------------------------------------------------------------

sub getTickCount {    # $ticks ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );
  # Return Turbo Vision compatible clock ticks (~18.2 Hz).
  return int( ( time() - $BASETIME ) * 1000 / 55 );
}

sub getPlatform {     # $osname ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );
  return $platform;
}

# -------------------------------------------------------------------------
# Caret functions
# -------------------------------------------------------------------------

sub setCaretSize {    # void ($class, $size)
  my ( $class, $size ) = @_;
  assert ( @_ == 2 );
  assert ( $class and !ref $class );
  assert ( looks_like_number $size );
  assert ( $initialized );
  if ( $size <= 0 ) {
    $cursorSize = 0;    # hidden
    tb_hide_cursor();
  } 
  elsif ( $size != $cursorSize ) {
    $cursorSize = max( 0, min( $size, 100 ) );

    my $term = $ENV{TERM} // '';
    if ( $term eq 'linux' ) {
      # Linux VGA console cursor style
      # https://unix.stackexchange.com/a/92743
      my $raw = sprintf(
        "\x1B[?%dc",
        2 + int( ( $cursorSize - 1 ) * 4 / 99 + 0.5 )
      );
      tb_send( $raw, bytes::length( $raw ) );
    }
    elsif ( $term ) {
      # DECSCUSR (DEC Set Cursor Style)
      # https://unix.stackexchange.com/a/597558
      my $raw;
      if ( $cursorSize < 50 ) {
        $raw = "\x1B[3 q";    # blinking underline
      }
      elsif ( $cursorSize < 100 ) {
        $raw = "\x1B[5 q";    # blinking bar
      }
      else {
        $raw = "\x1B[1 q";    # blinking block
      }
      $raw .= "\x1B[?25h";
      tb_send( $raw, bytes::length( $raw ) );
    }
    else {
      # Show cursor; (-1,-1) is clamped to (0,0).
      tb_set_cursor( -1, -1 );
    }
  }
  return;
}

sub getCaretSize {    # $size ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );
  return min( max( $cursorSize, 0 ), 100 );
}

sub setCaretPosition {    # void ($class, $x, $y)
  my ( $class, $x, $y ) = @_;
  assert ( @_ == 3 );
  assert ( $class and !ref $class );
  assert ( looks_like_number $x );
  assert ( looks_like_number $y );
  assert ( $initialized );
  tb_set_cursor( $x, $y );
  return;
}

sub isCaretVisible {    # $visible ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );
  return $cursorSize > 0;
}

# -------------------------------------------------------------------------
# Screen functions
# -------------------------------------------------------------------------

sub getScreenRows {    # $rows ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );
  assert ( $initialized );
  my $rows = tb_height();
  return 25 
    if $rows == 0;    # Borland's compatibility DOS default (only for rows)
  return $rows > 0 ? $rows : 0;
}

sub getScreenCols {       # $cols ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );
  assert ( $initialized );
  my $cols = tb_width();
  return $cols > 0 ? $cols : 0;
}

sub getScreenMode {       # $mode ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );
  assert ( $initialized );

  my $rows = tb_height();
  return 0 unless $rows > 0;

  # Invalid or unspecified mode.
  unless ( $screenMode ) {
    # https://no-color.org/
    $screenMode = exists $ENV{NO_COLOR} && $ENV{NO_COLOR}
                ? smMono
                : smCO80;
  }

  my $mode = $screenMode;
  $mode &= ~smFont8x8;
  $mode |= smFont8x8 if $rows > 25;
  return $mode;
}

sub setScreenMode {       # void ($class, $mode)
  my ( $class, $mode ) = @_;
  assert ( @_ == 2 );
  assert ( $class and !ref $class );
  assert ( looks_like_number $mode );
  assert ( $initialized );

  return unless tb_height() > 0;

  # Fix the requested mode to a valid output mode.
  my $base = $mode & 0xff;
  if ( $base != smCO80
    && $base != smBW80
    && $base != smMono
  ) {
    $mode = ( $mode & 0xff00 ) | smCO80;
  }
  $mode &= ~smUpdate;
  $mode &= ~smColorHigh 
    if ( $mode & smColorHigh ) 
    && $class->getColorCount() < 256*256*256;
  $mode &= ~smColor256 
    if ( $mode & smColor256 ) 
    && $class->getColorCount() < 256;

  # Set the appropriate output mode based on the requested screen mode.
  if ( $mode & smColorHigh ) {
    tb_set_output_mode( TB_OUTPUT_TRUECOLOR )
      if $outputMode != TB_OUTPUT_TRUECOLOR
  }
  elsif ( $mode & smColor256 ) {
    tb_set_output_mode( TB_OUTPUT_256 )
      if $outputMode != TB_OUTPUT_256;
  }
  elsif ( $class->getColorCount() >= 16 ) {
    tb_set_output_mode( TB_OUTPUT_256 )
      if $outputMode != TB_OUTPUT_256;
  }
  else {
    tb_set_output_mode( TB_OUTPUT_NORMAL )
      if $outputMode != TB_OUTPUT_NORMAL;
  }

  # Clear the attribute cache, since the color mapping has changed.
  %$TB_ATTR = ();

  # Save the current output state
  $screenMode = $mode;
  $outputMode = tb_set_output_mode( TB_OUTPUT_CURRENT );

  return;
}

sub clearScreen {         # void ($class, $w, $h)
  my ( $class, $w, $h ) = @_;
  assert ( @_ == 3 );
  assert ( $class and !ref $class );
  assert ( looks_like_number $w );
  assert ( looks_like_number $h );
  assert ( $initialized );
  tb_clear();
  return;
}

sub screenWrite {         # void ($class, $x, $y, $buf, $len)
  my ( $class, $x, $y, $buf, $len ) = @_;
  assert ( @_ == 5 );
  assert ( $class and !ref $class );
  assert ( looks_like_number $x );
  assert ( looks_like_number $y );
  assert ( ref $buf );
  assert ( looks_like_number $len );
  assert ( $initialized );

  for ( my $i = 0 ; $i < $len ; ++$i, ++$x ) {
    my $cell = $buf->[$i];
    my $character = $cell->[0];
    my $attribute = $cell->[1];

    # Fast path equivalent for the code below:
    #   my $ch   = Encode::decode( cp437 => $character->getText() );
    my $ch = $UTF8_TO_CP437[ ord( $$character ) & 0xff ];

    # Cached attribute conversion for the code below:
    #   my $attr = [
    #     $attribute->getForeground->$convertColor( true ),
    #     $attribute->getBackground->$convertColor( false ),
    #   ];
    my $attr = $TB_ATTR->{$$attribute};
    unless ( $attr ) {
      $attr = [
        $attribute->getForeground->$convertColor( true ),
        $attribute->getBackground->$convertColor( false ),
      ];
      $TB_ATTR->{$$attribute} = $attr;
    }

    tb_set_cell( $x, $y, $ch, @$attr );
  }

  tb_present();
  return;
}

sub allocateScreenBuffer {    # \@buffer ($class)
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( $class and !ref $class );
  assert ( $initialized );
  $class->reloadScreenInfo();

  my $cols = tb_width();
  my $rows = tb_height();

  return []
    if $cols <= 0 || $rows <= 0;

  # Make sure we allocate at least enough for a 80x50 screen.
  $cols = 80 if $cols < 80;
  $rows = 50 if $rows < 50;

  return [ map { TScreenCell->new() } 1 .. $cols * $rows ];
}

sub freeScreenBuffer {        # void ($class, \@buffer)
  assert ( @_ == 2 );
  assert ( $_[0] and !ref $_[0] );
  assert ( ref $_[1] and !readonly @{ $_[1] } );
  $_[1] = [];
  return;
}

# -------------------------------------------------------------------------
# Mouse functions
# -------------------------------------------------------------------------

sub getButtonCount {    # $num ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );

  # Termbox reports mouse events, but not a physical button count.
  # Return a practical compatibility value.
  return $initialized ? 3 : 0;
}

sub cursorOn {    # void ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );
  assert ( $initialized );
  my $mode = tb_set_input_mode( TB_INPUT_CURRENT );
  tb_set_input_mode( $mode | TB_INPUT_MOUSE );
  return;
}

sub cursorOff {    # void ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );
  assert ( $initialized );
  my $mode = tb_set_input_mode( TB_INPUT_CURRENT );
  tb_set_input_mode( $mode & ~TB_INPUT_MOUSE );
  return;
}

# -------------------------------------------------------------------------
# Event functions
# -------------------------------------------------------------------------

sub clearPendingEvent {    # void ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );
  $pendingEvent = 0;
  return;
}

sub getMouseEvent {    # $bool ($class, $event)
  my ( $class, $event ) = @_;
  assert ( @_ == 2 );
  assert ( $class and !ref $class );
  assert ( blessed $event );
  assert ( $initialized );

  # Check for pending events
  unless ( $pendingEvent ) {
    my $rv = tb_peek_event( $tb_event, 0 );
    $pendingEvent = 1 if $rv == TB_OK;
  }

  # Return false if there are no pending events
  return false
    unless $pendingEvent;

  # Return if the event is not a mouse event
  return false
    if $tb_event->type != TB_EVENT_MOUSE;

  # Track the state of mouse buttons
  my $buttons = $lastButtons;
  if ( $tb_event->key == TB_KEY_MOUSE_LEFT ) {
    $buttons |= mbLeftButton;
  }
  elsif ( $tb_event->key == TB_KEY_MOUSE_RIGHT ) {
    $buttons |= mbRightButton;
  }
  elsif ( $tb_event->key == TB_KEY_MOUSE_RELEASE ) {
    $buttons = 0;
  }

  # Mouse position
  my @where = ( $tb_event->x, $tb_event->y );
  $event->{where}{x} = $where[0];
  $event->{where}{y} = $where[1];

  # Button state
  $event->{buttons} = $buttons;

  # Event flags. Double-clicks are detected by TEventQueue.
  $event->{eventFlags} = 0;
  $event->{eventFlags} |= meMouseMoved
    if $tb_event->mod & TB_MOD_MOTION;

  # Mouse modifier state.
  $event->{controlKeyState} = $insertState ? kbInsState : 0;

  # Save the last button state
  $lastButtons = $buttons;

  # Clear the pending event flag because we have consumed the event
  $pendingEvent = 0;
  return true;
}

sub getKeyEvent {    # $bool ($class, $event)
  my ( $class, $event ) = @_;
  assert ( @_ == 2 );
  assert ( $class and !ref $class );
  assert ( blessed $event );
  assert ( $initialized );

  # Check for pending events
  unless ( $pendingEvent ) {
    my $rv = tb_peek_event( $tb_event, 0 );
    $pendingEvent = 1 if $rv == TB_OK;
  }

  # Return false if there are no pending events
  return false
    unless $pendingEvent;

  # Handle resize events immediately
  if ( $tb_event->type == TB_EVENT_RESIZE ) {
    $pendingEvent = 0;
    if ( $class->screenChanged() ) {
      $event->{what} = evCommand;
      $event->{message}{command} = cmScreenChanged;
      $event->{message}{infoPtr} = undef;
      return true;
    }
    return false;
  }

  # Return if the event is not a key event
  return false
    if $tb_event->type != TB_EVENT_KEY;

  $event->{what} = evKeyDown;

  # Set the key code and character code in the event structure.
  my $keyCode = $tb_event->$convertKeyCode();
  $event->{keyDown}{keyCode} = $keyCode;
  if ( $keyCode == kbNoKey ) {
    my $charCode = $tb_event->$convertCharCode();
    $event->{keyDown}{charScan}{charCode} = $charCode;
  }
  elsif ( $keyCode == kbIns ) {
    $insertState = !$insertState;
  }

  # Update the shift state and control key state in the event structure
  my $shiftState = 0;
  $shiftState |= kbAltShift
    if $tb_event->mod & TB_MOD_ALT;
  $shiftState |= kbCtrlShift
    if $tb_event->mod & TB_MOD_CTRL;
  $shiftState |= kbShift
    if $tb_event->mod & TB_MOD_SHIFT;
  $shiftState |= kbInsState
    if $insertState;
  $event->{keyDown}{controlKeyState} = $shiftState;

  # Set the Ctrl-Break flag if Ctrl-C was pressed
  $ctrlBreakHit ||= $event->{keyDown}{keyCode} == kbCtrlC;

  $pendingEvent = 0;
  return true;
}

# -------------------------------------------------------------------------
# System functions
# -------------------------------------------------------------------------

sub setCtrlBrkHandler {    # $success ($class, $install)
  my ( $class, $install ) = @_;
  assert ( @_ == 2 );
  assert ( $class and !ref $class );
  assert ( !defined $install or !ref $install );
  # Termbox handles terminal input itself. No direct Ctrl-Break handler.
  return true;
}

sub setCritErrorHandler {    # $bool ($class, $install)
  assert ( @_ == 2 );
  assert ( $_[0] and !ref $_[0] );
  assert ( !defined $_[1] or !ref $_[1] );
  # Not applicable for Termbox.
  return true;
}

# -------------------------------------------------------------------------
# Additional functions (not part of the original Borland interface)
# -------------------------------------------------------------------------

sub getColorCount {    # $count ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );

  state $COLORS;
  return $COLORS if defined $COLORS;

  # Is Windows 10 or later? (build 10586)
  if ( $^O eq 'MSWin32' ) {
    # Simple OS version test for very old systems
    require Win32;
    return $COLORS = 16
      if ( Win32::GetOSVersion() )[1] < 6;

    # Check if we can enable Virtual Terminal processing.
    require Win32API::File;
    require Win32::Console;
    my $ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;

    my $console = Win32::Console->new( Win32API::File::STD_OUTPUT_HANDLE() );
    return $COLORS = 16 unless $console;

    $^E = 0;
    my $mode = $console->Mode();
    return $COLORS = 16 if $^E;

    $console->Mode($mode | $ENABLE_VIRTUAL_TERMINAL_PROCESSING);
    my $isVT = !$^E 
      && ( $console->Mode() // 0 ) & $ENABLE_VIRTUAL_TERMINAL_PROCESSING;

    $console->Mode( $mode );

    # VT processing implies modern console host.
    # Only modern VT hosts support 24-bit colors.
    return $COLORS = !$isVT              ? 16
                   : !tb_has_truecolor() ? 256
                   :                       256*256*256;
  }

  # First check COLORTERM environment
  if ( tb_has_truecolor() ) {
    my $colorterm = $ENV{COLORTERM} // '';
    return $COLORS = 256*256*256
      if $colorterm =~ /\A(?:truecolor|24bit)\z/i;
  }

  # Next check terminfo database
  my $colors = eval {
    require Term::Cap;
    local $SIG{__WARN__} = sub { };    # Suppress warnings from Tgetent
    Term::Cap->Tgetent()->{_Co};
  };
  return $COLORS = $colors 
    if !$@ && defined $colors && $colors >=8;

  # Otherwise check for common TERM values that indicate color support.
  my $term = $ENV{TERM} // '';
  return $COLORS = 256 if $term =~ /256color/i;

  # Let's assume all terminals disguising themselves as 'xterm'
  # support at least 16 colors.
  return $COLORS = 16 if $term =~ /xterm/;

  # Fall back to a conservative default of 8 colors.
  return $COLORS = 8;
} #/ sub getColorCount

sub reloadScreenInfo {    # void ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );
  tb_invalidate();
  return;
}

sub screenChanged {    # $bool ($class)
  assert ( @_ == 1 );
  assert ( $_[0] and !ref $_[0] );
  my $cols = tb_width();
  my $rows = tb_height();
  if ( $cols != $lastSize[0] || $rows != $lastSize[1] ) {
    @lastSize = ( $cols, $rows );
    return true;
  }
  return false;
}

# -------------------------------------------------------------------------
# Key Event conversion
# -------------------------------------------------------------------------

my %TV_TO_TB = (
  # Control keys
  kbCtrlA() => [ TB_MOD_CTRL, TB_KEY_CTRL_A, 0 ],
  kbCtrlB() => [ TB_MOD_CTRL, TB_KEY_CTRL_B, 0 ],
  kbCtrlC() => [ TB_MOD_CTRL, TB_KEY_CTRL_C, 0 ],
  kbCtrlD() => [ TB_MOD_CTRL, TB_KEY_CTRL_D, 0 ],
  kbCtrlE() => [ TB_MOD_CTRL, TB_KEY_CTRL_E, 0 ],
  kbCtrlF() => [ TB_MOD_CTRL, TB_KEY_CTRL_F, 0 ],
  kbCtrlG() => [ TB_MOD_CTRL, TB_KEY_CTRL_G, 0 ],
  kbCtrlH() => [ TB_MOD_CTRL, TB_KEY_CTRL_H, 0 ],
  kbCtrlI() => [ TB_MOD_CTRL, TB_KEY_CTRL_I, 0 ],
  kbCtrlJ() => [ TB_MOD_CTRL, TB_KEY_CTRL_J, 0 ],
  kbCtrlK() => [ TB_MOD_CTRL, TB_KEY_CTRL_K, 0 ],
  kbCtrlL() => [ TB_MOD_CTRL, TB_KEY_CTRL_L, 0 ],
  kbCtrlM() => [ TB_MOD_CTRL, TB_KEY_CTRL_M, 0 ],
  kbCtrlN() => [ TB_MOD_CTRL, TB_KEY_CTRL_N, 0 ],
  kbCtrlO() => [ TB_MOD_CTRL, TB_KEY_CTRL_O, 0 ],
  kbCtrlP() => [ TB_MOD_CTRL, TB_KEY_CTRL_P, 0 ],
  kbCtrlQ() => [ TB_MOD_CTRL, TB_KEY_CTRL_Q, 0 ],
  kbCtrlR() => [ TB_MOD_CTRL, TB_KEY_CTRL_R, 0 ],
  kbCtrlS() => [ TB_MOD_CTRL, TB_KEY_CTRL_S, 0 ],
  kbCtrlT() => [ TB_MOD_CTRL, TB_KEY_CTRL_T, 0 ],
  kbCtrlU() => [ TB_MOD_CTRL, TB_KEY_CTRL_U, 0 ],
  kbCtrlV() => [ TB_MOD_CTRL, TB_KEY_CTRL_V, 0 ],
  kbCtrlW() => [ TB_MOD_CTRL, TB_KEY_CTRL_W, 0 ],
  kbCtrlX() => [ TB_MOD_CTRL, TB_KEY_CTRL_X, 0 ],
  kbCtrlY() => [ TB_MOD_CTRL, TB_KEY_CTRL_Y, 0 ],
  kbCtrlZ() => [ TB_MOD_CTRL, TB_KEY_CTRL_Z, 0 ],

  # Extended key codes
  kbEsc()       => [ TB_NONE,      TB_KEY_ESC,         0 ],
  kbAltSpace()  => [ TB_MOD_ALT,   TB_KEY_SPACE,       0 ],

  kbCtrlIns()   => [ TB_MOD_CTRL,  TB_KEY_INSERT,      0 ],
  kbShiftIns()  => [ TB_MOD_SHIFT, TB_KEY_INSERT,      0 ],

  kbCtrlDel()   => [ TB_MOD_CTRL,  TB_KEY_DELETE,      0 ],
  kbShiftDel()  => [ TB_MOD_SHIFT, TB_KEY_DELETE,      0 ],

  kbBack()      => [ TB_MOD_CTRL,  TB_KEY_BACKSPACE2,  0 ],
  kbCtrlBack()  => [ TB_MOD_CTRL,  TB_KEY_BACKSPACE,   0 ],

  kbShiftTab()  => [ TB_MOD_SHIFT, TB_KEY_BACK_TAB,    0 ],
  kbTab()       => [ TB_NONE,      TB_KEY_TAB,         0 ],

  kbCtrlEnter() => [ TB_MOD_CTRL,  TB_KEY_CTRL_J,      0 ],
  kbEnter()     => [ TB_MOD_CTRL,  TB_KEY_ENTER,       0 ],

  # Alt letters
  kbAltQ()      => [ TB_MOD_ALT, 0, ord('q') ],
  kbAltW()      => [ TB_MOD_ALT, 0, ord('w') ],
  kbAltE()      => [ TB_MOD_ALT, 0, ord('e') ],
  kbAltR()      => [ TB_MOD_ALT, 0, ord('r') ],
  kbAltT()      => [ TB_MOD_ALT, 0, ord('t') ],
  kbAltY()      => [ TB_MOD_ALT, 0, ord('y') ],
  kbAltU()      => [ TB_MOD_ALT, 0, ord('u') ],
  kbAltI()      => [ TB_MOD_ALT, 0, ord('i') ],
  kbAltO()      => [ TB_MOD_ALT, 0, ord('o') ],
  kbAltP()      => [ TB_MOD_ALT, 0, ord('p') ],

  kbAltA()      => [ TB_MOD_ALT, 0, ord('a') ],
  kbAltS()      => [ TB_MOD_ALT, 0, ord('s') ],
  kbAltD()      => [ TB_MOD_ALT, 0, ord('d') ],
  kbAltF()      => [ TB_MOD_ALT, 0, ord('f') ],
  kbAltG()      => [ TB_MOD_ALT, 0, ord('g') ],
  kbAltH()      => [ TB_MOD_ALT, 0, ord('h') ],
  kbAltJ()      => [ TB_MOD_ALT, 0, ord('j') ],
  kbAltK()      => [ TB_MOD_ALT, 0, ord('k') ],
  kbAltL()      => [ TB_MOD_ALT, 0, ord('l') ],

  kbAltZ()      => [ TB_MOD_ALT, 0, ord('z') ],
  kbAltX()      => [ TB_MOD_ALT, 0, ord('x') ],
  kbAltC()      => [ TB_MOD_ALT, 0, ord('c') ],
  kbAltV()      => [ TB_MOD_ALT, 0, ord('v') ],
  kbAltB()      => [ TB_MOD_ALT, 0, ord('b') ],
  kbAltN()      => [ TB_MOD_ALT, 0, ord('n') ],
  kbAltM()      => [ TB_MOD_ALT, 0, ord('m') ],

  # Function keys
  kbF1()        => [ TB_NONE,      TB_KEY_F1,          0 ],
  kbF2()        => [ TB_NONE,      TB_KEY_F2,          0 ],
  kbF3()        => [ TB_NONE,      TB_KEY_F3,          0 ],
  kbF4()        => [ TB_NONE,      TB_KEY_F4,          0 ],
  kbF5()        => [ TB_NONE,      TB_KEY_F5,          0 ],
  kbF6()        => [ TB_NONE,      TB_KEY_F6,          0 ],
  kbF7()        => [ TB_NONE,      TB_KEY_F7,          0 ],
  kbF8()        => [ TB_NONE,      TB_KEY_F8,          0 ],
  kbF9()        => [ TB_NONE,      TB_KEY_F9,          0 ],
  kbF10()       => [ TB_NONE,      TB_KEY_F10,         0 ],
  kbF11()       => [ TB_NONE,      TB_KEY_F11,         0 ],
  kbF12()       => [ TB_NONE,      TB_KEY_F12,         0 ],

  kbShiftF1()   => [ TB_MOD_SHIFT, TB_KEY_F1,          0 ],
  kbShiftF2()   => [ TB_MOD_SHIFT, TB_KEY_F2,          0 ],
  kbShiftF3()   => [ TB_MOD_SHIFT, TB_KEY_F3,          0 ],
  kbShiftF4()   => [ TB_MOD_SHIFT, TB_KEY_F4,          0 ],
  kbShiftF5()   => [ TB_MOD_SHIFT, TB_KEY_F5,          0 ],
  kbShiftF6()   => [ TB_MOD_SHIFT, TB_KEY_F6,          0 ],
  kbShiftF7()   => [ TB_MOD_SHIFT, TB_KEY_F7,          0 ],
  kbShiftF8()   => [ TB_MOD_SHIFT, TB_KEY_F8,          0 ],
  kbShiftF9()   => [ TB_MOD_SHIFT, TB_KEY_F9,          0 ],
  kbShiftF10()  => [ TB_MOD_SHIFT, TB_KEY_F10,         0 ],
  kbShiftF11()  => [ TB_MOD_SHIFT, TB_KEY_F11,         0 ],
  kbShiftF12()  => [ TB_MOD_SHIFT, TB_KEY_F12,         0 ],

  kbCtrlF1()    => [ TB_MOD_CTRL,  TB_KEY_F1,          0 ],
  kbCtrlF2()    => [ TB_MOD_CTRL,  TB_KEY_F2,          0 ],
  kbCtrlF3()    => [ TB_MOD_CTRL,  TB_KEY_F3,          0 ],
  kbCtrlF4()    => [ TB_MOD_CTRL,  TB_KEY_F4,          0 ],
  kbCtrlF5()    => [ TB_MOD_CTRL,  TB_KEY_F5,          0 ],
  kbCtrlF6()    => [ TB_MOD_CTRL,  TB_KEY_F6,          0 ],
  kbCtrlF7()    => [ TB_MOD_CTRL,  TB_KEY_F7,          0 ],
  kbCtrlF8()    => [ TB_MOD_CTRL,  TB_KEY_F8,          0 ],
  kbCtrlF9()    => [ TB_MOD_CTRL,  TB_KEY_F9,          0 ],
  kbCtrlF10()   => [ TB_MOD_CTRL,  TB_KEY_F10,         0 ],
  kbCtrlF11()   => [ TB_MOD_CTRL,  TB_KEY_F11,         0 ],
  kbCtrlF12()   => [ TB_MOD_CTRL,  TB_KEY_F12,         0 ],

  kbAltF1()     => [ TB_MOD_ALT,   TB_KEY_F1,          0 ],
  kbAltF2()     => [ TB_MOD_ALT,   TB_KEY_F2,          0 ],
  kbAltF3()     => [ TB_MOD_ALT,   TB_KEY_F3,          0 ],
  kbAltF4()     => [ TB_MOD_ALT,   TB_KEY_F4,          0 ],
  kbAltF5()     => [ TB_MOD_ALT,   TB_KEY_F5,          0 ],
  kbAltF6()     => [ TB_MOD_ALT,   TB_KEY_F6,          0 ],
  kbAltF7()     => [ TB_MOD_ALT,   TB_KEY_F7,          0 ],
  kbAltF8()     => [ TB_MOD_ALT,   TB_KEY_F8,          0 ],
  kbAltF9()     => [ TB_MOD_ALT,   TB_KEY_F9,          0 ],
  kbAltF10()    => [ TB_MOD_ALT,   TB_KEY_F10,         0 ],
  kbAltF11()    => [ TB_MOD_ALT,   TB_KEY_F11,         0 ],
  kbAltF12()    => [ TB_MOD_ALT,   TB_KEY_F12,         0 ],

  # Navigation
  kbHome()      => [ TB_NONE,      TB_KEY_HOME,        0 ],
  kbEnd()       => [ TB_NONE,      TB_KEY_END,         0 ],

  kbPgUp()      => [ TB_NONE,      TB_KEY_PGUP,        0 ],
  kbPgDn()      => [ TB_NONE,      TB_KEY_PGDN,        0 ],

  kbUp()        => [ TB_NONE,      TB_KEY_ARROW_UP,    0 ],
  kbDown()      => [ TB_NONE,      TB_KEY_ARROW_DOWN,  0 ],
  kbLeft()      => [ TB_NONE,      TB_KEY_ARROW_LEFT,  0 ],
  kbRight()     => [ TB_NONE,      TB_KEY_ARROW_RIGHT, 0 ],

  kbCtrlLeft()  => [ TB_MOD_CTRL,  TB_KEY_ARROW_LEFT,  0 ],
  kbCtrlRight() => [ TB_MOD_CTRL,  TB_KEY_ARROW_RIGHT, 0 ],

  kbCtrlHome()  => [ TB_MOD_CTRL,  TB_KEY_HOME,        0 ],
  kbCtrlEnd()   => [ TB_MOD_CTRL,  TB_KEY_END,         0 ],

  kbCtrlPgUp()  => [ TB_MOD_CTRL,  TB_KEY_PGUP,        0 ],
  kbCtrlPgDn()  => [ TB_MOD_CTRL,  TB_KEY_PGDN,        0 ],

  kbIns()       => [ TB_NONE,      TB_KEY_INSERT,      0 ],
  kbDel()       => [ TB_NONE,      TB_KEY_DELETE,      0 ],

  # Alt digits
  kbAlt1()      => [ TB_MOD_ALT, 0, ord('1') ],
  kbAlt2()      => [ TB_MOD_ALT, 0, ord('2') ],
  kbAlt3()      => [ TB_MOD_ALT, 0, ord('3') ],
  kbAlt4()      => [ TB_MOD_ALT, 0, ord('4') ],
  kbAlt5()      => [ TB_MOD_ALT, 0, ord('5') ],
  kbAlt6()      => [ TB_MOD_ALT, 0, ord('6') ],
  kbAlt7()      => [ TB_MOD_ALT, 0, ord('7') ],
  kbAlt8()      => [ TB_MOD_ALT, 0, ord('8') ],
  kbAlt9()      => [ TB_MOD_ALT, 0, ord('9') ],
  kbAlt0()      => [ TB_MOD_ALT, 0, ord('0') ],

  kbAltMinus()  => [ TB_MOD_ALT, 0, ord('-') ],
  kbAltEqual()  => [ TB_MOD_ALT, 0, ord('=') ],

  kbAltBack()   => [
                      TB_MOD_ALT | TB_MOD_CTRL,
                      TB_KEY_BACKSPACE2,
                      0
                    ],

  kbNoKey()     => [ TB_NONE, 0, 0 ],

  # kbGrayMinus() => collides with '-'
  # kbGrayPlus()  => collides with '+'
  # kbCtrlPrtSc() => no event generated (effectively collides with kbNoKey())
);
my %TB_TO_TV; {
  while ( my ( $tv_key, $tb_key ) = each %TV_TO_TB ) {
    my ( $mod, $key, $ch ) = @$tb_key;

    # Default: first mapping wins.
    # This avoids accidental replacement caused by hash iteration order.
    my $id = join( ':', ( $mod, $key, $ch ) );
    $TB_TO_TV{$id} = $tv_key
      unless exists $TB_TO_TV{$id};
  }

  # VT control-code collisions.
  #
  # VT stream     TV keys                 Preferred
  # ------------------------------------------------
  # 0x08          Ctrl-H, Ctrl-Back       Ctrl-Back
  # 0x09          Ctrl-I, Tab             Tab
  # 0x0A          Ctrl-J, Ctrl-Enter      Ctrl-Enter
  # 0x0D          Ctrl-M, Enter           Enter
  $TB_TO_TV{ join( ':', TB_MOD_CTRL, TB_KEY_BACKSPACE, 0 ) }
    = kbCtrlBack();
  $TB_TO_TV{ join( ':', TB_MOD_CTRL, TB_KEY_TAB, 0 ) }
    = kbTab();
  $TB_TO_TV{ join( ':', TB_MOD_CTRL, TB_KEY_CTRL_J, 0 ) }
    = kbCtrlEnter();
  $TB_TO_TV{ join( ':', TB_MOD_CTRL, TB_KEY_ENTER, 0 ) }
    = kbEnter();
}
my %CP437 = map { $CP437_TO_UTF8[$_] => $_ } 0..255;

$convertCharCode = sub {    # $charCode ($event)
  my ( $event ) = @_;

  my $cp = $event->ch;

  # Support the official Unicode values instead only the Termius equivalents
  return 0x10 if $cp == ord "\x{25ba}";
  return 0x11 if $cp == ord "\x{25c4}";

  return $CP437{$cp}
    if $cp && exists $CP437{$cp};

  my $key = $event->key;

  return $key
    if $key <= 0x1f || $key == 0x7f;

  return 0;
};

$convertKeyCode = sub {    # $keyCode ($event)
  my ( $event ) = @_;

  my $mod = $event->mod;
  my $key = $event->key;
  my $ch  = $event->ch;

  # Keep only keyboard modifier bits relevant for the key mapping.
  $mod &= TB_MOD_ALT | TB_MOD_CTRL | TB_MOD_SHIFT;

  my $id = join( ':', $mod, $key, $ch );
  return $TB_TO_TV{$id}
    if exists $TB_TO_TV{$id};

  # Some Alt/Ctrl key combinations have no dedicated Borland key code.
  # Map them to the corresponding unmodified key.
  if ( $mod & ( TB_MOD_CTRL | TB_MOD_ALT ) ) {
    return kbUp    if $key == TB_KEY_ARROW_UP;
    return kbDown  if $key == TB_KEY_ARROW_DOWN;
    return kbIns   if $key == TB_KEY_INSERT;
    return kbDel   if $key == TB_KEY_DELETE;
    return kbTab   if $key == TB_KEY_TAB;
    return kbEnter if $key == TB_KEY_ENTER;
  }
  if ( $mod & TB_MOD_ALT ) {
    return kbLeft  if $key == TB_KEY_ARROW_LEFT;
    return kbRight if $key == TB_KEY_ARROW_RIGHT;
    return kbHome  if $key == TB_KEY_HOME;
    return kbEnd   if $key == TB_KEY_END;
    return kbPgUp  if $key == TB_KEY_PGUP;
    return kbPgDn  if $key == TB_KEY_PGDN;
  }

  return kbNoKey();
};

# -------------------------------------------------------------------------
# Attribute conversion
# -------------------------------------------------------------------------

# The following content is inspired by the framework
# "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
#
# Copyright 2019-2026 by magiblot <magiblot@hotmail.com>
#
# I<ansiwrit.cpp>

$convertColor = sub {    # $tb_color ($color, $isFg)
  my ( $color, $isFg ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $color );
  assert ( !ref $isFg );
  return $color->$convertNoColor( $isFg )
    if ( $screenMode & 0xff ) == smMono;

  return TB_DEFAULT
    if ( $screenMode & 0xff ) != smBW80 
    && ( $screenMode & 0xff ) != smCO80;

  return $color->$convertDirect( $isFg )
    if $screenMode & smColorHigh;

  return $color->$convertIndexed256( $isFg )
    if $screenMode & smColor256;

  return $color->$convertIndexed16( $isFg )
    if $outputMode > TB_OUTPUT_NORMAL;
   
  return $color->$convertIndexed8( $isFg );
};

$convertNoColor = sub {    # $tb_color ($color, $isFg)
  my ( $color, $isFg ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $color );
  assert ( !ref $isFg );
  my $c = TB_DEFAULT;
  if ( $color->isBIOS() ) {
    my $bios = $color->asBIOS();
    if ( $isFg ) {
      if ( $bios & 0x8 ) {
        $c |= TB_BOLD;
      }
      elsif ( $bios == 0x1 ) {
        $c |= TB_UNDERLINE;
      }
    }
    elsif ( ( $bios & 0x7 ) == 0x7 ) {
      $c |= TB_REVERSE;
    }
  }
  return $c;
};

$convertIndexed8 = sub {    # $tb_color ($color, $isFg)
  my ( $color, $isFg ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $color );
  assert ( !ref $isFg );
  my $idx = $color->$convertIndexed16( $isFg );
  my $c = ( $idx & 0x7 ) + 1;
  if ( $idx & 0x8 ) {
    $c |= $isFg ? TB_BOLD : TB_BLINK;
  }
  $c = TB_BLACK   if $idx & TB_HI_BLACK;
  $c = TB_DEFAULT if $idx == TB_DEFAULT;
  return $c;
};

$convertIndexed16 = sub {    # $tb_color ($color, $isFg)
  my ( $color, $isFg ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $color );
  assert ( !ref $isFg );
  if ( $color->isBIOS() ) {
    my $idx = BIOStoXTerm16( $color->asBIOS() );
    return $idx == TB_DEFAULT ? TB_HI_BLACK : $idx;
  }
  elsif ( $color->isXTerm() ) {
    my $idx = $color->asXTerm();
    $idx = XTerm256toXTerm16( $idx )
      if $idx >= 16;
    return $idx == TB_DEFAULT ? TB_HI_BLACK : $idx;
  }
  elsif ( $color->isRGB() ) {
    my $idx = RGBtoXTerm16( $color->asRGB() );
    return $idx == TB_DEFAULT ? TB_HI_BLACK : $idx;
  }
  return TB_DEFAULT;
};

$convertIndexed256 = sub {    # $tb_color ($color, $isFg)
  my ( $color, $isFg ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $color );
  assert ( !ref $isFg );
  if ( $color->isXTerm() ) {
    my $idx = $color->asXTerm();
    return $idx == TB_DEFAULT ? TB_HI_BLACK : $idx;
  }
  elsif ( $color->isRGB() ) {
    my $idx = RGBtoXTerm256( $color->asRGB() );
    return $idx == TB_DEFAULT ? TB_HI_BLACK : $idx;
  }
  return $color->$convertIndexed16( $isFg );
};

my @XTERM256 = (
  # 0-15: system colors
  0x000000, 0x800000, 0x008000, 0x808000,
  0x000080, 0x800080, 0x008080, 0xc0c0c0,
  0x808080, 0xff0000, 0x00ff00, 0xffff00,
  0x0000ff, 0xff00ff, 0x00ffff, 0xffffff,
); {
  my @level = ( 0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff );

  # 16-231: color cubes
  for my $r ( @level ) {
    for my $g ( @level ) {
      for my $b ( @level ) {
        push @XTERM256, ( $r << 16 ) | ( $g << 8 ) | $b;
      }
    }
  }

  # 232-255: gray scale
  for my $i ( 0 .. 23 ) {
    my $v = 8 + $i * 10;
    push @XTERM256, ( $v << 16 ) | ( $v << 8 ) | $v;
  }
}

$convertDirect = sub {    # $tb_color ($color, $isFg)
  my ( $color, $isFg ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $color );
  assert ( !ref $isFg );
  if ( $color->isRGB() ) {
    my $idx = $color->asRGB();
    return $idx == TB_DEFAULT ? TB_HI_BLACK : $idx;
  }
  my $idx = $color->$convertIndexed256( $isFg );
  my $c = $XTERM256[ $idx & 0xff ];
  $c = TB_HI_BLACK if $idx & TB_HI_BLACK;
  return $c;
};

1;

__END__

=pod

=head1 NAME

TUI::Drivers::HardwareInfo::Termbox - Termbox hardware backend for THardwareInfo

=head1 DESCRIPTION

This module provides the L<Termbox>-based implementation of the 
L<THardwareInfo|TUI::Drivers::HardwareInfo> hardware interface used by the 
I<Turbo Vision> driver layer.

The module maps keyboard, mouse, screen, caret, timer, and terminal services
to the facilities provided by L<Termbox>.

Depending on availability, either the native L<Termbox> FFI implementation or 
the pure Perl fallback implementation is used transparently.

This module is not instantiated. All interaction is performed through
class-level method calls.

Terminal resources are initialized automatically when the module is loaded and
released automatically when the program terminates.

=head1 VARIABLES

The following variables are internal to the L<Termbox> backend implementation 
and are not part of the portable L<THardwareInfo|TUI::Drivers::HardwareInfo> 
interface.

=head2 $insertState

Tracks the current insert mode state (I<Bool>).

=head2 $platform

Contains the platform classification string (I<Str>) determined at module
initialization.

=head2 $pendingEvent

Indicates whether a Termbox input event has been buffered(I<PositiveOrZeroInt>).

=head2 $lastButtons

Stores the most recently observed mouse button state (I<PositiveOrZeroInt>).

=head1 IMPLEMENTATION

This module contains the Termbox-specific implementation behind
L<THardwareInfo|TUI::Drivers::HardwareInfo>. Public API semantics and usage are 
documented in L<THardwareInfo|TUI::Drivers::HardwareInfo>.

In this backend, those methods are mapped to Termbox facilities for terminal
input handling, screen output, cursor management, timing, and mouse support.

The implementation provides translation between I<Turbo Vision> key codes,
character codes, mouse events, and the corresponding Termbox event model.

When the pure Perl L<Termbox::PP> backend is used, additional compatibility
handling is available for standalone C<Esc> key detection and WinVT-specific
input processing. These facilities are currently not available when using the
native FFI-based L<Termbox> implementation.

The exact implementation details here are backend-specific and may differ from
other platform implementations.

=head1 SEE ALSO

L<THardwareInfo|TUI::Drivers::HardwareInfo>,
L<TScreen|TUI::Drivers::Screen>,
L<THWMouse|TUI::Drivers::HWMouse>,
L<TSystemError|TUI::Drivers::SystemError>,
L<Termbox::PP>, 
L<Termbox>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org>

=back

=head1 CONTRIBUTORS

=over

=item * magiblot <magiblot@hotmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2019-2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
