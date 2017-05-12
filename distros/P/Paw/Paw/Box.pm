#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information

package Paw::Box;

use strict;
use Paw::Container;
use Curses;

@Paw::Box::ISA = qw(Exporter Paw Paw::Container);

=head1 Box Widget

B<$box=Paw::Box->new($direction, [$name], [$title], [$color], [$orientation])>;

B<Parameter>

     $direction   => Direction in that the widgets will be packed
                     "v"ertically or "h"orizontally

     $color       => The colorpair must be generated with
                     Curses::init_pair(pair_nr, COLOR_fg, COLOR_bg)
                     [optionally]

     $name        => Name of the box [optionally]

     $orientation => "topleft", "topright", "bottomleft", "bottomright",
                     "center" and "grow" are the possible parameters.
                     They indicate how the box will behave on
                     modifications of the terminal size.
                     Either it keeps it's distance to the indicated
                     terminal side, it remains centered or it
                     grows/shrinks with the new terminal size
                     (default is the orientation of the parent-widget)
                     [ optionally ].'
B<Example>

     $box=Paw::Box->new(direction=>"v",title=>"Start",color=>1);

=head2 put($widget)

put the widget into the box.

B<Example>

     $box->put($button0);

=head2 set_border(["shade"])

activate the border of the box optionally also with shadows. 

B<Example>

     $box->set_border("shade"); or $win->set_border();

=head2 abs_move_curs($new_x, $new_y);

Sets the packer to the absolute position in the box (negative values lay outside of the box). 

B<Example>

     $box->abs_move_curs(new_x=>1);

=head2 rel_move_curs($new_x, $new_y);

Sets the packer relative to the current position in the box (also negative values are possible). 

B<Example>

     $box->rel_move_curs(new_y=>3, new_x=>-2);

=cut

sub new {
    my $class     = shift;
    my $this      = {};# Paw->new_widget_base();
    my %params    = @_;
    my @widgets;               #Fensterinhalt - Widgets Pointer
    my @act_wid;
    my %group;
    my %act_group;

    $this->{name}      = (defined $params{name})?($params{name}):("_auto_"."box");    #Name des Fensters (nicht Titel)
    $this->{title}     = '';
    $this->{type}      = 'box';
    $this->{direction} = $params{direction};
    $this->{put_dir}   = $params{direction}; #sorry
    $this->{widgets}   = \@widgets;        #Array of all Widget Pointer
                                           #for the refresh
    $this->{act_wid}   = \@act_wid;        #Array of all activate able Widgets
                                           #for switching between Widgets
    $this->{parent}     = $params{parent};
    $this->{color_pair}= (defined $params{color})?($params{color}):($this->{parent}->{color_pair});
    $this->{orientation}= (defined $params{orientation})?($params{orientation}):($params{parent}->{orientation});
    $this->{act_wid_cnt}= 0;
    $this->{act_able}   = 0;
    $this->{leaving}    = 0;
    $this->{box_border} = 0;
    $this->{act_hash}   = \%act_group;
    $this->{group_hash} = \%group;
    $this->{group}      = '_default';
    $this->{set_boxes}  = 1;
    $this->{event_func} = \&Paw::_empty_callback;
    $this->{prev_wid}  = {rows=>0};
    $this->{prev_wid}  = {cols=>0};
    $this->{growing}   = 1;
    $this->{cols}      = 0;
    $this->{rows}      = 0;
    
    bless ($this, $class);
    $this->{wx}        = 0;
    $this->{wy}        = 0;
    $this->{ax}        = 0;
    $this->{ay}        = 0;
    $this->{group_hash}->{'_default'}=\@widgets;
    $this->{act_hash}->{'_default'}=\@act_wid;

    return $this;
}

sub set_box_pos {
    my $this = shift;
    my $anz_wid = @{$this->{widgets}};

    for (my $i=0; $i < $anz_wid; $i++) {
        my $widget=$this->{widgets}->[$i];
        if ( $widget->{type} eq 'box' ) {
            $widget->{ax}=$this->{ax}+$widget->{wx};
            $widget->{ay}=$this->{ay}+$widget->{wy};
            $widget->set_box_pos();                 # deeper and deeper
        }
    }
    return;
}

sub next_active {
    my $this    = shift;

    $this->{active}->{is_act}=0;
    if ( $this->{act_wid_cnt} == (@{$this->{act_wid}}-1) ) {
        $this->{leaving} = 1;
        $this->{parent}->next_active();
    }
    elsif ( $this->{leaving} == 1 ) {
        $this->{leaving} = 0;
        $this->{act_wid_cnt} = 0;
        for ( my $i=0; $i < (@{$this->{act_wid}}-1) ; $i++ ) {
            shift @{$this->{act_wid}};
            push @{$this->{act_wid}}, $this->{active};
            $this->{active}=$this->{act_wid}[0];
        }
        $this->{active}->{is_act}=1;
    }
    else {
        $this->{leaving} = 0;
        shift @{$this->{act_wid}};
        push @{$this->{act_wid}}, $this->{active};
        $this->{act_wid_cnt}++;
        $this->{active}=$this->{act_wid}[0];
        $this->{active}->{is_act}=1;
    }
    return $this->{active};
    #$this->_refresh();
}

sub prev_active {
    my $this    = shift;

    $this->{active}->{is_act}=0;

    if ( $this->{act_wid_cnt} == 0 ) {
        $this->{leaving} = -1;
        $this->{parent}->prev_active();
    }
    elsif ( $this->{leaving} == -1 ) {
        $this->{leaving} = 0;
        $this->{act_wid_cnt} = @{$this->{act_wid}}-1;
        for ( my $i=0; $i < (@{$this->{act_wid}}-1) ; $i++ ) {
            shift @{$this->{act_wid}};
            push @{$this->{act_wid}}, $this->{active};
            $this->{active}=$this->{act_wid}[0];
        }
        $this->{active}->{is_act}=1;
    }
    else {
        $this->{leaving} = 0;
        my $last=pop @{$this->{act_wid}};
        unshift @{$this->{act_wid}}, $last;
        $this->{active}=$this->{act_wid}[0];
        $this->{act_wid_cnt}--;
        $this->{active}->{is_act}=1;
    }
    return $this->{active};
    #$this->_refresh();
}

sub key_press {
    my $this = shift;
    my $key  = $_[0];

    $key = '' if ( not defined $key );
    if ( $this->{active}->{is_act} ) {
        $key=$this->{active}->key_press($key);
        return '' if ( $key eq '' );
    }
    if ( $key eq "\t" or $key eq KEY_DOWN or $key eq KEY_RIGHT ) {
        $this->next_active();
        $key = '';
    }
    # Key up aktiviert vorheriges Widget
    elsif ( $key eq KEY_UP or $key eq KEY_LEFT or (defined $this->{active}->{leaving} and $this->{active}->{leaving}==-1) ) {
        $this->prev_active();
        $key = '';
    }
    $this->{active}->{is_act}=1;
    $this->_refresh();
    return $key;
}

return 1;
