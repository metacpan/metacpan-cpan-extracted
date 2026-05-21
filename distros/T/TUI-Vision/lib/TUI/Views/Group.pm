package TUI::Views::Group;
# ABSTRACT: Base class for all group components

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TGroup
  new_TGroup
);

use Devel::StrictMode;
use Scalar::Util qw(
  weaken
  isweak
);
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Objects::Point;
use TUI::Objects::Rect;
use TUI::Drivers::Const qw(
  :evXXXX
);
use TUI::Drivers::Event;
use TUI::Views::Const qw(
  :phaseType
  :selectMode
  :cmXXXX
  :evXXXX
  :hcXXXX
  :ofXXXX
  :sfXXXX
);
use TUI::Views::CommandSet;
use TUI::Views::View;

sub TGroup() { __PACKAGE__ }
sub name() { 'TGroup' }
sub new_TGroup { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $TheTopView;
our $ownerGroup;

# public attributes
has current   => ( is => 'bare' );
has last      => ( is => 'ro' );
has clip      => ( is => 'rw' );
has phase     => ( is => 'ro', default => phFocused );
has buffer    => ( is => 'ro' );
has lockFlag  => ( is => 'rw', default => 0 );
has endState  => ( is => 'rw', default => 0 );

# predeclare private methods
my (
  $invalid,
  $focusView,
  $selectView,
  $findNext,
);

my $lock_value = sub {
  Internals::SvREADONLY( $_[0] => 1 )
    if exists &Internals::SvREADONLY;
};

my $unlock_value = sub {
  Internals::SvREADONLY( $_[0] => 0 )
    if exists &Internals::SvREADONLY;
};

my $weaken = sub {
  # warn join(',' => caller()), "\n";
  &$unlock_value( $_[0] ) if STRICT;
  weaken $_[0];
  &$lock_value( $_[0] ) if STRICT;
};

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{eventMask} = 0xffff;
  $self->{options} |= ofSelectable | ofBuffered;
  $self->{clip} = $self->getExtent();
  weaken( $self->{current} ) if $self->{current};
  &$lock_value( $self->{current} ) if STRICT;
  return;
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Bool $in_global_destruction );
  &$unlock_value( $self->{current} ) if STRICT;
  $self->shutDown() unless $in_global_destruction;
  return;
}

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $p = $self->{last};
  if ( $p ) {
    do {
      $p->hide();
      $p = $p->prev();
    } while ( $p && $p != $self->{last} );

    while ( $p && $self->{last} ) {
      my $T = $p->prev();
      $self->destroy( $p );
      $p = $T; 
    }
  } #/ if ( $p )
  $self->freeBuffer();
  $self->current( undef );
  $self->SUPER::shutDown();
  return;
} #/ sub shutDown

sub execView {    # $int ($p|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $p ) = $sig->( @_ );
  alias: for $p ( $_[1] ) {
  return cmCancel
    unless $p;

  my $saveOptions = $p->{options};
  my $saveOwner = $p->{owner};
  my $saveTopView = $TheTopView;
  my $saveCurrent = $self->{current};
  my $saveCommands = TCommandSet->new();
  $self->getCommands( $saveCommands );
  weaken( $TheTopView = $p );
  $p->{options} &= ~ofSelectable;
  $p->setState( sfModal, true );
  $self->setCurrent( $p, enterSelect );
  $self->insert( $p )
    unless $saveOwner;
  my $retval = $p->execute();
  $self->remove( $p )
    unless $saveOwner;
  $self->setCurrent( $saveCurrent, leaveSelect );
  $p->setState( sfModal, false );
  $p->{options} = $saveOptions;
  weaken( $TheTopView = $saveTopView );
  $self->setCommands( $saveCommands );
  return $retval;
  } #/ alias:
} #/ sub execView

sub execute {    # $int ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  do {
    $self->{endState} = 0;
    do {
      my $e = TEvent->new();
      $self->getEvent( $e );
      $self->handleEvent( $e );
      if ( $e->{what} != evNothing ) {
        $self->eventError( $e );
      }
    } while ( !$self->{endState} );
  } while ( !$self->valid( $self->{endState} ) );
  return $self->{endState};
}

my $doAwaken = sub {    # void ($v, $p)
  assert ( @_ == 2 );
  assert ( is_Object $_[0] );
  $_[0]->awaken();
  return;
};

sub awaken {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->forEach( $doAwaken );
  return;
}

sub insertView {    # void ($p, $Target|undef)
  state $sig = signature(
    method => Object,
    pos    => [Object, Maybe[Object]],
  );
  my ( $self, $p, $Target ) = $sig->( @_ );
  $p->owner( $self );
  if ( $Target ) {
    assert ( $Target->{owner} == $self );
    assert ( $self->{last} );

    # Check if the cycle needs to be weakened again.
    my $weak_cycle = $self->{last} == $Target;

    # Insert new element (as originally)
    $Target = $Target->prev();
    $p->next( $Target->{next} );
    $Target->next( $p );

    q/*
      warn "\t\$Target => $Target\n";
      warn "\t\$p => $p\n";
      my $s = $self->{last};
      while ( $s->{next} && $s->{next} != $self->{last} ) {
        warn "\t\t\$" . $s . "->{next} => \\%" . $s->{next} . "\n";
        $s = $s->{next};
      }
      warn "\t\t\$" . $s . "->{next} => " . ( $s->{next} || 'undef' ) . "\n";
    */ if 0;

    # Set new weak reference if necessary
    &$weaken( $self->{last}->prev()->{next} ) if $weak_cycle;
  }
  else {
    if ( !$self->{last} ) {
      $p->next( $p );
    }
    else {
      $p->next( $self->{last}{next} );
      $self->{last}->next( $p );
    }
    $self->{last} = $p;

    # Set new weak reference
    &$weaken( $p->prev()->{next} );
  } #/ else [ if ( $Target ) ]
  q/*
    require Devel::Cycle; 
    warn $_ if local $_ = Devel::Cycle::find_cycle( $p );
  */ if 0;
  return;
} #/ sub insertView

sub remove {    # void ($p|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $p ) = $sig->( @_ );
  if ( $p ) {
    my $saveState = $p->{state};
    $p->hide();
    $self->removeView( $p );
    $p->owner( undef );
    $p->next( undef );
    if ( $saveState & sfVisible ) {
      $p->show();
    }
  } #/ if ( $p )
  return;
} #/ sub remove

# The following subroutine was taken from the framework
# "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
#
# Copyright 2019-2021 by magiblot <magiblot@hotmail.com>
#
# I<tgrmv.cpp>
sub removeView {    # void ($p)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $p ) = $sig->( @_ );
  if ( $self->{last} ) {
    no warnings qw( uninitialized numeric );
    my $s = $self->{last};

    # Check if the cycle needs to be weakened again.
    my $weak_cycle = $s == $p || $s == $p->{next};

    while ( $s->{next} != $p ) {
      return
        if $s->{next} == $self->{last};
      $s = $s->{next};
    }
    $s->next( $p->{next} );

    # Weaken the {next} field of the removed entry.
    &$weaken( $p->{next} ) unless isweak $p->{next};

    if ( $p == $self->{last} ) {
      if ( $p == $p->{next} ) {
        $self->{last} = undef;
        return;
      }
      $self->{last} = $s;
    } 

    # Set new weak reference if necessary
    &$weaken( $self->{last}->prev()->{next} ) if $weak_cycle;
    q/*
      require Devel::Cycle; 
      warn $_ if local $_ = Devel::Cycle::find_cycle( $p );
    */ if 0;
  } #/ if ( $self->{last} )
  return;
} #/ sub removeView

sub resetCurrent {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->setCurrent( $self->firstMatch( sfVisible, ofSelectable ),
    normalSelect );
  return;
}

sub setCurrent {    # void ($p|undef, $mode)
  no warnings qw( uninitialized numeric );
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object], PositiveOrZeroInt],
  );
  my ( $self, $p, $mode ) = $sig->( @_ );
  return 
    if $self->{current} == $p;

  $self->lock();
  $self->$focusView( $self->{current}, false );
  $self->{current}->setState( sfSelected, false )
    if $mode != enterSelect 
    && $self->{current};
  $p->setState( sfSelected, true ) 
    if $mode != leaveSelect && $p;
  $p->setState( sfFocused, true ) 
    if ( $self->{state} & sfFocused ) && $p;
  $self->current( $p );
  $self->unlock();
  return;
} #/ sub setCurrent

sub selectNext {    # void ($forwards)
  state $sig = signature(
    method => Object,
    pos    => [Bool],
  );
  my ( $self, $forwards ) = $sig->( @_ );
  if ( $self->{current} ) {
    my $p = $self->$findNext( $forwards );
    $p->select() if $p;
  }
  return;
} #/ sub selectNext

sub firstThat {    # $view|undef (\&Test, @args)
  state $sig = signature(
    method => Object,
    pos    => [
      CodeRef, 
      ArrayRef, { slurpy => 1 }
    ],
  );
  my ( $self, $func, $args ) = $sig->( @_ );
  my $temp = $self->{last};
  return undef
    unless $temp;

  no warnings qw( uninitialized numeric );
  do {
    $temp = $temp->{next};
    return $temp
      if $func->( $temp, @$args );
  } while ( $temp != $self->{last} );
  return undef;
} #/ sub firstThat

sub focusNext {    # $bool ($forwards)
  state $sig = signature(
    method => Object,
    pos    => [Bool],
  );
  my ( $self, $forwards ) = $sig->( @_ );
  my $p = $self->$findNext( $forwards );
  return $p ? $p->focus() : true;
}

sub forEach {    # void (\&action, @args)
  state $sig = signature(
    method => Object,
    pos    => [
      CodeRef, 
      ArrayRef, { slurpy => 1 }
    ],
  );
  my ( $self, $func, $args ) = $sig->( @_ );
  my $term = $self->{last};
  my $temp = $self->{last};
  return 
    unless $temp;

  no warnings qw( uninitialized numeric );
  my $next = $temp->{next};
  do {
    $temp = $next;
    $next = $temp->{next};
    $func->( $temp, @$args );
  } while ( $temp != $term );
  return;
} #/ sub forEach

sub insert {    # void ($p|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $p ) = $sig->( @_ );
  $self->insertBefore( $p, $self->first() );
  return;
}

sub insertBefore {    # void ($p, $Target|undef)
  no warnings qw( uninitialized numeric );
  state $sig = signature(
    method => Object,
    pos    => [Object, Maybe[Object]],
  );
  my ( $self, $p, $Target ) = $sig->( @_ );
  if ( $p && !$p->{owner} && ( !$Target || $Target->{owner} == $self ) ) {
    $p->{origin}{x} = ( $self->{size}{x} - $p->{size}{x} ) >> 1
      if $p->{options} & ofCenterX;
    $p->{origin}{y} = ( $self->{size}{y} - $p->{size}{y} ) >> 1
      if $p->{options} & ofCenterY;
    my $saveState = $p->{state};
    $p->hide();
    $self->insertView( $p, $Target );
    $p->show()
      if $saveState & sfVisible;
    $p->setState( sfActive, true )
      if $saveState & sfActive;
  } #/ if ( $p && !$p->owner(...))
} #/ sub insertBefore

sub current {    # $view|undef (|$view|undef)
  state $sig = signature(
    method => Object,
    pos    => [
      Maybe[Object], { optional => 1 },
    ],
  );
  my ( $self, $view ) = $sig->( @_ );
  goto SET if @_ > 1;
  GET: {
    return $self->{current};
  }
  SET: {
    &$unlock_value( $self->{current} ) if STRICT;
    weaken $self->{current}
      if $self->{current} = $view;
    &$lock_value( $self->{current} ) if STRICT;
    return;
  }
}

sub at {    # $view|undef ($index)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $index ) = $sig->( @_ );
  my $temp = $self->{last};
  while ( $index-- > 0 ) {
    $temp = $temp->{next};
  }
  return $temp;
} #/ sub at

sub firstMatch {    # $view|undef ($aState, $aOptions)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, PositiveOrZeroInt],
  );
  my ( $self, $aState, $aOptions ) = $sig->( @_ );
  return undef 
    unless $self->{last};

  no warnings qw( uninitialized numeric );
  my $temp = $self->{last};
  while ( 1 ) {
    return $temp
      if ( $temp->{state} & $aState ) == $aState
      && ( $temp->{options} & $aOptions ) == $aOptions;
    $temp = $temp->{next};
    return undef 
      if $temp == $self->{last};
  }
} #/ sub firstMatch

sub indexOf {    # $int ($p)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $p ) = $sig->( @_ );
  return 0 
    unless $self->{last};

  no warnings qw( uninitialized numeric );
  my $index = 0;
  my $temp  = $self->{last};
  do {
    $index++;
    $temp = $temp->{next};
  } while ( $temp != $p && $temp != $self->{last} );
  return $temp == $p ? $index : 0;
} #/ sub indexOf

sub matches {    # $bool ($p)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  $sig->( @_ );
  ...
}

sub first {    # $view|undef ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{last} ? $self->{last}{next} : undef;
}

my $doExpose = sub {    # void ($p, \$enable)
  my ( $p, $enable ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $p );
  assert ( is_ScalarRef $enable );
  $p->setState( sfExposed, $$enable )
    if $p->state & sfVisible;
  return;
};

my $doSetState = sub {    # void ($p, \%b)
  my ( $p, $b ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $p );
  assert ( is_HashLike $b );
  $p->setState( $b->{st}, $b->{en} );
  return;
};

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );
  my $sb = {
    st => $aState, 
    en => $enable,
  };

  $self->SUPER::setState( $aState, $enable );

  if ( $aState & ( sfActive | sfDragging ) ) {
    $self->lock();
    $self->forEach( $doSetState, $sb );
    $self->unlock();
  }

  if ( $aState & sfFocused ) {
    $self->{current}->setState( sfFocused, $enable ) 
      if $self->{current};
  }

  if ( $aState & sfExposed ) {
    $self->forEach( $doExpose, \$enable );
    $self->freeBuffer() 
      unless $enable;
  }
  return;
} #/ sub setState

my $doHandleEvent = sub {    # void ($p|undef, \%s)
  my ( $p, $s ) = @_;
  assert ( @_ == 2 );
  assert ( !defined $p or is_Object $p );
  assert ( is_HashLike $s );
  return unless $p;
  return
    if ( $p->{state} & sfDisabled )
    && ( $s->{event}{what} & ( positionalEvents | focusedEvents ) );

  SWITCH: for ( $s->{grp}{phase} ) {
    $_ == phPreProcess and do {
      return
        unless $p->{options} & ofPreProcess;
      last;
    };
    $_ == phPostProcess and do {
      return
        unless $p->{options} & ofPostProcess;
      last;
    };
  }
  $p->handleEvent( $s->{event} )
    if $s->{event}{what} & $p->{eventMask};
  return;
};

my $hasMouse = sub {    # $bool ($p, $s)
  my ( $p, $s ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $p );
  assert ( is_HashLike $s );
  return $p->containsMouse( $s );
};

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );

  my $hs = { 
    event => $event, 
    grp => $self
  };

  if ( $event->{what} & focusedEvents ) {
    $self->{phase} = phPreProcess;
    $self->forEach( $doHandleEvent, $hs );

    $self->{phase} = phFocused;
    &$doHandleEvent( $self->{current}, $hs );

    $self->{phase} = phPostProcess;
    $self->forEach( $doHandleEvent, $hs );
  } #/ if ( $event->{what} & ...)
  else {
    $self->{phase} = phFocused;
    if ( $event->{what} & positionalEvents ) {
      # get pointer to topmost view holding mouse
      my $p = $self->firstThat( $hasMouse, $event );
      if ( $p ) {
        # we have a view; send event to it
        &$doHandleEvent( $p, $hs );
      }
      elsif ( $event->{what} == evMouseDown ) {
        # it was a mouse click and we don't have a view,
        # so sound a beep.
        if ( eval { require Win32::Sound } ) {
          Win32::Sound::Play("SystemDefault");
        } 
        else {
          # May not work, depending on the nature of the terminal.
          print "\a";
        }
      }
    } #/ if ( $event->{what} & ...)
    else {
      $self->forEach( $doHandleEvent, $hs );
    }
  } #/ else [ if ( $event->{what} & ...)]
  return;
} #/ sub handleEvent

sub drawSubViews {    # void ($p|undef, $bottom|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object], Maybe[Object]],
  );
  my ( $self, $p, $bottom ) = $sig->( @_ );
  no warnings qw( uninitialized numeric );
  while ( $p != $bottom ) {
    $p->drawView();
    $p = $p->nextView();
  }
  return;
}

my $doCalcChange = sub {    # void ($p, $d)
  my ( $p, $d ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $p );
  assert ( is_Object $d );
  my $r = TRect->new();
  $p->calcBounds( $r, $d );
  $p->changeBounds( $r );
  return;
};

sub changeBounds {    # void ($self, $bounds)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $bounds ) = $sig->( @_ );
  my $d = TPoint->new(
    x => ( $bounds->{b}{x} - $bounds->{a}{x} ) - $self->{size}{x},
    y => ( $bounds->{b}{y} - $bounds->{a}{y} ) - $self->{size}{y},
  );
  if ( $d->{x} == 0 && $d->{y} == 0 ) {
    $self->setBounds( $bounds );
    $self->drawView();
  }
  else {
    $self->freeBuffer();
    $self->setBounds( $bounds );
    $self->{clip} = $self->getExtent();
    $self->getBuffer();
    $self->lock();
    $self->forEach( $doCalcChange, $d );
    $self->unlock();
  }
  return;
} #/ sub changeBounds

my $addSubviewDataSize = sub {    # void ($p, \$T)
  my ( $p, $T ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $p );
  assert ( is_ScalarRef $T );
  $$T += $p->dataSize();
};

sub dataSize {    # $int ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $T = 0;
  $self->forEach( $addSubviewDataSize, \$T );
  return $T;
}

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  my $i = 0;
  if ( $self->{last} ) {
    my $v = $self->{last};
    do {
      $v->getData( sub { \@_ }->( @$rec[ $i .. $#$rec ] ) );
      $i += $v->dataSize();
      $v = $v->prev();
    } while ( $v != $self->{last} );
  }
  return;
} #/ sub getData

sub setData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  my $i = 0;
  if ( $self->{last} ) {
    my $v = $self->{last};
    do {
      $v->setData( sub { \@_ }->( @$rec[ $i .. $#$rec ] ) );
      $i += $v->dataSize();
      $v = $v->prev();
    } while ( $v != $self->{last} );
  }
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( !$self->{buffer} ) {
    $self->getBuffer();
    if ( $self->{buffer} ) {
      $self->{lockFlag}++;
      $self->redraw();
      $self->{lockFlag}--;
    }
  }
  if ( $self->{buffer} ) {
    $self->writeBuf( 0, 0, $self->{size}{x}, $self->{size}{y}, $self->{buffer} );
  }
  else {
    $self->{clip} = $self->getClipRect();
    $self->redraw();
    $self->{clip} = $self->getExtent();
  }
  return;
} #/ sub draw

sub redraw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->drawSubViews( $self->first(), undef );
  return;
}

sub lock {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{lockFlag}++ 
    if $self->{buffer} || $self->{lockFlag};
  return;
}

sub unlock {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->drawView() 
    if $self->{lockFlag} && --$self->{lockFlag} == 0;
  return;
}

sub resetCursor {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{current}->resetCursor() 
    if $self->{current};
  return;
}

sub endModal {    # void ($command)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $command ) = $sig->( @_ );
  if ( $self->{state} & sfModal ) {
    $self->{endState} = $command;
  }
  else {
    $self->SUPER::endModal( $command );
  }
  return;
}

sub eventError {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  if ( $self->{owner} ) {
    $self->{owner}->eventError( $event );
  }
  return;
}

sub getHelpCtx {    # $int ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $h = hcNoContext;
  $h = $self->{current}->getHelpCtx()
    if $self->{current};
  $h = $self->SUPER::getHelpCtx()
    if $h == hcNoContext;
  return $h;
}

my $isInvalid = sub {    # $bool ($p, \$command)
  my ( $p, $command ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $p );
  assert ( is_ScalarRef $command );
  return !$p->valid( $$command );
};

sub valid {    # $bool ($command)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $command ) = $sig->( @_ );
  if ( $command == cmReleasedFocus ) {
    if ( $self->{current}
      && ( $self->{current}{options} & ofValidate )
    ) {
      return $self->{current}->valid( $command );
    }
    else {
      return true;
    }
  }
  return !$self->firstThat( $isInvalid, \$command );
}

sub freeBuffer {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( ( $self->{options} & ofBuffered ) && $self->{buffer} ) {
    $self->{buffer} = undef;
  }
  return;
}

sub getBuffer {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{buffer} = [ (0) x ( $self->{size}{x} * $self->{size}{y} * 2 ) ]
    if ( $self->{state} & sfExposed )
      && ( $self->{options} & ofBuffered )
      && !$self->{buffer};
  return;
}

$focusView = sub {    # void ($p|undef, $enable)
  my ( $self, $p, $enable ) = @_;
  assert ( @_ == 3 );
  assert ( !defined $p or is_Object $p );
  assert ( is_Bool $enable );
  $p->setState( sfFocused, $enable ) 
    if ( $self->{state} & sfFocused ) && $p;
  return;
};

$selectView = sub {    # void ($p, $enable)
  my ( $self, $p, $enable ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $p );
  assert ( is_Bool $enable );
  $p->setState( sfSelected, $enable )
    if $p;
  return;
};

$findNext = sub {
  my ( $self, $forwards ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Bool $forwards );
  my $p      = $self->{current};
  my $result = undef;
  if ( $p ) {
    do {
      $p = $forwards ? $p->{next} : $p->prev();
    } while (
      !(
        ( ( $p->{state} & ( sfVisible | sfDisabled ) ) == sfVisible )
        && ( $p->{options} & ofSelectable )
      )
      && ( $p != $self->{current} )
    );
    $result = $p 
      if $p != $self->{current};
  } #/ if ( $p )
  return $result;
};

1

__END__

=pod

=head1 NAME

TUI::Views::Group - base class for grouping views in TUI::Vision

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TWindow
          TDialog
        TDeskTop
        TProgram

=head1 SYNOPSIS

  use TUI::Views;

  my $group = TGroup->new(bounds => $bounds);
  $group->insert($view);
  $group->remove($view);

=head1 DESCRIPTION

C<TGroup> is the structural backbone of TUI::Vision's view hierarchy. It
manages collections of subviews and coordinates drawing, event dispatch, and
modal execution.

A group itself is an invisible view. Its visual representation is defined
entirely by its subviews. Dialogs, windows, and the desktop are all implemented
as specialized groups.

TGroup is responsible for maintaining Z-order, dispatching events according to
focus and position, and coordinating modal execution via C<execView> and
C<execute>. During event processing, the C<phase> attribute allows subviews to
determine in which processing stage their handlers are invoked.

To improve drawing performance, groups may use an internal buffer. In this
case, screen updates should be bracketed by C<lock> and C<unlock> calls to
avoid flicker.

=head2 Commonly Used Features

In typical application code, only a small subset of the API is used directly:
subviews are added with C<insert>, modal views are executed with C<execView>,
and dialog-style state transfer is handled through C<getData> and C<setData>.

Most remaining methods are primarily infrastructure for descendants such as
C<TWindow>, C<TDialog>, and C<TDeskTop>. Direct instantiation of C<TGroup>
itself is therefore uncommon outside framework-level or advanced custom view
implementations.

=head1 VARIABLES

The following global variables are used internally by C<TGroup> to track
view hierarchy state.

=head2 $TheTopView

Holds a reference to the currently active top-level view.
This variable is used during focus and event handling.

=head2 $ownerGroup

Holds a reference to the group currently owning a view.
It is used internally to manage parent-child relationships between views.

=head1 ATTRIBUTES

The following attributes represent the internal state of the group and its
relationship to contained subviews. Attributes marked as read-only are managed
internally and should not be modified directly.

=over

=item current

Pointer to the currently selected subview (I<TView>).  
This attribute is managed internally.

=item last

Read-only pointer to the last subview in the Z-ordered view list.

=item clip

Clipping rectangle of the group (I<TRect>).  
Defines the drawable region for subviews.

=item phase

Read-only event processing phase indicator (I<Int>).  
Used by subviews to determine the context in which their C<handleEvent> method
is invoked.

=item buffer

Read-only reference to the internal screen cache buffer.  
Used to speed up redraw operations when buffering is enabled.

=item lockFlag

Lock counter used to suppress screen updates while batch operations are
performed.

=item endState

Command value used to terminate modal execution.

=back

=head1 CONSTRUCTOR

=head2 new

  my $group = TGroup->new(bounds => $bounds);

Creates and initializes a new group with the specified bounds.

=over

=item bounds

Bounding rectangle of the group (I<TRect>).

=back

=head2 new_TGroup

  my $group = new_TGroup($bounds);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with the C<bounds> parameter
and is provided for compatibility with traditional Turbo Vision construction
patterns.

=head1 DESTRUCTOR

=head1 METHODS

The following methods implement group-specific behavior for managing subviews,
event dispatch, drawing, and modal execution.

=head2 at

  my $view | undef = $group->at($index);

Returns the subview at the specified index.

=head2 insert

  $group->insert($view);

Inserts a view into the group. The view becomes part of the group's Z-ordered
subview list.

=head2 insertBefore

  $group->insertBefore($view, $target | undef);

Inserts a view before the specified target view. If C<$target> is omitted, the
view is inserted at the back of the Z-order.

=head2 insertView

  $group->insertView($view, $target | undef);

Internal insertion helper used by group management routines.

=head2 remove

  $group->remove($view | undef);

Removes a view from the group.

=head2 removeView

  $group->removeView($view);

Removes a view from the group and updates internal bookkeeping.

=head2 indexOf

  my $index = $group->indexOf($view);

Returns the index of the specified view within the group.

=head2 first

  my $view | undef = $group->first();

Returns the topmost subview in the group.

=head2 last

  my $view | undef = $group->last();

Returns the bottommost subview in the group.

=head2 firstMatch

  my $view | undef = $group->firstMatch($state, $options);

Returns the first subview matching the specified state and options.

=head2 firstThat

  my $view | undef = $group->firstThat(\&test, @args);

Returns the first subview for which the supplied test function returns true.

=head2 forEach

  $group->forEach(\&action, @args);

Applies the given action to each subview in Z-order.

=head2 current

  my $view | undef = $group->current();
  $group->current($view);

Returns or sets the currently selected subview.

=head2 setCurrent

  $group->setCurrent($view, $mode);

Sets the currently focused subview using the specified selection mode.

=head2 selectNext

  $group->selectNext($forwards);

Selects the next or previous subview in Z-order.

=head2 draw

  $group->draw();

Draws the group. If buffering is enabled, cached contents are copied to the
screen.

=head2 drawSubViews

  $group->drawSubViews($from | undef, $bottom | undef);

Draws subviews within the specified Z-order range.

=head2 redraw

  $group->redraw();

Forces a redraw of the group, bypassing cached output.

=head2 lock

  $group->lock();

Locks the group to suppress screen updates during batch operations.

=head2 unlock

  $group->unlock();

Unlocks the group and flushes buffered screen updates.

=head2 freeBuffer

  $group->freeBuffer();

Releases the internal cache buffer.

=head2 getBuffer

  my $buffer = $group->getBuffer();

Returns the internal buffer used for cached drawing.

=head2 handleEvent

  $group->handleEvent($event);

Dispatches events to the appropriate subview based on focus and event type.

=head2 eventError

  $group->eventError($event);

Handles events that could not be processed by any subview.

=head2 matches

  my $bool = $group->matches($view);

Returns true if the specified view belongs to this group.

=head2 execView

  my $command = $group->execView($view);

Executes a modal view and returns the command that terminated the modal state.

=head2 execute

  my $command = $group->execute();

Runs the group's event loop until modal execution ends.

=head2 endModal

  $group->endModal($command);

Terminates modal execution and causes C<execute> or C<execView> to return.

=head2 dataSize

  my $size = $group->dataSize();

Returns the combined data size of all subviews.

=head2 getData

  $group->getData(\$record);

Copies subview data into the supplied record.

=head2 setData

  $group->setData(\$record);

Restores subview data from the supplied record.

=head2 valid

  my $bool = $group->valid($command);

Checks whether the group and all subviews are in a valid state.

=head2 shutDown

  $group->shutDown();

Shuts down the group and releases associated resources.

=head1 SEE ALSO

L<TUI::Views::View>, L<TUI::Views::Window>, L<TUI::Dialogs::Dialog>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

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
