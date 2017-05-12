package SDLx::Widget::Menu;
use strict;
use warnings;
use SDL;
use SDL::Audio;
use SDL::Video;
use SDLx::Text;
use SDL::Color;
use SDL::Event;
use SDL::Events;
use SDLx::Rect;
use SDL::TTF;
use Carp ();
use Mouse;

our $VERSION = '0.072';

# TODO: add default values
has 'font'         => ( is => 'ro', isa => 'Str' );
has 'font_color'   => ( is => 'ro', isa => 'ArrayRef', 
                        default => sub { [ 255, 255, 255] }
                      );

has 'topleft' => ( is => 'ro', isa => 'ArrayRef', default => sub { [0,0] } );

has 'h_align' => ( is => 'ro', isa => 'Str', default => sub { 'center' } );

has 'spacing' => ( is => 'ro', isa => 'Int', default => sub { 20 } );

has 'select_color' => ( is => 'ro', isa => 'ArrayRef', 
                        default => sub { [ 255, 0, 0 ] }
                      );

has 'active_color' => ( is => 'ro', isa => 'ArrayRef',
                        default => sub { [ 255, 255, 0 ] }
                      );

has 'font_size'    => ( is => 'ro', isa => 'Int', default => 24 );
has 'current'      => ( is => 'rw', isa => 'Int', default => 0 );
has 'selected'     => ( is => 'rw', isa => 'Maybe[Int]' );

has 'mouse'        => ( is => 'ro', isa => 'Bool', default => 1);

# TODO implement those
has 'change_sound' => ( is => 'ro', isa => 'Str' );
has 'select_sound' => ( is => 'ro', isa => 'Str' );

# private
has 'has_audio' => ( is => 'rw', isa => 'Bool', default => 0,
                     writer => '_has_audio' );

# internal
has '_items' => (is => 'rw', isa => 'ArrayRef', default => sub {[]} );
has '_container_rect' => ( is => 'rw', isa => 'SDLx::Rect' );
has '_font'  => (is => 'rw', isa => 'SDLx::Text' );
has '_change_sound' => (is => 'rw', isa => 'SDL::Mixer::MixChunk' );
has '_select_sound' => (is => 'rw', isa => 'SDL::Mixer::MixChunk' );

sub BUILD {
    my $self = shift;

    $self->_build_font;
    $self->_build_sound;
}

sub _build_font {
    my $self = shift;

    my $font = SDLx::Text->new( size => $self->font_size );
    $font->font( $self->font ) if $self->font;

    $self->_font( $font );
}

sub _build_sound {
    my $self = shift;

    if ($self->select_sound or $self->change_sound ) {
        require SDL::Mixer;
        require SDL::Mixer::Music;
        require SDL::Mixer::Channels;
        require SDL::Mixer::Samples;
        require SDL::Mixer::MixChunk;

        # initializes sound if it's not already
        my ($status) = @{ SDL::Mixer::query_spec() };
        if ($status != 1) {
            SDL::Mixer::open_audio( 44100, AUDIO_S16, 2, 4096 );
            ($status) = @{ SDL::Mixer::query_spec() };
        }

        # load sounds if audio is (or could be) initialized
        if ( $status == 1 ) {
            $self->_has_audio(1);
            if ($self->select_sound) {
                my $sound = SDL::Mixer::Samples::load_WAV($self->select_sound);
                $self->_select_sound( $sound );
            }
            if ($self->change_sound) {
                my $sound = SDL::Mixer::Samples::load_WAV($self->change_sound);
                $self->_change_sound( $sound );
            }
        }
    }
}

# this is the method used to indicate
# all menu items, their position on screen and callbacks
sub items {
    my ($self, @items) = @_;

    my ( $top, $left ) = @{$self->topleft};
    my $largest = 0;
    my $item_top = $top;

    while( my ($name, $val) = splice @items, 0, 2 ) {
        my ( $width, $height )
            = @{ SDL::TTF::size_text( $self->_font->font, $name ) };

        $largest = $width if $width > $largest;

        my $rect
            = SDLx::Rect->new( $left, $item_top, $width, $height );

        push @{$self->_items},
            { name => $name, trigger => $val, rect => $rect };

        $item_top += $self->spacing + $height;
    }

    # second pass, aligning against the largest item
    if ($self->h_align ne 'left') {
        # default is to center
        my ($method, $value) = ( 'centerx', $left + ($largest / 2) );
        if ($self->h_align eq 'right') {
            ($method, $value) = ('right', $left + $largest );
        }

        foreach my $item ( @{ $self->_items } ) {
            $item->{rect}->$method( $value );
        }
    }

    # we store a container rect surrounding all items
    # to help speed things up during mouse motion checks
    $self->_container_rect( SDLx::Rect->new(
               $left,
               $top,
               $largest,
               $item_top - $top - $self->spacing
    ));

    return $self;
}

sub event_hook {
    my ($self, $event) = @_;

    my $type = $event->type;
    my $mask = SDL_EVENTMASK($type);

    if ( $type == SDL_KEYDOWN ) {
        my $key = $event->key_sym;

        if ($key == SDLK_DOWN) {
            $self->current( ($self->current + 1) % @{$self->_items} );
            $self->_play($self->_change_sound);
        }
        elsif ($key == SDLK_UP) {
            $self->current( ($self->current - 1) % @{$self->_items} );
            $self->_play($self->_change_sound);
        }
        elsif ($key == SDLK_RETURN or $key == SDLK_KP_ENTER ) {
            $self->_play($self->_select_sound);
            $self->selected( $self->current );
            return $self->_items->[$self->current]->{trigger}->();
        }
    }
    elsif ( $self->mouse && ( $mask & SDL_MOUSEEVENTMASK ) ) {
        my ( $x, $y ) = ( $event->button_x, $event->button_y );
        my @items     = @{$self->_items};

        if ( $type == SDL_MOUSEMOTION ) {
            ($x, $y) = ( $event->motion_x, $event->motion_y );
            if ($self->_container_rect->collidepoint( $x, $y )) {
                for ( 0 .. $#items ) {
                    if ( $items[$_]->{rect}->collidepoint( $x, $y ) ) {
                        $self->current( $_ );
                        last;
                    }
                }
            }
        }
        elsif ( $type == SDL_MOUSEBUTTONUP ) {
            if ( $items[$self->current]->{rect}->collidepoint( $x, $y ) ) {
                $self->_play($self->_select_sound);
                $self->selected( $self->current );
                return $items[$self->current]->{trigger}->();
            }
        }
    }

    return 1;
}

sub _play {
    my ($self, $sound) = @_;
    return unless $self->has_audio;

    my $channel = SDL::Mixer::Channels::play_channel(-1, $sound, 0 );
    if ( $channel ) {
        SDL::Mixer::Channels::volume( $channel, 10 );
    }
}


# NOTE: the update() call is here just as an example.
# SDLx::* calls should likely implement those whenever
# they need updating in each delta t.
sub update {}

=pod

=for Pod::Coverage update

=cut

sub render {
    my ($self, $screen) = @_;

    my $font = $self->_font;

    foreach my $item ( @{$self->_items} ) {
#        print STDERR 'it: ' . $item->{name} . ', s: '. $self->_items->[$self->current]->{name} . ', c: ' . $self->current . $/;

        my $color = defined $self->selected && $item->{name} eq $self->_items->[$self->selected]->{name}
                  ? $self->select_color
                  : $item->{name} eq $self->_items->[$self->current]->{name}
                  ? $self->active_color : $self->font_color
                  ;

        $font->color( $color );
        $font->write_xy( $screen, $item->{rect}->x, $item->{rect}->y, $item->{'name'} );
    }
}

1;
__END__
=head1 NAME

SDLx::Widget::Menu - create menus for your SDL apps easily

=head1 SYNOPSIS

Create a simple SDL menu for your game/app:

    my $menu = SDLx::Widget::Menu->new->items(
                   'New Game' => \&play,
                   'Options'  => \&settings,
                   'Quit'     => \&quit,
               );


Or customize it at will:

    my $menu = SDLx::Widget::Menu->new(
                   topleft      => [100, 120],
                   h_align      => 'right',
                   spacing      => 10,
                   mouse        => 1,
                   font         => 'mygame/data/menu_font.ttf',
                   font_size    => 20,
                   font_color   => [255, 0, 0], # RGB (in this case, 'red')
                   select_color => [0, 255, 0],
                   active_color => [0, 0, 255],
                   change_sound => 'game/data/menu_select.ogg',
               )->items(
                   'New Game' => \&play,
                   'Options'  => \&settings,
                   'Quit'     => \&quit,
               );

After that, all you have to do is make sure your menu object's hooks are
called at the right time in your game loop:

    # in the event loop
    $menu->event_hook( $event );  # $event is a SDL::Event

    # in the rendering loop
    $menu->render( $screen );     # $screen is a SDL::Surface


=head1 DESCRIPTION

Main menus are a very common thing in games. They let the player choose
between a new game, loading games, setting up controls, among lots of other
stuff. This menu widget is meant to aid developers create menus quickly and easily, so they can concentrate in their game's logic rather than on such a
repetitive task. Simple menus, easy. Complex menus, possible!


=head1 WARNING! VOLATILE CODE AHEAD

This is a new module and the API is subject to change without notice.
If you care, please join the discussion on the #sdl IRC channel in
I<irc.perl.org>. All thoughts on further improving the API are welcome.

You have been warned :)

=head1 METHODS

=head2 new

=head2 new( %options )

Creates a new SDLx::Widget::Menu object. No option is mandatory.
Available options are:

=over 4

=item * topleft => [ $top, $left ]

Determines topmost and leftmost positions for the menu. Defaults to [ 0, 0 ].

=item * h_align => 'center'

Sets the preferred menu text alignment. Default is 'center', which
will center menu items to their largest entry. Other possible values
are 'left' and 'right'.

=item * spacing => 20

Sets the line spacing between menu items. Default value is 20. Setting
this to 0 will place one item right below the other.

=item * font => $filename

File name of the font used to render menu text.

=item * font_size => $size

Size of the font used to render menu text.

=item * font_color => [ $red, $green, $blue ]

RGB value to set the font color.

=item * select_color => [ $red, $green, $blue ]

RGB value for the font color of the selected (clicked) item

=item * active_color => [ $red, $green, $blue ]

RGB value for the font color of the active (hovered) item

=item * change_sound => $filename

File name of the sound to play when the selected item changes

=item * mouse => 1

Indicates that menu items can be clicked using a mouse. By default,
mouse input is active.

=back

=head2 items( 'Item 1' => \&sub1, 'Item 2' => \&sub2, ... )

=head2 event_hook( $event )

=head2 render( $surface )

Creates menu items, setting up callbacks for each item.

=head1 BUGS AND LIMITATIONS

=over 4

=item * Doesn't let you setup other keys to change current selection (yet)

=item * Doesn't let you handle menu changes yourself (yet)

=back

=head1 AUTHORS

Breno G. de Oliveira, C<< <garu at cpan.org> >>

Kartik thakore C<< <kthakore at cpan.org> >>

=head1 SEE ALSO

L<< SDL >>, L<< SDLx::App >>, L<< SDLx::Controller >>

