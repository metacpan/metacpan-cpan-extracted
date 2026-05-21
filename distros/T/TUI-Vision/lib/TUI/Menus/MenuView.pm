package TUI::Menus::MenuView;
# ABSTRACT: Abstract class for menu bars and menu boxes

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMenuView
  new_TMenuView
);

use Devel::StrictMode;
use Scalar::Util qw( weaken );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Drivers::Const qw( 
  :evXXXX
  :kbXXXX
);
use TUI::Drivers::Util qw(
  ctrlToArrow
  getAltChar
);
use TUI::Drivers::Event;
use TUI::Objects::Rect;
use TUI::Views::Const qw( 
  :cmXXXX
  hcNoContext
);
use TUI::Views::Palette;
use TUI::Views::View;
use TUI::Menus::Const qw( 
  :menuAction
  cpMenuView
);

sub TMenuView() { __PACKAGE__ }
sub name() { 'TMenuView' }
sub new_TMenuView { __PACKAGE__->from(@_) }

extends TView;

# protected attributes
has parentMenu => ( is => 'bare' );
has menu       => ( is => 'ro' );
has current    => ( is => 'bare' );

# predeclare private methods
my (
  $nextItem,
  $prevItem,
  $trackKey,
  $mouseInOwner,
  $mouseInMenus,
  $trackMouse,
  $topMenu,
  $updateMenu,
  $do_a_select,
  $findHotKey,
);

my $lock_value = sub {
  Internals::SvREADONLY( $_[0] => 1 )
    if exists &Internals::SvREADONLY;
};

my $unlock_value = sub {
  Internals::SvREADONLY( $_[0] => 0 )
    if exists &Internals::SvREADONLY;
};

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      menu       => Object, { optional => 1, alias => 'aMenu' },
      parentMenu => Object, { optional => 1, alias => 'aParent' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  assert ( !exists $args->{parentMenu} or exists $args->{menu} );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{eventMask} |= evBroadcast;
  weaken( $self->{parentMenu} )        if $self->{parentMenu};
  weaken( $self->{current} )           if $self->{current};
  &$lock_value( $self->{parentMenu} ) if STRICT;
  &$lock_value( $self->{current} )    if STRICT;
  return;
}

sub from {    # $obj ($bounds, |$aMenu, |$aParent);
  state $sig = signature(
    method => 1,
    pos => [
      Object,
      Object, { optional => 1 },
      Object, { optional => 1 },
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  SWITCH: for ( scalar @args ) {
    $_ == 1 and return $class->new( bounds => $args[0] );
    $_ == 2 and return $class->new( bounds => $args[0], menu => $args[1] );
    $_ == 3 and return $class->new( bounds => $args[0], menu => $args[1], 
      parentMenu => $args[2] );
  }
  return;
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  &$unlock_value( $self->{parentMenu} ) if STRICT;
  &$unlock_value( $self->{current} )    if STRICT;
  return;
}

# The following subroutine was taken from the framework
# "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
#
# Copyright 2019-2021 by magiblot <magiblot@hotmail.com>
#
# I<tmnuview.cpp>
sub execute {    # $int ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $autoSelect     = false;
  my $firstEvent     = true;
  my $action         = 0;
  my $result         = 0;
  my $itemShown      = undef;
  my $target         = undef;
  my $lastTargetItem = undef;
  my $r              = TRect->new();
  my $e              = TEvent->new();
  my $mouseActive    = false;

  $self->current( $self->{menu}{deflt} );
  $mouseActive = 0;
  do {
    $action = doNothing;
    $self->getEvent( $e );
    SWITCH: for ( $e->{what} ) {
      $_ == evMouseDown and do {
        if ( $self->mouseInView( $e->{mouse}{where} ) 
          || $self->$mouseInOwner( $e ) 
        ) {
          $self->$trackMouse( $e, \$mouseActive );
          # autoSelect makes it possible to open the selected submenu directly
          # on a MouseDown event. This should be avoided, however, when said
          # submenu was just closed by clicking on its name, or when this is
          # not a menu bar.
          if ( $self->{size}{y} == 1 ) {
            no warnings 'uninitialized';
            $autoSelect = !$self->{current}
              || $lastTargetItem != $self->{current};
          }
          # A submenu will close if the MouseDown event takes place on the
          # parent menu, except when this submenu has just been opened.
          elsif ( !$firstEvent && $self->$mouseInOwner( $e ) ) {
            $action = doReturn;
          }
        }
        else {
          $action = doReturn;
        }
        last;
      };
      $_ == evMouseUp and do {
        $self->$trackMouse( $e, \$mouseActive );
        if ( $self->$mouseInOwner( $e ) ) {
          $self->current( $self->{menu}{deflt} );
        }
        elsif ( $self->{current} ) {
          if ( $self->{current}{name} ) {
            no warnings 'uninitialized';
            if ( $self->{current} != $lastTargetItem ) {
              $action = doSelect;
            }
            elsif ( $self->{size}{y} == 1 ) {
              # If a menu bar entry was closed, exit and stop listening
              # for events.
              $action = doReturn;
            }
            else {
              # MouseUp won't open up a submenu that was just closed by 
              # clicking on its name.
              $action = doNothing;
              # But the next one will.
              $lastTargetItem = undef;
            }
          } #/ if ( $self->{current}{...})
        } #/ elsif ( $self->{current} )
        elsif ( $mouseActive && !$self->mouseInView( $e->{mouse}{where} ) ) {
          $action = doReturn;
        }
        elsif ( $self->{size}{y} == 1 ) {
          # When MouseUp happens inside the Box but not on a highlightable
          # entry (e.g. on a margin, or a separator), either the default or the
          # first entry will be automatically highlighted. This was added in
          # Turbo Vision 2.0. But this doesn't make sense in a menu bar, which
          # was the original behavior.
          $self->current(
            $self->{menu}{deflt}
            ? $self->{menu}{deflt}
            : $self->{menu}{items}
          );
          $action = doNothing;
        } #/ elsif ( $self->{size}{y} ...)
        last;
      };
      $_ == evMouseMove and do {
        if ( $e->{mouse}{buttons} ) {
          $self->$trackMouse( $e, \$mouseActive );
          if ( !( $self->mouseInView( $e->{mouse}{where} ) 
              || $self->$mouseInOwner( $e ) 
            )
            && $self->$mouseInMenus( $e ) )
          {
            $action = doReturn;
          }
        }
        last;
      };
      $_ == evKeyDown and do {
        SWITCH: for my $key ( ctrlToArrow( $e->{keyDown}{keyCode} ) ) {
          $key == kbUp || 
          $key == kbDown and do {
            if ( $self->{size}{y} != 1 ) {
              $self->$trackKey( $key == kbDown );
            }
            elsif ( $e->{keyDown}{keyCode} == kbDown ) {
              $autoSelect = true;
            }
            last;
          };
          $key == kbLeft || 
          $key == kbRight and do {
            if ( !$self->{parentMenu} ) {
              $self->$trackKey( $key == kbRight );
            }
            else {
              $action = doReturn;
            }
            last;
          };
          $key == kbHome || 
          $key == kbEnd and do {
            if ( $self->{size}{y} != 1 ) {
              $self->current( $self->{menu}{items} );
              $self->$trackKey( false )
                if $e->{keyDown}{keyCode} == kbEnd;
            }
            last;
          };
          $key == kbEnter and do {
            $autoSelect = true 
              if $self->{size}{y} == 1;
            $action = doSelect;
            last;
          };
          $key == kbEsc and do {
            $action = doReturn;
            $self->clearEvent( $e )
              if !$self->{parentMenu} || $self->{parentMenu}{size}{y} != 1;
            last;
          };
          DEFAULT: {
            $target = $self;
            my $ch = getAltChar( $e->{keyDown}{keyCode} );
            $ch = $e->{keyDown}{charScan}{charCode} 
              unless $ch;
            $target = $self->$topMenu()
              if $ch;
            my $p = $target->findItem( $ch );
            if ( !$p ) {
              $p = $self->$topMenu()->hotKey( $e->{keyDown}{keyCode} );
              if ( $p && TView->commandEnabled( $p->{command} ) ) {
                $result = $p->{command};
                $action = doReturn;
              }
            }
            elsif ( $target == $self ) {
              $autoSelect = true 
                if $self->{size}{y} == 1;
              $action = doSelect;
              $self->current( $p );
            }
            elsif ( $self->{parentMenu} != $target 
              || $self->{parentMenu}{current} != $p 
            ) {
              $action = doReturn;
            }
          }
        }
        last;
      };
      $_ == evCommand and do {
        if ( $e->{message}{command} == cmMenu ) {
          $autoSelect = false;
          $lastTargetItem = undef;
          $action = doReturn
            if $self->{parentMenu};
        }
        else {
          $action = doReturn;
        }
        last;
      };
    }

    {
      no warnings 'uninitialized';
      # If a submenu was closed by clicking on its name, and the mouse is 
      # dragged to another menu entry, then the submenu will be opened the next 
      # time it is hovered over.
      if ( $lastTargetItem != $self->{current} ) {
        $lastTargetItem = undef;
      }

      if ( $itemShown != $self->{current} ) {
        $itemShown = $self->{current};
        $self->drawView();
      }
    }

    if ( ( $action == doSelect || ( $action == doNothing && $autoSelect ) )
      && $self->{current}
      && $self->{current}{name}
    ) {
      if ( $self->{current}{command} == 0 && !$self->{current}{disabled} ) {
        if ( $e->{what} & ( evMouseDown | evMouseMove ) ) {
          $self->putEvent( $e );
        }
        $r = $self->getItemRect( $self->{current} );
        $r->{a}{x} = $r->{a}{x} + $self->{origin}{x};
        $r->{a}{y} = $r->{b}{y} + $self->{origin}{y};
        $r->{b} = $self->{owner}{size};
        $r->{a}{x}-- 
          if $self->{size}{y} == 1;
        $target = $self->$topMenu()->newSubView( 
          $r, $self->{current}{subMenu}, $self 
        );
        $result = $self->{owner}->execView( $target );
        $self->destroy( $target );
        weaken( $lastTargetItem = $self->{current} );
        $self->{menu}->deflt( $self->{current} );
      } #/ if ( $self->{current}{...})
      elsif ( $action == doSelect ) {
        $result = $self->{current}{command};
      }
    } #/ if ( ( $action == doSelect...))

    if ( $result && TView->commandEnabled( $result ) ) {
      $action = doReturn;
      $self->clearEvent( $e );
    }
    else {
      $result = 0;
    }

    $firstEvent = false;
  } while ( $action != doReturn );

  if ( $e->{what} != evNothing
    && ( $self->{parentMenu} || $e->{what} == evCommand )
  ) {
    $self->putEvent( $e );
  }
  if ( $self->{current} ) {
    $self->{menu}->deflt( $self->{current} );
    $self->current( undef );
    $self->drawView();
  }
  return $result;
} #/ sub execute

sub findItem {    # $menuItem|undef ($ch)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $ch ) = $sig->( @_ );
  assert ( length $ch == 1 );
  $ch = uc( $ch );
  my $p = $self->{menu}{items};
  while ( $p ) {
    if ( $p->{name} && !$p->{disabled} ) {
      my $loc = index( $p->{name}, '~' );
      if ( $loc != -1 && uc( substr( $p->{name}, $loc + 1, 1 ) ) eq $ch ) {
        return $p;
      }
    }
    $p = $p->{next};
  }
  return undef;
} #/ sub findItem

sub getItemRect {    # $rect ($item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $item ) = $sig->( @_ );
  return TRect->new();
}

sub getHelpCtx {    # $int ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $c = $self;

  while ( $c 
    && ( !$c->{current}
      || $c->{current}{helpCtx} == hcNoContext
      || !$c->{current}{name} )
  ) {
    $c = $c->{parentMenu};
  }

  return $c
    ? $c->{current}{helpCtx}
    : hcNoContext;
} #/ sub getHelpCtx

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new( 
    data => cpMenuView, 
    size => length( cpMenuView ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  if ( $self->{menu} ) {
    SWITCH: for ( $event->{what} ) {
      $_ == evMouseDown and do {
        $self->$do_a_select( $event );
        last;
      };
      $_ == evKeyDown and do {
        if ( $self->findItem( getAltChar( $event->{keyDown}{keyCode} ) ) ) {
          $self->$do_a_select( $event );
        }
        else {
          my $p = $self->hotKey( $event->{keyDown}{keyCode} );
          if ( $p && TView->commandEnabled( $p->{command} ) ) {
            $event->{what} = evCommand;
            $event->{message}{command} = $p->{command};
            $event->{message}{infoPtr} = undef;
            $self->putEvent( $event );
            $self->clearEvent( $event );
          }
        } #/ else [ if ( $self->findItem( ...))]
        last;
      };
      $_ == evCommand and do {
        if ( $event->{message}{command} == cmMenu ) {
          $self->$do_a_select( $event );
        }
        last;
      };
      $_ == evBroadcast and do {
        if ( $event->{message}{command} == cmCommandSetChanged ) {
          $self->drawView() 
            if $self->$updateMenu( $self->{menu} );
        }
        last;
      };
    }
  } #/ if ( $self->{menu} )
  return;
} #/ sub handleEvent

sub hotKey {    # $menuItem ($keyCode)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $keyCode ) = $sig->( @_ );
  return $self->$findHotKey( $self->{menu}{items}, $keyCode );
}

sub newSubView {    # $menuView ($bounds, $aMenu, $aParentMenu)
  state $sig = signature(
    method => Object,
    pos    => [Object, Object, Object],
  );
  my ( $self, $bounds, $aMenu, $aParentMenu ) = $sig->( @_ );
  require TUI::Menus::MenuBox;
  return TUI::Menus::MenuBox->new(
    bounds     => $bounds,
    menu       => $aMenu,
    parentMenu => $aParentMenu,
  );
}

sub parentMenu {    # $menuView|undef (|$menuView|undef)
  state $sig = signature(
    method => Object,
    pos    => [
      Maybe[Object], { optional => 1 },
    ],
  );
  my ( $self, $menuView ) = $sig->( @_ );
  goto SET if @_ > 1;
  GET: {
    return $self->{parentMenu};
  }
  SET: {
    &$unlock_value( $self->{parentMenu} ) if STRICT;
    weaken $self->{parentMenu}
      if $self->{parentMenu} = $menuView;
    &$lock_value( $self->{parentMenu} ) if STRICT;
    return;
  }
}

sub current {    # $menuItem|undef (|$menuItem|undef)
  state $sig = signature(
    method => Object,
    pos    => [
      Maybe[Object], { optional => 1 },
    ],
  );
  my ( $self, $menuItem ) = $sig->( @_ );
  goto SET if @_ > 1;
  GET: {
    return $self->{current};
  }
  SET: {
    &$unlock_value( $self->{current} ) if STRICT;
    weaken $self->{current}
      if $self->{current} = $menuItem;
    &$lock_value( $self->{current} ) if STRICT;
    return;
  }
}

$nextItem = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  $self->current(
    $self->{current}{next}
      ? $self->{current}{next}
      : $self->{menu}{items}
  );
  return;
};

$prevItem = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  my $p;

  no warnings 'uninitialized';
  if ( ( $p = $self->{current} ) == $self->{menu}{items} ) {
    $p = undef;
  }

  do {
    $self->$nextItem();
  } while ( $self->{current}{next} != $p );
  return;
};

$trackKey = sub {    # void ($findNext)
  my ( $self, $findNext ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Bool $findNext );
  return
    unless $self->{current};

  do {
    if ( $findNext ) {
      $self->$nextItem();
    }
    else {
      $self->$prevItem();
    }
  } while ( !$self->{current}{name} );
  return;
}; #/ $trackKey = sub

$mouseInOwner = sub {    # $bool ($e)
  my ( $self, $e ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $e );
  if ( !$self->{parentMenu} || $self->{parentMenu}{size}{y} != 1 ) {
    return false;
  }
  else {
    my $mouse = $self->{parentMenu}->makeLocal( $e->{mouse}{where} );
    my $r = $self->{parentMenu}->getItemRect( $self->{parentMenu}{current} );
    return $r->contains( $mouse );
  }
}; #/ $mouseInOwner = sub

$mouseInMenus = sub {    # $bool ($e)
  my ( $self, $e ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $e );
  my $p = $self->{parentMenu};
  while ( $p && !$p->mouseInView( $e->{mouse}{where} ) ) {
    $p = $p->{parentMenu};
  }
  return defined $p;
};

$trackMouse = sub {    # void ($e, \$mouseActive)
  my ( $self, $e, $mouseActive ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_Object $e );
  assert ( is_ScalarRef $mouseActive );
  my $mouse = $self->makeLocal( $e->{mouse}{where} );
  for (
    $self->current( $self->{menu}{items} );
    $self->{current};
    $self->current( $self->{current}{next} )
  ) {
    my $r = $self->getItemRect( $self->{current} );
    if ( $r->contains( $mouse ) ) {
      $$mouseActive = true;
      return;
    }
  } #/ for ( $self->{current} ...)
  return;
}; #/ sub

$topMenu = sub {    # $menuView ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  my $p = $self;
  while ( $p->{parentMenu} ) {
    $p = $p->{parentMenu};
  }
  return $p;
};

$updateMenu = sub {    # $bool ($menu|undef)
  my ( $self, $menu ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( !defined $menu or is_Object $menu );
  my $res = false;
  if ( $menu ) {
    for ( my $p = $menu->{items} ; $p ; $p = $p->{next} ) {
      if ( $p->{name} ) {
        if ( $p->{command} == 0 ) {
          $res = true
            if $p->{subMenu}
            && $self->$updateMenu( $p->{subMenu} );
        }
        else {
          my $commandState = TView->commandEnabled( $p->{command} );
          no warnings 'uninitialized';
          if ( $p->{disabled} == $commandState ) {
            $p->{disabled} = !$commandState;
            $res = true;
          }
        }
      } #/ if ( $p->{name} )
    } #/ for ( my $p = $menu->{items...})
  } #/ if ( $menu )
  return $res;
}; #/ $updateMenu = sub

$do_a_select = sub {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $event );
  $self->putEvent( $event );
  my $cmd = $self->{owner}->execView( $self );
  if ( $cmd && TView->commandEnabled( $cmd ) ) {
    $event->{what} = evCommand;
    $event->{message}{command} = $cmd;
    $event->{message}{infoPtr} = undef;
    $self->putEvent( $event );
  }
  $self->clearEvent( $event );
  return;
}; #/ $do_a_select = sub

$findHotKey = sub {    # $menuItem|undef ($p|undef, $keyCode)
  my ( $self, $p, $keyCode ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( !defined $p or is_Object $p );
  assert ( is_Int $keyCode );
  while ( $p ) {
    if ( $p->{name} ) {
      if ( $p->{command} == 0 ) {
        my $T = $self->$findHotKey( $p->{subMenu}{items}, $keyCode );
        return $T 
          if $T;
      }
      elsif ( !$p->{disabled}
        && $p->{keyCode} != kbNoKey
        && $p->{keyCode} == $keyCode
      ) {
        return $p;
      }
    } #/ if ( $p->{name} )
    $p = $p->{next};
  } #/ while ( $p )
  return undef;
}; #/ sub $findHotKey

1

__END__

=pod

=head1 NAME

TUI::Menus::MenuView - abstract base class for menu views

=head1 HIERARCHY

  TObject
    TView
      TMenuView
        TMenuBar
        TMenuBox

=head1 DESCRIPTION

C<TMenuView> implements the shared behavior required by menu views such as
C<TMenuBar> and C<TMenuBox>. It manages menu navigation, item selection, hotkey
handling, and modal execution of menus.

This class is abstract and is not intended to be instantiated directly.
Applications normally interact with derived classes rather than with
C<TMenuView> itself.

Most methods defined here are used internally by the menu system and are rarely
called directly by application code.

=head1 ATTRIBUTES

The following attributes are managed internally and exposed as read-only
accessors.

=over

=item menu

Reference to the menu data structure defining the menu items (I<TMenu>).

=item parentMenu

Optional reference to the parent menu view (I<TMenuView>).

=item current

Reference to the currently selected menu item (I<TMenuItem>).

=back

=head1 CONSTRUCTOR

=head2 new

  my $view = TMenuView->new(
    bounds     => $bounds,
    menu       => $menu,
    parentMenu => $parentMenu
  );

Creates a new menu view. This constructor is intended to be called only by
derived classes such as C<TMenuBar> and C<TMenuBox>.

=over

=item bounds

Bounding rectangle of the menu view (I<TRect>).

=item menu

Menu data structure defining the menu items (I<TMenu>).

=item parentMenu

Optional parent menu view (I<TMenuView>).

=back

=head2 new_TMenuView

  my $view = new_TMenuView($bounds, | $menu, | $parentMenu);

Factory-style constructor using positional arguments.

This constructor exists primarily for internal use and for compatibility with
traditional Turbo Vision construction patterns.

=head1 METHODS

=head2 current

  my $item = $view->current();
  $view->current($item);

Gets or sets the currently selected menu item.

=head2 execute

  my $command = $view->execute();

Executes the menu view in a modal loop and returns the selected command
identifier, or C<0> if the menu was cancelled.

=head2 findItem

  my $item = $view->findItem($ch);

Searches for a menu item matching the specified shortcut character and returns
the corresponding menu item, or C<undef> if no match is found.

=head2 getHelpCtx

  my $ctx = $view->getHelpCtx();

Returns the help context associated with the currently selected menu item.

=head2 getItemRect

  my $rect = $view->getItemRect($item | undef);

Returns the screen rectangle occupied by the specified menu item.

=head2 getPalette

  my $palette = $view->getPalette();

Returns the color palette used to draw the menu view.

=head2 handleEvent

  $view->handleEvent($event);

Processes keyboard and mouse events for menu navigation and selection.

=head2 hotKey

  my $item = $view->hotKey($keyCode);

Searches for a menu item matching the specified hot key and returns it if found.

=head2 newSubView

  my $subView = $view->newSubView($bounds, $menu, $parentMenu);

Creates a new submenu view associated with this menu view.

=head2 parentMenu

  my $parent = $view->parentMenu();
  $view->parentMenu($parent);

Gets or sets the parent menu view.

=head1 SEE ALSO

L<TUI::Menus::MenuBar>,
L<TUI::Menus::MenuBox>,
L<TUI::Menus::Menu>,
L<TUI::Menus::MenuItem>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut

