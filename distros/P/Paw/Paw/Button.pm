#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information

package Paw::Button;
use strict;
@Paw::Button::ISA = qw(Exporter Paw);
use Curses;

=head1 Button Widget

B<$button=Paw::Button->new([$color], [$name], [\&callback], [$label]);>

B<Parameter>

     color    => the colorpair must be generated with
                 Curses::init_pair(pair_nr, COLOR_fg, COLOR_bg)
                 [optionally]

     name     => name of the button [optionally]

     callback => reference to the function which will be called
                 when pushing the button. [optionally]

     label    => text in the button. If the button contains text,
                 it is not possible to see if it is pushed or not.
                 [optionally]

B<Example>

     $button=Paw::Button->new(callback=>\&button_callback);

B<Callback>

     sub button_callback {
         my $this = shift;             # Referenz to the button
         
         $data = $edit->get_text();
         $box->add_row($data);
         return;
     }

=head2 set_button()

Sets the button into the status " pressed "

B<Example>

     $button->set_button();      # [x]

=head2 release_button()

Sets the button into the status "not pressed"

B<Example>

     $button->release_button();      # [ ]

=head2 push_button()

the button changes it status.

B<Example>

     $button->push_button();      # [x]->[ ], [ ]->[x]

=head2 abs_move_widget($new_x, $new_y)

the widget moves to the new absolute screen position.
if you set only one of the two parameters, the other one keeps the old value.

B<Example>

     $button->abs_move_widget( new_x=>5 );      #y-pos is the same

=head2 get_widget_pos()

returns an array of two values, the x-position and the y-position of the widget.

B<Example>

     ($xpos,$ypos)=$button->get_widget_pos();

=head2 set_color($color_pair)

Set a new color_pair for the widget.

B<Example>

     $button->set_color(3);

=head2 set_border(["shade"])

activates the border of the widget (optionally also with shadows). 

B<Example>

     $widget->set_border("shade"); or $widget->set_border();

=cut

sub new {
    my $class = shift;
    my %params = @_;
    my $this = Paw->new_widget_base;

    $this->{name}      = (defined $params{name})?($params{name}):('_auto_button');    #Name des Fensters (nicht Titel)
    $this->{label}     = $params{text};
    $this->{callback}  = $params{callback};
    $this->{text}      = '[ ]';
    $this->{rows}      = 1;
    $this->{direction} = 'h';
    $this->{type}      = 'button';
    $this->{in_butt}   = ' ';
    $this->{act_able}  = 1;
    $this->{is_act}    = 0;
    $this->{is_pressed}= 0;
    $this->{rows}      = 1;
    $this->{direction} = 'h';
    $this->{color_pair} = (defined $params{color})?($params{color}):(0);
    
    $this->{label} = '' if ( not $this->{label} );
    
    bless ($this, $class);
    $this->{cols}      = ( $this->{label} eq '' )?(3):(length ($this->{label})+2);
    
    return $this;
}

sub draw {
    my $this = shift;
    $this->{color_pair} = $this->{parent}->{color_pair} if ( not defined $this->{color_pair} );

    $this->{text}=(not $this->{label})?("[$this->{in_butt}]"):("[$this->{label}]");
    attron(COLOR_PAIR($this->{color_pair}));
    attron(A_REVERSE) if $this->{is_act} ;
    addstr($this->{text});
}

sub push_button {
    my $this     = shift;
    my $text     = $this->{text};
    my $callback = $this->{callback};
    
    $this->{in_butt}=($this->{in_butt} eq ' ')?('x'):(' ');
    $this->{is_pressed} = ~$this->{is_pressed};

    if ( $this->{callback} ) {
        &$callback($this);
        #$this->release_button();
    }
}

sub set_button {
    my $this     = shift;
    my $text     = $this->{text};
    my $callback = $this->{callback};
    
    $this->{in_butt}='x' if ( not $this->{label} );
    $this->{is_pressed}=1;
    &$callback($this) if ( $this->{callback} );
}

sub release_button {
    my $this     = shift;
    my $text     = $this->{text};
    my $callback = $this->{callback};
    
    $this->{in_butt}=' ' if ( not $this->{label} );
    $this->{is_pressed}=0;
}

sub is_pressed {
    my $this = shift;
    my $text = $this->{text};

    return $this->{is_pressed};
}

sub key_press {
    my $this = shift;
    my $key  = shift;

    if ( $key eq ' ' or $key eq "\n" ) {
        $this->push_button();
        return '';
    }
    return $key;
}

return 1;
