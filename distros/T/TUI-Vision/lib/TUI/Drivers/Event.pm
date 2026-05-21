package TUI::Drivers::Event;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TEvent
  new_TEvent
);

use PerlX::Assert::PP;
use Hash::Util qw( lock_hash );
use Scalar::Util qw(
  blessed
  looks_like_number
);
use Tie::Hash;

use TUI::Drivers::Const qw( 
  :evXXXX
  kbAltShift
  kbAltSpace
  kbDel
  kbCtrlShift
  kbCtrlDel
  kbShift
  kbShiftDel
  kbIns
  kbCtrlIns
  kbShiftIns
);
use TUI::Drivers::HardwareInfo;

# The following code section represents the 'MouseEventType' structure used for 
# the 'THWMouse' and 'TEvent' class.
package MouseEventType {
  use strict;
  use warnings;

  use Devel::StrictMode;
  use PerlX::Assert::PP;
  use if STRICT => 'Hash::Util';
  use Scalar::Util qw( blessed );
  use TUI::Objects::Point;

  our %HAS; BEGIN {
    %HAS = ( 
      eventFlags      => sub { 0 },
      controlKeyState => sub { 0 },
      buttons         => sub { 0 },
      where           => sub { TPoint->new() },
    );
  }

  sub new {    # $obj (%args)
    no warnings 'uninitialized';
    my ( $class, %args ) = @_;
    assert ( $class and !ref $class );
    my $self = {
      eventFlags      => 0+ $args{eventFlags}      || $HAS{eventFlags}->(),
      controlKeyState => 0+ $args{controlKeyState} || $HAS{controlKeyState}->(),
      buttons         => 0+ $args{buttons}         || $HAS{buttons}->(),
    };
    my $type = ref $args{where};
    if ( $type eq 'HASH' || $type eq TPoint ) {
      $self->{where} = TPoint->new(
        x => 0+ $args{where}{x},
        y => 0+ $args{where}{y},
      );
    }
    elsif ( $type eq 'ARRAY' ) {
      $self->{where} = TPoint->new(
        x => 0+ $args{where}->[0],
        y => 0+ $args{where}->[1],
      );
    } 
    else {
      $self->{where} = $HAS{where}->();
    }
    bless $self, $class;
    Hash::Util::lock_keys( %$self ) if STRICT;
    return $self;
  } #/ sub MouseEventType::new

  sub clone {    # $obj ()
    my ( $self ) = @_;
    assert ( @_ == 1 );
    assert ( blessed $self );
    my $class = ref $self || return;
    my $clone = bless { %$self }, $class;
    Hash::Util::lock_keys( %$clone ) if STRICT;
    $clone->{where} = $self->{where}->clone();
    return $clone;
  }

  $INC{"MouseEventType.pm"} = 1;
}

# The following code section represents the 'CharScanType' structure used for 
# the 'KeyDownEvent' class.
package CharScanType {
  use strict;
  use warnings;

  use PerlX::Assert::PP;
  use Hash::Util qw( lock_hash );
  use Scalar::Util qw( blessed );
  use Tie::Hash;

  our %HAS = (
    scanCode => sub {
      no warnings 'uninitialized';
      my ( $this, $code ) = @_;
      $$this = ($$this & 0xff) + (0+$code << 8) if @_ > 1;
      $$this >> 8;
    },
    charCode => sub { 
      no warnings 'uninitialized';
      my ( $this, $code ) = @_;
      $$this = ($$this & ~0xff) + (0+$code & 0xff) if @_ > 1;
      $$this & 0xff;
    },
  );
  lock_hash( %HAS );

  use parent 'Tie::Hash';

  sub new {    # $obj (%args)
    my ( $class, %args ) = @_;
    assert ( $class and !ref $class );
    my $self = bless {}, $class;
    tie %$self, $class;
    map { $self->{$_} = $args{$_} }
      grep { exists $args{$_} }
        keys %HAS;
    return $self;
  }

  sub clone {    # $obj ()
    my ( $self ) = @_;
    assert ( @_ == 1 );
    assert ( blessed $self );
    my $class = ref $self || return;
    my $clone = bless {}, $class;
    tie %$clone, $class;
    map { $clone->{$_} = $self->{$_} } keys %HAS;
    return $clone;
  }

  sub TIEHASH  { bless \( my $data ), $_[0] }
  sub STORE    { $HAS{ $_[1] }->( $_[0], $_[2] ) }
  sub FETCH    { $HAS{ $_[1] }->( $_[0] ) }
  sub FIRSTKEY { my $a = scalar keys %HAS; each %HAS }
  sub NEXTKEY  { each %HAS }
  sub EXISTS   { exists $HAS{ $_[1] } }
  sub DELETE   { delete $HAS{ $_[1] } }  # raise an exception
  sub CLEAR    { %HAS = () }             # raise an exception
  sub SCALAR   { scalar keys %HAS }      # return number of elements (> 5.24)

  $INC{"CharScanType.pm"} = 1;
}

# The following code section represents the 'KeyDownEvent' structure used for 
# the 'TEvent' class.
package KeyDownEvent {
  use strict;
  use warnings;

  use PerlX::Assert::PP;
  use Hash::Util qw( lock_hash );
  use Scalar::Util qw( blessed );
  use Tie::Hash;

  our %HAS = (
    keyCode => sub {
      no warnings 'uninitialized';
      my ( $this, $code ) = @_;
      my $obj = tied %{ $this->[0] };
      $$obj = 0+$code if @_ > 1;
      $$obj;
    },
    charScan => sub {
      my ( $this, $obj ) = @_;
      $this->[0] = $obj if @_ > 1;
      $this->[0];
    },
    controlKeyState => sub { 
      no warnings 'uninitialized';
      my ( $this, $state ) = @_;
      $this->[1] = 0+$state if @_ > 1;
      $this->[1];
    },
  );
  lock_hash( %HAS );

  use parent 'Tie::Hash';

  sub new {    # $obj (%args)
    my ( $class, %args ) = @_;
    assert ( $class and !ref $class );
    my $self = bless {}, $class;
    tie %$self, $class;
    map { $self->{$_} = $args{$_} }
      grep { exists $args{$_} }
        keys %HAS;
    return $self;
  }

  sub clone {    # $obj ()
    my ( $self ) = @_;
    assert ( @_ == 1 );
    assert ( blessed $self );
    my $class = ref $self || return;
    my $clone = bless {}, $class;
    tie %$clone, $class;
    $clone->{keyCode}         = $self->{keyCode};
    $clone->{controlKeyState} = $self->{controlKeyState};
    return $clone;
  }

  sub TIEHASH  { bless [ CharScanType->new(), 0 ], $_[0] }
  sub STORE    { $HAS{ $_[1] }->( $_[0], $_[2] ) }
  sub FETCH    { $HAS{ $_[1] }->( $_[0] ) }
  sub FIRSTKEY { my $a = scalar keys %HAS; each %HAS }
  sub NEXTKEY  { each %HAS }
  sub EXISTS   { exists $HAS{ $_[1] } }
  sub DELETE   { delete $HAS{ $_[1] } }  # raise an exception
  sub CLEAR    { %HAS = () }             # raise an exception
  sub SCALAR   { scalar keys %HAS }      # return number of elements (> 5.24)

  $INC{"KeyDownEvent.pm"} = 1;
}

# The following code section represents the 'MessageEvent' structure used for
# the 'TEvent' class.
package MessageEvent {
  use strict;
  use warnings;

  use PerlX::Assert::PP;
  use Hash::Util qw( lock_hash );
  use Scalar::Util qw(
    blessed
    weaken
  );
  use Tie::Hash;

  our %HAS = (
    command => sub {
      no warnings 'uninitialized';
      my ( $this, $cmd ) = @_;
      $this->[0] = 0+$cmd if @_ > 1;
      $this->[0];
    },
    infoPtr => sub {
      my ( $this, $info ) = @_;
      if ( @_ > 1 ) {
        $this->[1] = $info;
        weaken $this->[1] if ref $info;
      }
      $this->[1];
    },
    infoLong => sub {
      no warnings qw( uninitialized numeric );
      my ( $this, $info ) = @_;
      $this->[1] = 0+$info & 0xffff_ffff if @_ > 1;
      0+$this->[1] & 0xffff_ffff;
    },
    infoWord => sub {
      no warnings qw( uninitialized numeric );
      my ( $this, $info ) = @_;
      $this->[1] = 0+$info & 0xffff if @_ > 1;
      0+$this->[1] & 0xffff;
    },
    infoInt => sub {
      no warnings qw( uninitialized numeric );
      my ( $this, $info ) = @_;
      $this->[1] = 0+$info if @_ > 1;
      0+$this->[1];
    },
    infoByte => sub {
      no warnings qw( uninitialized numeric );
      my ( $this, $info ) = @_;
      $this->[1] = 0+$info & 0xff if @_ > 1;
      0+$this->[1] & 0xff;
    },
    infoChar => sub {
      no warnings qw( uninitialized numeric );
      my ( $this, $info ) = @_;
      $this->[1] = ord $_[1] if @_ > 1;
      chr( 0+$this->[1] );
    },
  );
  lock_hash( %HAS );

  use parent 'Tie::Hash';

  sub new {    # $obj (%args)
    my ( $class, %args ) = @_;
    assert ( $class and !ref $class );
    my $self = bless {}, $class;
    tie %$self, $class;
    map { $self->{$_} = $args{$_} }
      grep { exists $args{$_} }
        keys %HAS;
    return $self;
  } #/ sub new

  sub clone {    # $obj ()
    my ( $self ) = @_;
    assert ( @_ == 1 );
    assert ( blessed $self );
    my $class = ref $self || return;
    my $clone = bless {}, $class;
    tie %$clone, $class;
    $clone->{command} = $self->{command};
    if ( blessed $self->{infoPtr} && $self->{infoPtr}->can( 'clone' ) ) {
      $clone->{infoPtr} = $self->{infoPtr}->clone();
    }
    elsif ( ref $self->{infoPtr} ) {
      weaken( $clone->{infoPtr} = $self->{infoPtr} );
    }
    else {
      $clone->{infoPtr} = $self->{infoPtr};
    }
    return $clone;
  }

  sub TIEHASH  { bless [ 0, 0 ], $_[0] }
  sub STORE    { $HAS{ $_[1] }->( $_[0], $_[2] ) }
  sub FETCH    { $HAS{ $_[1] }->( $_[0] ) }
  sub FIRSTKEY { my $a = scalar keys %HAS; each %HAS }
  sub NEXTKEY  { each %HAS }
  sub EXISTS   { exists $HAS{ $_[1] } }
  sub DELETE   { delete $HAS{ $_[1] } }  # raise an exception
  sub CLEAR    { %HAS = () }             # raise an exception
  sub SCALAR   { scalar keys %HAS }      # return number of elements (> 5.24)

  $INC{"MessageEvent.pm"} = 1;
}

sub TEvent() { __PACKAGE__ }
sub new_TEvent { __PACKAGE__->from(@_) }

our %HAS = (
  what => sub {
    my ( $this, $what ) = @_;
    if ( @_ > 1 ) {
      assert ( looks_like_number $what );
      no warnings 'uninitialized';
      $what += evNothing;
      my $type = ref $this->[1];
      if ( ( $what & evMouse ) && $type !~ /mouse/i ) {
        @$this = ( $what, MouseEventType->new() );
      }
      elsif ( ( $what & evKeyboard ) && $type !~ /keyDown/i ) {
        @$this = ( $what, KeyDownEvent->new() );
      }
      elsif ( ( $what & evMessage ) && $type !~ /message/i ) {
        @$this = ( $what, MessageEvent->new() );
      }
      else {
        $this->[0] = $what;
      }
    }
    $this->[0];
  },
  mouse => sub {
    my ( $this, $mouse ) = @_;
    $this->[1] = $mouse if @_ > 1;
    my $type = ref $this->[1];
    $type =~ /mouse/i ? $this->[1] : undef;
  },
  keyDown => sub {
    my ( $this, $keyDown ) = @_;
    $this->[1] = $keyDown if @_ > 1;
    my $type = ref $this->[1];
    $type =~ /keyDown/i ? $this->[1] : undef;
  },
  message => sub {
    my ( $this, $message ) = @_;
    $this->[1] = $message if @_ > 1;
    my $type = ref $this->[1];
    $type =~ /message/i ? $this->[1] : undef;
  },
);
lock_hash( %HAS );

use parent 'Tie::Hash';

sub new {    # $obj (%args)
  no warnings 'uninitialized';
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  my $self = bless {}, $class;
  tie %$self, $class;
  my $this = tied %$self;
  assert ( !exists $args{what} or looks_like_number $args{what} );
  if ( $args{what} & evMouse ) {
    $this->[0] = $args{what},
    $this->[1] = MouseEventType->new(
      map { $_ => $args{mouse}{$_} }
        grep { exists $args{mouse}{$_} } 
          qw( where eventFlags controlKeyState buttons )
    );
  }
  elsif ( $args{what} & evKeyboard ) {
    $this->[0] = $args{what},
    $this->[1] = KeyDownEvent->new( 
      map { $_ => $args{keyDown}{$_} }
        grep { exists $args{keyDown}{$_} } 
          qw( keyCode charScan controlKeyState )
    );
  }
  elsif ( $args{what} & evMessage ) {
    $this->[0] = $args{what},
    $this->[1] = MessageEvent->new( 
      map { $_ => $args{message}{$_} }
        grep { exists $args{message}{$_} } 
          qw( command infoPtr infoLong infoWord infoInt infoByte infoChar )
    );
  }
  return $self;
} #/ sub new

sub from {    # $obj ()
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 0 );
  return $class->new();
}

sub dump {    # $str (|$maxDepth)
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  no warnings 'once';
  require Data::Dumper;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Maxdepth = @_ ? shift : 3;
  my $str = Data::Dumper::Dumper $self;
  $str =~ s/(^|\s)\$VAR\d+\b/$1'$self'/g;
  return $str;
}

sub assign {    # $self ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );
  $self->{what} = $event->{what};
  if ( $event->{mouse} ) {
    $self->{mouse} = $event->{mouse}->clone();
  }
  elsif ( $event->{keyDown} ) {
    $self->{keyDown} = $event->{keyDown}->clone();
  }
  elsif ( $event->{message} ) {
    $self->{message} = $event->{message}->clone();
  }
  return $self;
}

sub clone {    # $obj ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  my $class = ref $self || return;
  my $clone = bless {}, $class;
  tie %$clone, $class;
  $clone->{what} = $self->{what};
  if ( $self->{mouse} ) {
    $clone->{mouse} = $self->{mouse}->clone();
  }
  elsif ( $self->{keyDown} ) {
    $clone->{keyDown} = $self->{keyDown}->clone();
  }
  elsif ( $self->{message} ) {
    $clone->{message} = $self->{message}->clone();
  }
  return $clone;
}

sub TIEHASH  { bless [ evNothing, undef ], $_[0] }
sub STORE    { $HAS{ $_[1] }->( $_[0], $_[2] ) }
sub FETCH    { $HAS{ $_[1] }->( $_[0] ) }
sub FIRSTKEY { my $a = scalar keys %HAS; each %HAS }
sub NEXTKEY  { each %HAS }
sub EXISTS   { exists $HAS{ $_[1] } }
sub DELETE   { delete $HAS{ $_[1] } }  # raise an exception
sub CLEAR    { %HAS = () }             # raise an exception
sub SCALAR   { scalar keys %HAS }      # return number of elements (> 5.24)

sub getMouseEvent {    # void ($self)
  assert ( blessed $_[0] );
  require TUI::Drivers::EventQueue;
  TUI::Drivers::EventQueue->getMouseEvent( $_[0] );
  return;
}

sub getKeyEvent {    # void ($self)
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  if ( THardwareInfo->getKeyEvent( $self ) ) {

    # Need to handle special case of Alt-Space, Ctrl-Ins, Shift-Ins,
    # Ctrl-Del, Shift-Del

    SWITCH: for ( $self->{keyDown}{keyCode} ) {
      $_ == ord(' ') and do {
        if ( $self->{keyDown}{controlKeyState} & kbAltShift ) {
          $self->{keyDown}{keyCode} = kbAltSpace;
        }
        last;
      };
      $_ == kbDel and do {
        if ( $self->{keyDown}{controlKeyState} & kbCtrlShift ) {
          $self->{keyDown}{keyCode} = kbCtrlDel;
        }
        elsif ( $self->{keyDown}{controlKeyState} & kbShift ) {
          $self->{keyDown}{keyCode} = kbShiftDel;
        }
        last;
      };
      $_ == kbIns and do {
        if ( $self->{keyDown}{controlKeyState} & kbCtrlShift ) {
          $self->{keyDown}{keyCode} = kbCtrlIns;
        }
        elsif ( $self->{keyDown}{controlKeyState} & kbShift ) {
          $self->{keyDown}{keyCode} = kbShiftIns;
        }
        last;
      };
    } #/ SWITCH: for ( $self->{keyDown}{...})
  } #/ if ( THardwareInfo->getKeyEvent...)
  else {
    $self->{what} = evNothing;
  }
  return;
} #/ sub getKeyEvent

1

__END__

=pod

=head1 NAME

TUI::Drivers::Event - unified event structure for input handling

=head1 HIERARCHY

  TEvent (value type, tied hash)
    used throughout the event system

=head1 SYNOPSIS

  use TUI::Drivers::Event;

  my $event = TEvent->new;

  if ($event->{what} & evMouse) {
    my $x = $event->{mouse}{where}{x};
    my $y = $event->{mouse}{where}{y};
  }

  if ($event->{what} & evKeyboard) {
    my $key = $event->{keyDown}{keyCode};
  }

=head1 DESCRIPTION

C<TEvent> represents the central event structure used throughout TUI::Vision.
It models all input and message events such as keyboard input, mouse activity,
and broadcast messages.

This type is implemented as a tied hash and is not derived from C<TObject>.
Its structure mirrors the Turbo Vision event union, with the active event
variant selected by the C<what> field.

Depending on the event type, one of the variant substructures is active and
accessible via the corresponding hash key.

=head2 Commonly Used Features

In practice, C<TEvent> is most often used in two ways:

=over

=item *

As the mutable event object passed through C<handleEvent()> chains, where
handlers inspect C<what> and then read/write the active variant
(C<mouse>/C<keyDown>/C<message>).

=item *

As a synthetic event in tests and higher-level components, e.g. creating
keyboard, mouse, broadcast, or command events with C<TEvent->new(...)> and
injecting them into controls/dialogs.

=back

Typical checks branch on C<what> and then access only the matching variant
fields. For example, C<evKeyDown> events commonly use
C<< $event->{keyDown}{charScan}{charCode} >> for incremental search, while
C<evCommand>/C<evBroadcast> paths read C<< $event->{message}{command} >> and
optionally C<infoPtr>/C<infoWord> payload fields.

=head1 EVENT STRUCTURE

A C<TEvent> object exposes the following top-level fields:

=over

=item what

Event type bitmask indicating the active event variant.

=item mouse

Mouse event data, present when C<what> includes C<evMouse>.

=item keyDown

Keyboard event data, present when C<what> includes C<evKeyboard>.

=item message

Message event data, present when C<what> includes C<evMessage>.

=back

Only one variant field is active at a time, determined by the value of
C<what>.

=head1 INTERNAL REPRESENTATION

Internally, C<TEvent> is implemented as a tied hash that models the original
Turbo Vision C++ event union. The active event variant is selected by the value 
of the C<what> field.

Conceptually, the structure can be viewed as follows:

=over

=item *

The C<what> field stores the event type bitmask.

=item *

Exactly one variant structure is active at a time and stored internally.

=item *

Access to variant data is provided through the keys C<mouse>, C<keyDown>, or
C<message>, depending on the event type.

=back

The following conceptual layout illustrates the Perl representation:

  TEvent (tied hash)
    what    => Int
    mouse   => MouseEventType
      where           => TPoint
      eventFlags      => Bool
      buttons         => Int
      controlKeyState => Int

    keyDown => KeyDownEvent
      keyCode          => Int
      charScan         => CharScanType
        charCode       => Int
        scanCode       => Int
      controlKeyState  => Int

    message => MessageEvent
      command  => Int
      infoPtr  => Any
      infoLong => Int
      infoWord => Int
      infoInt  => Int
      infoByte => Int
      infoChar => Str

This representation is an implementation detail. Application code should rely
solely on the documented C<TEvent> fields and must not depend on the internal
tie or storage mechanics.

=head1 CONSTRUCTOR

=head2 new

  my $event = TEvent->new();

Creates a new event object initialized to C<evNothing>.

=head2 new_TEvent

  my $event = new_TEvent();

Factory-style constructor equivalent to C<new>.

=head1 METHODS

=head2 assign

  $event->assign($other);

Copies the contents of another event into this event.

The active event variant is copied as well. Variant data is cloned to avoid
unexpected aliasing when events are reused.

=head2 clone

  my $copy = $event->clone();

Creates a deep copy of the event, including its active variant data.

This method is useful when an event must be preserved beyond the lifetime of
the current event loop iteration.

=head2 dump

  my $string = $event->dump();

Returns a string representation of the event for debugging purposes.

=head2 getKeyEvent

  $event->getKeyEvent();

Retrieves the next keyboard event from the hardware layer and populates the
event structure accordingly.

=head2 getMouseEvent

  $event->getMouseEvent();

Retrieves the next mouse event from the event queue and populates the event
structure accordingly.

=head1 HASH INTERFACE

C<TEvent> implements the C<Tie::Hash> interface. Fields are accessed via normal
hash operations.

Direct deletion or clearing of fields is not supported.

=head1 EVENT VARIANTS

=head2 Mouse events

When C<what> contains C<evMouse>, the C<mouse> field is active and provides:

=over

=item where

Mouse position as a C<TPoint>.

=item buttons

Bitmask of pressed mouse buttons.

=item eventFlags

Additional mouse event flags.

=item controlKeyState

Modifier key state during the mouse event.

=back

=head2 Keyboard events

When C<what> contains C<evKeyboard>, the C<keyDown> field is active and provides:

=over

=item keyCode

Combined key code representing the pressed key.

=item charScan

Character and scan code pair.

=item controlKeyState

Modifier key state during the key press.

=back

=head2 Message events

When C<what> contains C<evMessage>, the C<message> field is active and provides:

=over

=item command

Command identifier.

=item infoPtr

Optional associated object or reference.

=item infoLong

32-bit integer message data.

=item infoWord

16-bit integer message data.

=item infoInt

Native integer message data.

=item infoByte

8-bit integer message data.

=item infoChar

Single character message data.

=back

=head1 USAGE NOTES

C<TEvent> objects are typically allocated once and reused by the event loop.
Event handlers inspect the C<what> field to determine the active variant and
process the corresponding data.

=head1 SEE ALSO

L<TUI::Drivers::EventQueue>,
L<TUI::Drivers::Const>,
L<TUI::Views::View>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution). 

=cut
