#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
package Paw::Radiobutton;
use strict;

@Paw::Radiobutton::ISA = qw(Paw);
use Curses;

=head1 Radiobutton Widget

B<$rb=Paw::Radiobutton->new(\@labels, [$direction], [$color], [$name], [\&callback]);>

B<Parameter>

     \@labels   => array of label for the buttons,
                   one element for each button.

     $color     => The colorpair must be generated with
                   Curses::init_pair(pair_nr, COLOR_fg, COLOR_bg)
                   [optionally]

     $name      => name of the widget [optionally]

     \&callback => reference to a function which will be executed
                   if the radiobutton is being pressed. [optional]

     $direction => "h"orizontally or "v"ertically (default) [optionally]

B<Example>

     @labels=("Red", "Green", "Blue");
     $rb=Paw::Radiobutton->new(labels=>\@labels, direction=>"v");

B<Callback>

Similarly as with the normal button.

=head2 set_button()

the aktive button will be set/pushed.

B<Example>

     $rb->set_button();

=head2 get_pressed()

returns the number of the pressed button. (starting at 0).

B<Example>

     $pushed_button=$rb->get_pressed();

=head2 abs_move_widget($new_x, $new_y)

the widget moves to the new absolute screen position.
if you set only one of the two parameters, the other one keeps the old value.

B<Example>

     $rb->abs_move_widget( new_x=>5 );      #y-pos is the same

=head2 get_widget_pos()

returns an array of two values, the x-position and the y-position of the widget.

B<Example>

     ($xpos,$ypos)=$rb->get_widget_pos();

=head2 set_color($color_pair)

Set a new color_pair for the widget.

B<Example>

     $box->set_color(3);

=head2 set_border(["shade"])

activates the border of the widget (optionally also with shadows). 

B<Example>

     $widget->set_border("shade"); or $widget->set_border();


=cut

sub new {
    my $class  = shift;
    my $this   = Paw->new_widget_base;
    my %params = @_;
    my @label  = @{$params{labels}};

    $this->{name}      = (defined $params{name})?($params{name}):('_auto_radiobutton');    #Name des Fensters (nicht Titel)
    $this->{direction} = (defined $params{direction})?($params{direction}):('v');
    $this->{callback}  = $params{callback};
    $this->{act_able}  = 1;
    $this->{rows}      = 1;
    $this->{label}     = \@label;
    $this->{type}      = 'radiobutton';
    $this->{act_elem}  = 0;
    $this->{view_start_y} = 0;
    $this->{active_row} = 0;
    $this->{color_pair}= (defined $params{color})?($params{color}):(0);
    
    bless ($this, $class);
    if ( $this->{direction} eq 'h' ) {
        $this->{rows} = 1;
        for ( my $i=0; $i < @label; $i++ ) {
            $this->{cols}=$this->{cols}+(length $label[$i])+4;
        }
    }
    else {
        $this->{rows}=@label;
        $this->{cols}=((length $label[0])+4);
        for ( my $i=0; $i < @label; $i++ ) {
            if ($this->{cols} < ( (length $label[$i])+4) ) {
                $this->{cols} = ( (length $label[$i])+4);
            }
        }
    }
    return $this;
}

sub draw {
    my $this    = shift;
    my $line    = shift;
    my $anz     = @{$this->{label}};
    my @arr     = @{$this->{label}};
    $this->{color_pair} = $this->{parent}->{color_pair} if ( not defined $this->{color_pair} );
    attron(COLOR_PAIR($this->{color_pair}));
    
    for ( my $i=0; $i < $anz; $i++ ) {
        if ( $this->{direction} eq 'v' ) {
            my $fill = ($this->{cols} - (length $arr[$i])-4);
            my $dummy;
            $dummy = ($arr[$i] . (' ' x $fill) . ( ($i==$this->{act_elem}) ? (' (x)'):(' ( )') ));
            if ( $this->{is_act} ) {
                ($i==$this->{active_row})?(attron(A_REVERSE)):(attroff(A_REVERSE));
            }
            addstr($dummy) if ( $i == $line );
        }
        else {
            my $dummy=$arr[$i] . ( ($i==$this->{act_elem}) ? (' (x)'):(' ( )') );
            ($i==$this->{active_row})?(attron(A_REVERSE)):(attroff(A_REVERSE));
            addstr($dummy);
        }
    }
}

sub set_button {
    my $this     = shift;
    my $text     = $this->{text};
    my $anz      = @{$this->{label}};
    my $callback = $this->{callback};
    
    $this->{act_elem}=($this->{act_elem}==$anz) ? (0) : ($this->{active_row});
    &$callback if ($this->{callback});
}

sub get_pressed {
    my $this = shift;
    my $text = $this->{text};

    return ( $this->{act_elem} );
}

sub key_press {
    my $this = shift;
    my $key  = shift;
    my $anz  = @{$this->{label}};

    if ( $key eq ' ' or $key eq "\n" ) {
        $this->set_button();
        return '';
    }
    elsif ( $key eq KEY_UP ) {
        $this->{active_row} = $this->{active_row}-1 if ($this->{active_row} > 0);
        return '';
    }
    elsif ( $key eq KEY_DOWN ) {
        $this->{active_row} = $this->{active_row}+1 if ($this->{active_row} < $anz-1);
        return '';
    }
    return $key;
}

return 1;
