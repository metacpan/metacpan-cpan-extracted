#
# This file is part of SDLx-GUI
#
# This software is copyright (c) 2013 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.016;
use warnings;

package SDLx::GUI::Widget::Toplevel;
# ABSTRACT: Toplevel widget for whole app screen
$SDLx::GUI::Widget::Toplevel::VERSION = '0.002';
use Carp            qw{ croak };
use List::AllUtils  qw{ first };
use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;
use SDL::Event;
use SDL::Video;
use SDLx::Rect;
use SDLx::Surface;

use SDLx::GUI::Debug qw{ debug };
use SDLx::GUI::Pack;

extends qw{ SDLx::GUI::Widget };


# -- attributes


has app => ( ro, required, weak_ref, isa=>"SDLx::App" );


# A list of widgets created inside the toplevel.
has _children => (
    ro, auto_deref,
    traits  => ['Array'],
    isa     => 'ArrayRef[SDLx::GUI::Widget]',
    default => sub { [] },
    handles => {
        _add_child  => 'push',
    },
);

# The widget where the mouse is currently over.
has _mouse_over_widget => ( rw, lazy_build, isa=>"SDLx::GUI::Widget" );


# -- initialization

sub BUILD {
    my $self = shift;
    $self->app->add_event_handler( sub { $self->_handle_event($_[0]) } );
}

sub _build__mouse_over_widget { return $_[0] }


# -- public methods

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;

    # Remove qualifier from original method name...
    my $called = $AUTOLOAD =~ s/.*:://r;
    my $class  = "SDLx::GUI::Widget::$called";

    eval "require $class";
    croak "No such method $called\n" if $@;
    my $widget = $class->new( parent=>$self, @_);
    $self->_add_child( $widget );
    return $widget;
}



sub draw {
    my $self = shift;

    debug( "redrawing $self\n" );
    $self->app->draw_rect( undef, $self->bg_color );

    foreach my $child ( grep { $_->is_packed } $self->_children ) {
        my $pack       = $child->_pack_info;
        my $parcel     = $pack->_parcel;
        my $slave_dims = $pack->_slave_dims;
        my $surface = SDLx::Surface->new(
            width  => $slave_dims->w,
            height => $slave_dims->h
        );
        debug( "child $child to be redrawn\n" );
        debug( "parcel     = " . _rects($parcel) );
        debug( "slave_dims = " . _rects($slave_dims) );
        $child->_draw( $surface );
        my $sprite = SDLx::Sprite->new(
            surface => $surface,
            x       => $parcel->x,
            y       => $parcel->y,
            ( $pack->_clip ? ( clip => $pack->_clip ) : () ),
        );
        $sprite->draw( $self->app );
    }
    debug( "completed redrawing of $self\n" );
    $self->app->update;
}


# -- private methods

sub _handle_event {
    my ($self, $event) = @_;
    my $type = $event->type;

    if ( $type == SDL_MOUSEMOTION ) {
        my ($x, $y) = ($event->motion_x, $event->motion_y);
        #debug( "mouse motion \@$x,$y\n" );

        # check which widget mouse is overing
        my ($new) =
            grep { $_->_pack_info->_slave_dims->collidepoint($x,$y) }
            grep { $_->is_visible }
            $self->_children;
        $new //= $self; # no widget = over the toplevel container
        my $old = $self->_mouse_over_widget;

        if ( $new ne $old ) {
            debug( "mouse leaving $old\n" );
            debug( "mouse entering $new\n" );
            $self->_set_mouse_over_widget($new);
            $old->_on_mouse_leave($event) if $old->can("_on_mouse_leave");
            $new->_on_mouse_enter($event) if $new->can("_on_mouse_enter");
        }
    } elsif ( $type == SDL_MOUSEBUTTONDOWN ) {
        #debug( "mouse button down\n" );
        my $curwidget = $self->_mouse_over_widget;
        $curwidget->_on_mouse_down($event)
            if $curwidget->can("_on_mouse_down");
    } elsif ( $type == SDL_MOUSEBUTTONUP ) {
        #debug( "mouse button up\n" );
        my $curwidget = $self->_mouse_over_widget;
        $curwidget->_on_mouse_up($event)
            if $curwidget->can("_on_mouse_up");
    }
}


#
#    $toplevel->_recompute;
#
# Request C<$toplevel> to recompute the size of all its children,
# recursively. Refer to the packer algorithm in L<SDLx::GUI::Pack> for
# more information. Note that this method doesn't request C<$toplevel>
# to be redrawn!
#
sub _recompute {
    my $self = shift;
    my $app  = $self->app;

    debug( "recomputing $self\n" );

    # first, clear all previous positionning
    foreach my $c ( $self->_children ) {
        my $pack = $self->_pack_info;
        next unless defined $pack;
        $pack->_clear_parcel;
        $pack->_clear_slave_dims;
        $pack->_clear_clip;
    }

    my $cavity = SDLx::Rect->new( 0, 0, $app->w, $app->h );
    debug( "cavity is " . _rects($cavity) . "\n" );

    foreach my $child ( grep { $_->is_packed } $self->_children ) {
        my $pack = $child->_pack_info;
        debug( "checking $child\n" );
        my ($childw, $childh) = $child->_wanted_size;

        debug( "child $child wants [$childw,$childh] at ".$pack->side. "\n" );
        my ($px, $py, $pw, $ph);
        my $side = $pack->side;
        if ( $side eq "top" ) {
            $pw = $cavity->w;
            $ph = $childh;
            $px = $cavity->x;
            $py = $cavity->y;
            $cavity = SDLx::Rect->new(
                $cavity->x, $cavity->y + $ph,
                $cavity->w, $cavity->h - $ph,
            );
        }
        elsif ( $side eq "bottom" ) {
            $pw = $cavity->w;
            $ph = $childh;
            $px = $cavity->x;
            $py = $cavity->y + $cavity->h - $childh;
            $cavity = SDLx::Rect->new(
                $cavity->x, $cavity->y,
                $cavity->w, $cavity->h - $ph,
            );
        }
        elsif ( $side eq "left" ) {
            $pw = $childw;
            $ph = $cavity->h;
            $px = $cavity->x;
            $py = $cavity->y;
            $cavity = SDLx::Rect->new(
                $cavity->x + $pw, $cavity->y,
                $cavity->w - $pw, $cavity->h,
            );
        }
        elsif ( $side eq "right" ) {
            $pw = $childw;
            $ph = $cavity->h;
            $px = $cavity->x + $cavity->w - $childw;
            $py = $cavity->y;
            $cavity = SDLx::Rect->new(
                $cavity->x,       $cavity->y,
                $cavity->w - $pw, $cavity->h,
            );
        }
        else {
            croak "uh? should not get there";
        }
        $pack->_set_parcel( SDLx::Rect->new($px,$py,$pw,$ph) );
        $pack->_set_slave_dims( SDLx::Rect->new($px,$py,$childw,$childh) );
        debug( "parcel:     " . _rects($pack->_parcel) . "\n" );
        debug( "slave dims: " . _rects($pack->_slave_dims) . "\n" );
        debug( "cavity:     " . _rects($cavity) . "\n" );
    }
}


# -- private functions

#
# my $string = _rects( $rect );
#
# Return a string with $rect main info: "[x,y,w,h]".
#
sub _rects {
    my $r = shift;
    return "[" . join(",",$r->x, $r->y, $r->w, $r->h) . "]";
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SDLx::GUI::Widget::Toplevel - Toplevel widget for whole app screen

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This package provides a widget that will cover the whole application
screen. It should be used as the base widget upon which all the other
ones will be drawn.

=head2 Widget creation

One can call methods named after the widget class to be created on the
toplevel. It will try to load said class and return the wanted widget.
For example:

    my $button = $toplevel->Button( ... );
    my $label  = $toplevel->Label( ... );

will return a L<SDLx::GUI::Widget::Label> and a
L<SDLx::GUI::Widget::Button> object.

=head1 ATTRIBUTES

=head2 app

A reference to the main SDL application (a L<SDLx::App> object).
Mandatory, but storead as a weak reference.

=head1 METHODS

=head2 draw

    $top->draw;

Request C<$top> to be redrawn on the main application window, along with
all its children.

=for Pod::Coverage AUTOLOAD ^SDL_.*$

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
