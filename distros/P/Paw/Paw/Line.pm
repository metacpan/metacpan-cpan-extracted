#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
package Paw::Line;
use strict;

@Paw::Line::ISA = qw(Paw);
use Curses;

=head1 Line Widget

B<$line=Paw::Line->new($length, [$name], [$char], [$direction])>;

B<Parameter>

     $name      => name of the widget [optionally]

     $char      => character that will be used to build the line
                   (ACS_HLINE) [optionally]

     $direction => "v"ertically or "h"orizontally (default) [optional]

     $length    => length in characters of the line

B<Example>

     $l=Paw::Line->new(length=>$columns, char=>"#");

=head2 abs_move_widget($new_x, $new_y)

the widget moves to the new absolute screen position.
if you set only one of the two parameters, the other one keeps the old value.

B<Example>

     $l->abs_move_widget( new_x=>5 );      #y-pos is the same

=head2 get_widget_pos()

returns an array of two values, the x-position and the y-position of the widget.

B<Example>

     ($xpos,$ypos)=$l->get_widget_pos();

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

    $this->{name}        = (defined $params{name})?($params{name}):('_auto_line');    #Name des Fensters (nicht Titel)
    $this->{cols}        = 1;
    $this->{rows}        = 1;
    $this->{char}        = (defined $params{char})?($params{char}):(ACS_HLINE);
    $this->{size}        = $params{length};
    $this->{direction}   = (defined $params{direction})?($params{direction}):('h');
    $this->{type}        = 'line';
    $this->{print_style} = 'char';
    
    bless ($this, $class);
    ( $this->{direction} eq 'v' ) ? ($this->{rows}=$this->{size}):($this->{cols}=$this->{size});
    return $this;
}

sub draw {
    my $this    = shift;
    my $line    = shift;
    $this->{color_pair} = $this->{parent}->{color_pair} if ( not defined $this->{color_pair} );
    attron(COLOR_PAIR($this->{color_pair}));
    
    if ( $this->{direction} eq 'h' ) {
        for ( my $i=0; $i<$this->{size}; $i++ ) {
            addch( $this->{char} );
        }
    }
    else {
        addch($this->{char});
    }
}
return 1;
