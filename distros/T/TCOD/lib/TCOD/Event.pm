package TCOD::Event;

use strict;
use warnings;
use feature 'state';

use TCOD::SDL2;
use Sub::Util ();

our $VERSION = '0.009';

BEGIN {
    require constant;
    constant->import({
        map { $_ => TCOD::SDL2->can($_)->() }
        grep /^(?:K(?:MOD)?|SCANCODE)_/,
        keys %TCOD::SDL2::
    });
    our %Keymod   = %TCOD::SDL2::Keymod;
    our %Keycode  = %TCOD::SDL2::Keycode;
    our %Scancode = %TCOD::SDL2::Scancode;

    our %MouseButton = (
        BUTTON_LEFT   => 1,
        BUTTON_MIDDLE => 2,
        BUTTON_RIGHT  => 3,
        BUTTON_X1     => 4,
        BUTTON_X2     => 5,
    );

    our %MouseButtonMask = (
        BUTTON_LMASK  => 1,
        BUTTON_MMASK  => 2,
        BUTTON_RMASK  => 4,
        BUTTON_X1MASK => 8,
        BUTTON_X2MASK => 16,
    );

    constant->import( \%MouseButton );
    constant->import( \%MouseButtonMask );
}

package
    TCOD::Event::Base {

    sub new {
        bless {
            type      => uc $_[0] =~ s/.*:://r,
            sdl_event => $_[1],
            '!key'    => $_[2] // '',
        }, $_[0]
    }

    sub init { shift }

    sub as_hash {
        my ($self) = @_;
        return { %{ $self }{ grep !/^(?:!|sdl_event)/, keys %{ $self } } };
    }

    sub as_string { '<type=' . shift->type . '>' }

    sub AUTOLOAD {
        our $AUTOLOAD;
        my $self = shift;

        return if $AUTOLOAD =~ /DESTROY/;
        my $method = $AUTOLOAD =~ s/.*:://r;

        no strict 'refs';
        *{$AUTOLOAD} = Sub::Util::set_subname $AUTOLOAD,
            sub { shift->{$method} };

        $self->{$method} // die "No such method: $AUTOLOAD";
    }
}

package
    TCOD::Event::Quit {
    our @ISA = 'TCOD::Event::Base';
}

package
    TCOD::Event::Keyboard {
    our @ISA = 'TCOD::Event::Base';
    sub init {
        my $self = shift;
        my ( $e, $k ) = @{ $self }{qw( sdl_event !key )};
        $e = $e->$k if $k;
        $self->{scancode} = $e->scancode;
        $self->{sym}      = $e->sym;
        $self->{mod}      = $e->mod;
        $self->{repeat}   = $e->repeat;
        $self;
    }

    sub as_string {
        my $self = shift;
        sprintf '<%s, scancode=%d, sym=%d, mod=%d, repeat=%d>',
            $self->SUPER::as_string =~ s/^<|>$//gr,
            @{ $self }{qw( scancode sym mod repeat )};
    }
}

package
    TCOD::Event::KeyDown {
    our @ISA = 'TCOD::Event::Keyboard';
}

package
    TCOD::Event::KeyUp {
    our @ISA = 'TCOD::Event::Keyboard';
}

package
    TCOD::Event::Mouse {
    our @ISA = 'TCOD::Event::Base';
    sub init {
        my $self = shift;
        my ( $e, $k ) = @{ $self }{qw( sdl_event !key )};
        $e = $e->$k if $k;
        $self->{xy} = [ $e->x, $e->y ];
        $self;
    }

    sub x { shift->{xy}[0] }
    sub y { shift->{xy}[1] }

    sub tilex { shift->{tilexy}[0] }
    sub tiley { shift->{tilexy}[1] }

    sub as_string {
        my $self = shift;
        my $out = sprintf '%s, x=%d, y=%d', $self->SUPER::as_string =~ s/^<|>$//gr, @{ $self->{xy} };
        $out .= sprintf ', tilex=%d, tiley=%d', @{ $self->{tilexy} } if $self->{tilexy};
        "<$out>";
    }
}

package
    TCOD::Event::MouseState {
    our @ISA = 'TCOD::Event::Mouse';
    sub init {
        my $self = shift;
        $self->SUPER::init;

        my ( $e, $k ) = @{ $self }{qw( sdl_event !key )};
        $e = $e->$k if $k;

        $self->{state} = $e->state;
        $self;
    }

    sub as_string {
        my $self = shift;
        sprintf '<%s, state=%05b>', $self->SUPER::as_string =~ s/^<|>$//gr, $self->{state};
    }
}

package
    TCOD::Event::MouseButton {
    our @ISA = 'TCOD::Event::MouseState';
    sub init {
        my $self = shift;
        $self->SUPER::init;

        my ( $e, $k ) = @{ $self }{qw( sdl_event !key )};
        $e = $e->$k if $k;

        $self->{button} = $e->button;
        $self;
    }

    sub as_string {
        my $self = shift;
        sprintf '<%s, button=%d>', $self->SUPER::as_string =~ s/^<|>$//gr, $self->{button};
    }
}

package
    TCOD::Event::MouseButtonUp {
    our @ISA = 'TCOD::Event::MouseButton';
}

package
    TCOD::Event::MouseButtonDown {
    our @ISA = 'TCOD::Event::MouseButton';
}

package
    TCOD::Event::MouseMotion {
    our @ISA = 'TCOD::Event::MouseState';
    sub init {
        my $self = shift;
        $self->SUPER::init;

        my ( $e, $k ) = @{ $self }{qw( sdl_event !key )};
        $e = $e->$k if $k;

        $self->{dxy} = [ $e->xrel, $e->yrel ];
        $self;
    }

    sub dx { shift->{dxy}[0] }
    sub dy { shift->{dxy}[1] }

    sub tiledx { shift->{tiledxy}[0]  }
    sub tiledy { shift->{tiledxy}[1]  }

    sub as_string {
        my $self = shift;
        my $out = sprintf '%s, dx=%d, dy=%d', $self->SUPER::as_string =~ s/^<|>$//gr, @{ $self->{dxy} };
        $out .= sprintf ', tiledx=%d, tiledy=%d', @{ $self->{tiledxy} } if $self->{tiledxy};
        "<$out>";
    }
}

package
    TCOD::Event::MouseWheel {
    our @ISA = 'TCOD::Event::Mouse';
    sub init {
        my $self = shift;
        $self->SUPER::init;

        my ( $e, $k ) = @{ $self }{qw( sdl_event !key )};
        $e = $e->$k if $k;

        $self->{flipped} = $e->direction;
        $self;
    }

    sub as_string {
        my $self = shift;
        sprintf '<%s, flipped=%d>', $self->SUPER::as_string =~ s/^<|>$//gr, $self->{flipped};
    }
}

package
    TCOD::Event::TextInput {
    our @ISA = 'TCOD::Event::Base';
    sub init {
        my $self = shift;

        my ( $e, $k ) = @{ $self }{qw( sdl_event !key )};
        $e = $e->$k if $k;

        $self->{text} = $e->text;
        $self;
    }

    sub as_string {
        my $self = shift;
        sprintf '<%s, text=%s>', $self->SUPER::as_string =~ s/^<|>$//gr, $self->{text};
    }
}

package
    TCOD::Event::WindowBase {
    our @ISA = 'TCOD::Event::Base';
    sub init {
        my $self = shift;

        my ( $e, $k ) = @{ $self }{qw( sdl_event !key )};
        my $w = $e->$k;

        $self->{type} = $TCOD::SDL2::WindowEventID{ $w->event }
            // return TCOD::Event::Undefined->new($e)->init;

        $self->{type} =~ s/WINDOWEVENT_/WINDOW/;
        $self->{type} =~ s/_//g;

        $self;
    }
}

package
    TCOD::Event::WindowWidthHeight {
    our @ISA = 'TCOD::Event::WindowBase';
    sub init {
        my $self = shift;
        $self->SUPER::init;

        my ( $e, $k ) = @{ $self }{qw( sdl_event !key )};
        my $w = $e->$k;

        $self->{width}  = $w->data1;
        $self->{height} = $w->data2;

        $self;
    }

    sub as_string {
        my $self = shift;
        sprintf '<%s, width=%d, height=%d>',
            $self->SUPER::as_string =~ s/^<|>$//gr,
            @{ $self }{qw( width height )};
    }
}

package
    TCOD::Event::WindowClose {
    our @ISA = 'TCOD::Event::WindowBase';
}

package
    TCOD::Event::WindowEnter {
    our @ISA = 'TCOD::Event::WindowBase';
}

package
    TCOD::Event::WindowLeave {
    our @ISA = 'TCOD::Event::WindowBase';
}

package
    TCOD::Event::WindowRestored {
    our @ISA = 'TCOD::Event::WindowBase';
}

package
    TCOD::Event::WindowMinimized {
    our @ISA = 'TCOD::Event::WindowBase';
}

package
    TCOD::Event::WindowMaximized {
    our @ISA = 'TCOD::Event::WindowBase';
}

package
    TCOD::Event::WindowExposed {
    our @ISA = 'TCOD::Event::WindowBase';
}

package
    TCOD::Event::WindowFocusGained {
    our @ISA = 'TCOD::Event::WindowBase';
}

package
    TCOD::Event::WindowFocusLost {
    our @ISA = 'TCOD::Event::WindowBase';
}

package
    TCOD::Event::WindowTakeFocus {
    our @ISA = 'TCOD::Event::WindowBase';
}

package
    TCOD::Event::WindowShown {
    our @ISA = 'TCOD::Event::WindowBase';
}

package
    TCOD::Event::WindowHidden {
    our @ISA = 'TCOD::Event::WindowBase';
}

package
    TCOD::Event::WindowHitTest {
    our @ISA = 'TCOD::Event::WindowBase';
}

package
    TCOD::Event::WindowMoved {
    our @ISA = 'TCOD::Event::WindowBase';
    sub init {
        my $self = shift;
        $self->SUPER::init;

        my ( $e, $k ) = @{ $self }{qw( sdl_event !key )};
        $e = $e->$k;

        $self->{xy} = [ $e->data1, $e->data2 ];
        $self;
    }

    sub x { shift->{xy}[0] }
    sub y { shift->{xy}[1] }

    sub as_string {
        my $self = shift;
        sprintf '<%s, x=%d, y=%d>',
            $self->SUPER::as_string =~ s/^<|>$//gr,
            @{ $self->{xy} };
    }
}

package
    TCOD::Event::WindowResized {
    our @ISA = 'TCOD::Event::WindowWidthHeight';
}

package
    TCOD::Event::WindowSizeChanged {
    our @ISA = 'TCOD::Event::WindowWidthHeight';
}

package
    TCOD::Event::Undefined {
    our @ISA = 'TCOD::Event::Base';
}

package TCOD::Event::Dispatch {
    use Role::Tiny;

    sub dispatch {
        my $class = shift;
        my ( $event ) = @_;

        my $type = lc $event->type // '';

        unless ( defined $type ) {
            Carp::carp 'Uninitialised event type in call to dispatch';
            return;
        }

        my $dispatch = $class->can("ev_$type")
            or Carp::croak 'No event handler for event of type ' . $type;

        goto $dispatch;
    }

    sub ev_keydown           { }
    sub ev_keyup             { }
    sub ev_mousebuttondown   { }
    sub ev_mousebuttonup     { }
    sub ev_mousemotion       { }
    sub ev_mousewheel        { }
    sub ev_quit              { }
    sub ev_textinput         { }
    sub ev_undefined         { }
    sub ev_windowclose       { }
    sub ev_windowenter       { }
    sub ev_windowexposed     { }
    sub ev_windowfocusgained { }
    sub ev_windowfocuslost   { }
    sub ev_windowhidden      { }
    sub ev_windowhittest     { }
    sub ev_windowleave       { }
    sub ev_windowmaximized   { }
    sub ev_windowminimized   { }
    sub ev_windowmoved       { }
    sub ev_windowresized     { }
    sub ev_windowrestored    { }
    sub ev_windowshown       { }
    sub ev_windowsizechanged { }
    sub ev_windowtakefocus   { }
}

sub new {
    state %win = (
        TCOD::SDL2::WINDOWEVENT_SHOWN        ,=> [ 'WindowShown'       => 'window' ],
        TCOD::SDL2::WINDOWEVENT_HIDDEN       ,=> [ 'WindowHidden'      => 'window' ],
        TCOD::SDL2::WINDOWEVENT_EXPOSED      ,=> [ 'WindowExposed'     => 'window' ],
        TCOD::SDL2::WINDOWEVENT_MOVED        ,=> [ 'WindowMoved'       => 'window' ],
        TCOD::SDL2::WINDOWEVENT_RESIZED      ,=> [ 'WindowResized'     => 'window' ],
        TCOD::SDL2::WINDOWEVENT_SIZE_CHANGED ,=> [ 'WindowSizeChanged' => 'window' ],
        TCOD::SDL2::WINDOWEVENT_MINIMIZED    ,=> [ 'WindowMinimized'   => 'window' ],
        TCOD::SDL2::WINDOWEVENT_MAXIMIZED    ,=> [ 'WindowMaximized'   => 'window' ],
        TCOD::SDL2::WINDOWEVENT_RESTORED     ,=> [ 'WindowRestored'    => 'window' ],
        TCOD::SDL2::WINDOWEVENT_ENTER        ,=> [ 'WindowEnter'       => 'window' ],
        TCOD::SDL2::WINDOWEVENT_LEAVE        ,=> [ 'WindowLeave'       => 'window' ],
        TCOD::SDL2::WINDOWEVENT_FOCUS_GAINED ,=> [ 'WindowFocusGained' => 'window' ],
        TCOD::SDL2::WINDOWEVENT_FOCUS_LOST   ,=> [ 'WindowFocusLost'   => 'window' ],
        TCOD::SDL2::WINDOWEVENT_CLOSE        ,=> [ 'WindowClose'       => 'window' ],
        TCOD::SDL2::WINDOWEVENT_TAKE_FOCUS   ,=> [ 'WindowTakeFocus'   => 'window' ],
        TCOD::SDL2::WINDOWEVENT_HIT_TEST     ,=> [ 'WindowHitTest'     => 'window' ],
    );

    state %map = (
        TCOD::SDL2::QUIT             ,=> [ 'Quit'            => ''       ],
        TCOD::SDL2::KEYDOWN          ,=> [ 'KeyDown'         => 'key'    ],
        TCOD::SDL2::KEYUP            ,=> [ 'KeyUp'           => 'key'    ],
        TCOD::SDL2::MOUSEMOTION      ,=> [ 'MouseMotion'     => 'motion' ],
        TCOD::SDL2::MOUSEBUTTONDOWN  ,=> [ 'MouseButtonDown' => 'button' ],
        TCOD::SDL2::MOUSEBUTTONUP    ,=> [ 'MouseButtonUp'   => 'button' ],
        TCOD::SDL2::MOUSEWHEEL       ,=> [ 'MouseWheel'      => 'wheel'  ],
        TCOD::SDL2::TEXTINPUT        ,=> [ 'TextInput'       => 'text'   ],
    );

    my ( undef, $e ) = @_;

    my ( $class, $method ) = $e->type == TCOD::SDL2::WINDOWEVENT
        ? @{ $win{ $e->window->event } // [ Undefined => '' ] }
        : @{ $map{ $e->type          } // [ Undefined => '' ] };

    $class = "TCOD::Event::$class";

    $class->new( $e, $method )->init;
}

my $get = sub {
    TCOD::SDL2::PollEvent( my $event = TCOD::SDL2::Event->new )
        or return;

    __PACKAGE__->new($event);
};

sub get { sub { goto $get } }

sub wait {
    my $timeout = shift || 0;

    if ( $timeout ) {
        TCOD::SDL2::WaitEventTimeout( undef, $timeout * 1000 )
            or die TCOD::SDL2::GetError();
    }
    else {
        TCOD::SDL2::WaitEvent( undef )
            or die TCOD::SDL2::GetError();
    }

    goto &get;
}

1;
