#!/usr/bin/perl

package SDLx::Widget::Textbox;

use strict;
use warnings;

use SDL;
use SDLx::App;
use SDL::Event;
use SDL::Events;
use SDL::TTF;
use Encode;
use Clipboard;
use Time::HiRes;

use Mouse;

our $VERSION = '0.072';

has 'app'          => ( is => 'ro', isa => 'SDLx::Controller', required => 1 );
has 'value'        => ( is => 'rw', isa => 'Str', default => '' );
has 'focus'        => ( is => 'rw', isa => 'Int', default => 0 );
has 'cursor'       => ( is => 'rw', isa => 'Int', default => 0 );
has 'cursor_moved' => ( is => 'rw', isa => 'Int', default => 0 );
has 'mousedown'    => ( is => 'rw', isa => 'Int', default => 0 );
has 'x'            => ( is => 'rw', isa => 'Int' ,required => 1 );
has 'y'            => ( is => 'rw', isa => 'Int' ,required => 1 );
has 'w'            => ( is => 'rw', isa => 'Int' ,required => 1 );
has 'h'            => ( is => 'rw', isa => 'Int' ,required => 1 );
has 'name'         => ( is => 'rw', isa => 'Str', required => 1  );
has 'textbox'      => ( is => 'rw', isa => 'HashRef', default => sub{ {} } );

sub BUILD {
    my $self = shift;
    $self->{textbox_render} = sub {
        my $_self = $self;
        my $delta = $_[0];
        $_self->app->draw_rect( [$_self->x, $_self->y, $_self->w, $_self->h], [255,255,255,255] );
        
        # calculation the text-highlight-box on mouse movement
        if($self->{mousedown} && $_self->{value}) {
            my ($mask, $mouse_x)      = @{ SDL::Events::get_mouse_state( ) };
            my $text_end              = $_self->x + 2 + length($_self->{value}) * 8;
            $mouse_x                  = $_self->x + $_self->w if $mouse_x > $_self->x + $_self->w;
            $mouse_x                  = $_self->x               if $mouse_x < $_self->x;
            $mouse_x                  = $text_end                 if $mouse_x > $text_end;
            $_self->{mousedown}       = $text_end                 if $_self->{mousedown} > $text_end;
            $_self->{selection_start} = int(($_self->{mousedown} - 2 - $_self->x) / 8 + 0.5);
            $_self->{selection_stop}  = int(($mouse_x            - 2 - $_self->x) / 8 + 0.5);
        }
        
        # drawing the text-highlight-box
        if(defined $_self->{selection_start} && defined $_self->{selection_stop} && $_self->{selection_start} != $_self->{selection_stop}) {
            ($_self->{selection_start}, $_self->{selection_stop}) = sort {$a <=> $b} ($_self->{selection_start}, $_self->{selection_stop});
            my $width = ($_self->{selection_stop} - $_self->{selection_start}) * 8;
            my $left  = $_self->{selection_start} * 8 + 2 + $_self->x;
            $_self->app->draw_rect( [$left, $_self->y + 2, $width, $_self->h - 4], [128,128,255,255] );
        }
        
        # drawing the name of the textbox in grey letters
        if($_self->{name} && !length($_self->{value}) && !$_self->{focus}) {
            $_self->app->draw_gfx_text( [$_self->x + 3, $_self->y + 7], 0xAAAAAAFF, $_self->{name} );
        }
        # drawing asterisk for password fields
        elsif($_self->{password}) {
            $_self->app->draw_gfx_text( [$_self->x + 3, $_self->y + 7], 0x000000FF, '*' x length($_self->{value}) );
        }
        # drawing the value
        else {
            $_self->app->draw_gfx_text( [$_self->x + 3, $_self->y + 7], 0x000000FF, $_self->{value} );
        }

        # drawing the blinking cursor
        if($_self->{focus}
        && ((int($_self->app->ticks/600) % 2) || $_self->{cursor_moved} + 500 > $_self->app->ticks)
        && (!defined $_self->{selection_start} || !defined $_self->{selection_stop} || $_self->{selection_start} == $_self->{selection_stop})) {
            my $x = $_self->x + 2 + $_self->cursor * 8;
            $_self->app->draw_line( [$x, $_self->y + 2], [$x, $_self->y + $_self->h - 4], 0x000000FF );
        }
        $_self->app->update;
    };

    $self->app->add_event_handler( sub{$self->event_handler(@_)} );
    SDL::Events::enable_unicode(1);
}


sub show {
    my $self = shift;

    $self->app->add_show_handler( $self->{textbox_render}, $self );
}

sub event_handler {
    my ($self, $event, $app) = @_;
    
    if(SDL_MOUSEMOTION == $event->type) {
        # on_mousemotion
        if($self->x <= $event->motion_x && $event->motion_x < $self->x + $self->w
        && $self->y <= $event->motion_y && $event->motion_y < $self->y + $self->h) {
                
        }

        # on_drag
        if($self->{focus} && $self->{mousedown}) {
        
        }
    }
    elsif(SDL_MOUSEBUTTONDOWN == $event->type) {
        if($self->x <= $event->button_x && $event->button_x < $self->x + $self->w
        && $self->y <= $event->button_y && $event->button_y < $self->y + $self->h) {
            # on_mousedown
            if(SDL_BUTTON_LEFT == $event->button_button) {
                if(!$self->{focus}) {
                    # on_focus
                    $self->{focus} = 1;
                }
                else {
                    # single click
                    if(!defined $self->{lastclick} || Time::HiRes::time - $self->{lastclick} >= 0.3) {
                        #warn 'on_click';
                        $self->{cursor} = int(($event->button_x - 2 - $self->x) / 8 + 0.5);
                        $self->{cursor} = length($self->{value}) if $self->{cursor} > length($self->{value});
                        $self->{mousedown} = $event->button_x;
                    }
                    # double click (selecting word)
                    elsif(!defined $self->{lastdoubleclick} || Time::HiRes::time - $self->{lastdoubleclick} >= 0.3) {
                        # on_doubleclick
                        if(substr($self->{value}, 0, $self->{cursor}) =~ m/^(.+)\b.{1}/) {
                            $self->{selection_start} = length($1);
                        }
                        else {
                            $self->{selection_start} = 0;
                        }
                        
                        if(substr($self->{value}, $self->{cursor})    =~ m/.{1}\b(.+)$/) {
                            $self->{selection_stop} = length($self->{value}) - length($1);
                        }
                        else {
                            $self->{selection_stop} = length($self->{value});
                        }
                        $self->{lastdoubleclick} = Time::HiRes::time;
                    }
                    # trippel click (select all)
                    else {
                        # on_trippelclick
                        $self->{lastwasdblclick} = undef;
                        $self->{selection_start} = 0;
                        $self->{selection_stop}  = length($self->{value});
                    }
                    $self->{lastclick} = Time::HiRes::time;
                }
            }
        }
    }
    elsif(SDL_MOUSEBUTTONUP == $event->type) {
        if($self->x <= $event->button_x && $event->button_x < $self->x + $self->w
        && $self->y <= $event->button_y && $event->button_y < $self->y + $self->h) {
            # on_mouseup
        }
        else {
            if(SDL_BUTTON_LEFT == $event->button_button && $self->{focus}) {
                # on_blur
                $self->{selection_start} = undef;
                $self->{selection_stop}  = undef;
                $self->{focus}           = 0;
            }
        }
        $self->{mousedown} = 0;
    }
    elsif(SDL_KEYDOWN == $event->type) { # on_keydown
        if($self->{focus}) {
            my $key = SDL::Events::get_key_name($event->key_sym);
            my $mod = SDL::Events::get_mod_state();
            
            $key = ' ' if $key eq 'space';
            
            if($mod & KMOD_CTRL) {
                # on_ctrldown
                if($key eq 'v') {
                    $self->{value}   = substr($self->{value}, 0, $self->{cursor})
                                     . Clipboard->paste
                                     . substr($self->{value}, $self->{cursor});
                    $self->{cursor} += length(Clipboard->paste);
                }
                elsif(defined $self->{selection_start} && defined $self->{selection_stop}) {
                    ($self->{selection_start}, $self->{selection_stop}) = sort {$a <=> $b} ($self->{selection_start}, $self->{selection_stop});
                    if($key eq 'c') {
                        Clipboard->copy(substr($self->{value}, $self->{selection_start}, $self->{selection_stop} - $self->{selection_start}));
                    }
                    elsif($key eq 'x') {
                        Clipboard->copy(substr($self->{value}, $self->{selection_start}, $self->{selection_stop} - $self->{selection_start}));
                        $self->{value} = substr($self->{value}, 0, $self->{selection_start})
                                       . substr($self->{value}, $self->{selection_stop});
                        $self->{selection_start} = undef;
                        $self->{selection_stop}  = undef;
                    }
                }
            }
            elsif($key =~ /\bshift$/) {
                # on_shiftdown
                $self->{shiftdown} = $self->{cursor};
            }
            elsif($key eq 'left') {
                $self->{cursor}-- if $self->{cursor} > 0;
                $self->{cursor_moved} = $self->app->ticks;
                if(defined $self->{shiftdown}) {
                    $self->{selection_start} = $self->{cursor};
                    $self->{selection_stop}  = $self->{shiftdown};
                }
                else {
                    $self->{selection_start} = undef;
                    $self->{selection_stop}  = undef;
                }
            }
            elsif($key eq 'right') {
                $self->{cursor}++ if $self->{cursor} < length($self->{value});
                $self->{cursor_moved} = $self->app->ticks;
                if(defined $self->{shiftdown}) {
                    $self->{selection_start} = $self->{shiftdown};
                    $self->{selection_stop}  = $self->{cursor};
                }
                else {
                    $self->{selection_start} = undef;
                    $self->{selection_stop}  = undef;
                }
            }
            elsif($key eq 'home') {
                if(defined $self->{shiftdown}) {
                    $self->{selection_start} = 0;
                    $self->{selection_stop}  = $self->{selection_stop} ? $self->{selection_stop} : $self->{cursor};
                }
                else {
                    $self->{selection_start} = undef;
                    $self->{selection_stop}  = undef;
                }
            }
            elsif($key eq 'end') {
                if(defined $self->{shiftdown}) {
                    $self->{selection_start} = $self->{selection_start} ? $self->{selection_start} : $self->{cursor};
                    $self->{selection_stop}  = length($self->{value});
                }
                else {
                    $self->{selection_start} = undef;
                    $self->{selection_stop}  = undef;
                }
            }
            elsif($key eq 'delete') {
                if(defined $self->{selection_start} && defined $self->{selection_stop} && $self->{selection_start} != $self->{selection_stop}) {
                    $self->{value} = substr($self->{value}, 0, $self->{selection_start})
                                   . substr($self->{value}, $self->{selection_stop});
                    $self->{cursor} = $self->{selection_start};
                    $self->{selection_start} = undef;
                    $self->{selection_stop}  = undef;
                }
                elsif($self->{cursor} < length($self->{value})) {
                    $self->{value} = substr($self->{value}, 0, $self->{cursor})
                                   . substr($self->{value}, $self->{cursor} + 1);
                }
            }
            elsif($key eq 'backspace') {
                if(defined $self->{selection_start} && defined $self->{selection_stop} && $self->{selection_start} != $self->{selection_stop}) {
                    $self->{value} = substr($self->{value}, 0, $self->{selection_start})
                                   . substr($self->{value}, $self->{selection_stop});
                    $self->{cursor} = $self->{selection_start};
                    $self->{selection_start} = undef;
                    $self->{selection_stop}  = undef;
                }
                elsif($self->{cursor} > 0) {
                    $self->{value} = substr($self->{value}, 0, $self->{cursor} - 1)
                                   . substr($self->{value}, $self->{cursor});
                    $self->{cursor}--;
                }
            }
            elsif($event->key_unicode && (length($key) == 1 || (length($key) == 3 && $key =~ s/\[|\]//) )) {
                if(defined $self->{selection_start} && defined $self->{selection_stop} && $self->{selection_start} != $self->{selection_stop}) {
                    $self->{value} = substr($self->{value}, 0, $self->{selection_start})
                                   . chr($event->key_unicode)
                                   . substr($self->{value}, $self->{selection_stop});
                    $self->{cursor} = $self->{selection_start} + 1;
                    $self->{selection_start} = undef;
                    $self->{selection_stop}  = undef;
                }
                else {
                    $self->{value} = substr($self->{value}, 0, $self->{cursor})
                                   . chr($event->key_unicode)
                                   . substr($self->{value}, $self->{cursor});
                    $self->{cursor}++;
                }
            }

        }
    }
    elsif(SDL_KEYUP == $event->type) {
        if($self->{focus}) {
            my $key = SDL::Events::get_key_name($event->key_sym);
            # on_keyup
            if($key =~ /\bshift$/) {
                $self->{shiftdown}  = undef;
            }
        }
    }
}


sub value :lvalue
{
    $_[0]->{value}
}

sub focus :lvalue
{
    $_[0]->{focus}
}

sub DESTROY {
    my $self = shift;
}

1;
__END__
=head1 NAME

SDLx::Widget::Textbox - create text boxes for your SDL apps easily

=head1 SYNOPSIS

Create a simple SDL text for your L<SDLx::App>:

    $textbox = SDLx::Widget::Textbox->new(app => $app, x => 200, y => 200, w => 200, h => 20, name => 'username');
    $passbox = SDLx::Widget::Textbox->new(app => $app, x => 200, y => 230, w => 200, h => 20, name => 'password', password => 1);
    $textbox->show;
    $passbox->show;

C<$app> is L<SDLx::App> or L<SDLx::Controller>.

Get the value out by:

    my $text_value = $textbox->value;

Also know if it is focused right now.

    warn 'Stop typing here!' if $textbox->focus;

=head1 METHODS

=head2 event_handler( $event )

=head2 show( $surface )

=head1 SEE ALSO

L<< SDL >>, L<< SDLx::App >>, L<< SDLx::Controller >>

