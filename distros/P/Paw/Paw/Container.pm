#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information

package Paw::Container;

@ISA = qw(Exporter);
@EXPORT = qw();
use Curses;

sub draw_border {
    my $this  = shift;
    my $style = $_[0];

    $style="shade" if ( $this->{box_border}&2 );
    attron( COLOR_PAIR($this->{color_pair}) );
    #
    # draw Edges
    #
    $this->abs_move_curs(new_x=>-1, new_y=>-1);
    addch(ACS_ULCORNER);
    addstr ($this->{title}) if ( $this->{title});
    $this->abs_move_curs(new_x=>$this->{cols}, new_y=>-1);
    addch(ACS_URCORNER);
    #
    # draw horizontal Lines (top,down)
    #
    #$this->abs_move_curs(new_x=>-1, new_y=>0);
    for( my $i=(length $this->{title}); $i<$this->{cols}; $i++ ) {
        $this->abs_move_curs(new_x=>$i, new_y=>-1);
        addch(ACS_HLINE);
    }

    for( my $i=0; $i<$this->{cols}; $i++ ) {
        $this->abs_move_curs(new_x=>$i, new_y=>$this->{rows}+1);
        addch(ACS_HLINE);
    }

    #
    # draw vertical Lines (left, right)
    #
    for ( my $i=0; $i<$this->{rows}+1; $i++ ) {
        $this->abs_move_curs(new_x=>-1, new_y=>$i);
        addch(ACS_VLINE);
        $this->abs_move_curs(new_x=>$this->{cols}, new_y=>$i);
        addch(ACS_VLINE);
    }
    $this->abs_move_curs(new_x=>-1, new_y=>$this->{rows}+1);
    addch(ACS_LLCORNER);
    $this->abs_move_curs(new_x=>$this->{cols}, new_y=>($this->{rows}+1));
    addch(ACS_LRCORNER);
    if ( $style and $style eq "shade" ) {
        bkgdset(" ");
        attron(COLOR_PAIR($this->{anz_pairs}-1));
        for( my $i=0; $i<$this->{cols}+2; $i++ ) {
            $this->abs_move_curs(new_x=>$i, new_y=>$this->{rows}+2);
            addch(" ");
        }
        for ( my $i=0; $i<$this->{rows}+2; $i++ ) {
            $this->abs_move_curs(new_x=>$this->{cols}+1, new_y=>$i);
            addch(" ");
        }
    }
    attroff(A_REVERSE);
}

sub set_focus {
    my $this       = shift;
    my $widget     = shift;
    my $act_widget = $this->{active};
    my $success    = 0;

FIND:
    for ( my $i=0; $i < @{$this->{act_wid}}; $i++ ) {
        if ( not $success and $widget ne $this->{active}->{name} ) {
            if ( $this->{active}->{type} eq "box" ) {
                $success=$this->{active}->set_focus($widget);
            }
            else {
                $this->next_active();
            }
        }
        else {
            $success=1;
            last FIND;
        }
    }
    return $success;
}

sub rel_move_curs {
    my $this = shift;
    my %params = @_;
    my $new_x  = $params{new_x};
    my $new_y  = $params{new_y};

    $this->{wy} = ( $this->{wy}+$new_y ) if defined $new_y ;
    $this->{wx} = ( $this->{wx}+$new_x ) if defined $new_x ;
    move($this->{ay}+$this->{wy}, $this->{ax}+$this->{wx});
}

sub abs_move_curs {
    my $this   = shift;
    my %params = @_;
    my $new_x  = (defined $params{new_x}) ? ($params{new_x}):(0);
    my $new_y  = (defined $params{new_y}) ? ($params{new_y}):(0);

    $this->{wy}=$new_y;
    $this->{wx}=$new_x;
    move($this->{ay}+$new_y, $this->{ax}+$new_x);
}

sub _refresh {
    my $this = shift;
    my $widget = 0;
    my @drawn_widget;
    my @widgets_array;
    my $widgets_of_group;
    my $anz_wid = 0;
    my $y=0;
    my $x=0;

    $this->{color_pair} = $this->{parent}->{color_pair} if ( not defined $this->{color_pair} );

    if ( $this->{border} ) {
        $this->{box_border}=$this->{border};
        $this->{border}=0;
    }
    $this->draw_border() if ( $this->{box_border} );
    $_[0] = "clear" if ( not $_[0] );
    attron( COLOR_PAIR($this->{color_pair}) );
    $this->clear_win() if ( $_[0] ne "no_clear" );
    foreach $widgets_of_group ( values(%{$this->{group_hash}}) ) {
        @widgets_array = @{$widgets_of_group};
        $anz_wid = @widgets_array;
        for (my $i=0; $i < $anz_wid; $i++) {
            $this->{active}->{is_act}=($this->{is_act})?(1):(0);
            $y=0;
            $x=0;
            $widget=$widgets_array[$i];
            if ( $widget->{border} ) {
                $this->{wx} = ($widget->{wx});
                $this->{wy} = ($widget->{wy}-1);
                move($this->{wy}+$this->{ay}+$y, $this->{wx}+$this->{ax}+$x);
                addch(ACS_ULCORNER);
                for ( my $k=0; $k<$widget->{cols}; $k++ ) {
                    addch(ACS_HLINE);
                }
                addch(ACS_URCORNER);
            }
            $this->{wx} = $widget->{wx};
            $this->{wy} = $widget->{wy};
            my $anz_lines = $widget->{rows};
            for (my $j=0; $j < $anz_lines; $j++) {
                move($this->{wy}+$this->{ay}+$y, $this->{wx}+$this->{ax}+$x);
                addch(ACS_VLINE) if ( $widget->{border} );
                attron(COLOR_PAIR($widget->{color_pair})) if (defined $widget->{color_pair});
                $widget->draw($j);
                attron(COLOR_PAIR($this->{color_pair}));
                attroff(A_REVERSE+A_BOLD);
                if ( $widget->{border} ) {
                    addch(ACS_VLINE);
                    # Shade ?
                    if ( $widget->{border} & 2 ) {
                        attron(COLOR_PAIR($this->{anz_pairs}-1));
                        addch(" ");
                        attron(COLOR_PAIR($this->{color_pair}));
                    }
                }
                $x=($widget->{direction} eq "h")?(++$x):(0);
                $y=($widget->{direction} eq "v")?(++$y):(0);
                last if ( $widget->{type} eq "box" );
                last if ( defined $this->{screen_cols} and $j == $this->{screen_cols} );
            }
            if ( $widget->{border} ) {
                $this->{wx} = ($widget->{wx});
                if ( $y == 0 ) {
                    $y=1;
                    $x=0;
                }
                move($this->{wy}+$this->{ay}+$y, $this->{wx}+$this->{ax}+$x);
                addch(ACS_LLCORNER);
                for ( my $k=0; $k<$widget->{cols}; $k++ ) {
                    addch(ACS_HLINE);
                }
                addch(ACS_LRCORNER);
                # Shade ?
                if ( $widget->{border} & 2 ) {
                    attron(COLOR_PAIR($this->{anz_pairs}-1));
                    addch(" ");
                    move($this->{wy}+$this->{ay}+$y+1, $this->{wx}+$this->{ax}+$x+1);
                    addstr " " x ($widget->{cols}+2);
                    attron(COLOR_PAIR($this->{color_pair}));
                }
            }
            $x=0;
            $y=0;
        }
    }                    
}
sub draw {
    my $this = shift;
    #$this->_refresh();
    $this->raise();
}

sub raise {
    my $this = shift;
    my $func = $this->{event_func};

    if ( $this->{type} eq "window" and not $this->{box_border} ) {
        $this->{box_border} = $this->{border};
    }
    if ( defined $this->{statusbar} and $this->{statusbar} ) {
        $this->{statusbar}=Paw::Box->new(direction=>"h", orientation=>"bottomleft");
        $this->{statusbar}->put(Paw::Statusbar->new(func_keys=>$this->{func_keys}));
        $this->put($this->{statusbar});
        $this->{statusbar}->{wy}=$this->{rows}-1; #this sucks
        $this->{statusbar}->{wx}=0;             #sorry
    }
    $this->set_box_pos() if ( not $this->{set_boxes} );
    $this->{set_boxes}=1;
    $this->_refresh();
    attron(COLOR_PAIR($this->{color_pair}));
    if ( $this->{box_border} & 2 ) {
        $this->draw_border("shade");
    }
    elsif ( $this->{box_border} & 1 ) {
        $this->draw_border();
    }
        return (&$func($this));
}
sub clear_win {
    my $this = shift;

    for ( my $i=0; $i <= $this->{rows}; $i++ ) {
        $this->abs_move_curs(new_x=>0, new_y=>$i);
        addstr (" " x $this->{cols});
    }
}

sub clear_screen {
    my $this=shift;
    
    for ( my $i=0; $i <= $this->{screen_rows}; $i++ ) {
        $this->abs_move_curs(new_x=>0, new_y=>$i);
        #addstr (" " x $this->{screen_cols});
    }
}

sub put {
    my $this    = shift;
    my $widget  = shift;

    my $group = $this->{group};
    my $dummy = $this->{put_dir};
    my $parent_type = "";

    $this->{anz_pairs} = $widget->{anz_pairs};
    $parent_type = ($this->{parent}) ? ($this->{parent}->{type}) : ("");
    if ( $widget->{type} eq "pull_down_menu" and $parent_type ne "pull_down_menu" ){
        $this->activate_group("_menu");
        $this->{put_dir} = "h";
    }
    my $anz_wid = (defined @{$this->{widgets}})?(@{$this->{widgets}}):(0);
    my $prev_wid = $this->{widgets}->[$anz_wid-1] if ( $anz_wid > 0 );;
    push (@{$this->{widgets}}, $widget);
    if ( $this->{put_dir} eq "h" ) {
        $this->{wx} += $prev_wid->{cols} if ( defined $prev_wid->{cols} );
        $this->{wx} += 2 if ( $prev_wid->{border} );
        #$this->{wx} += 1 if ( $widget->{border} );
        if ( $this->{growing} ) {
            if ( $this->{rows} < $widget->{rows} ) {
                $this->{rows} =  $widget->{rows};
                $this->{rows} += 2 if ( $widget->{border} );  # ???
            }
            $this->{cols} += $widget->{cols};
            $this->{cols} += 2 if ( $widget->{border} );
        }
    }
    else {
        $this->{wy} += $prev_wid->{rows} if ( defined $prev_wid->{rows} );
        $this->{wy} += 2 if ( defined $prev_wid->{border} and $prev_wid->{border} );
        #$this->{wy} += 1 if ( $widget->{border} );
        if ( $this->{growing} ) {
            if ( $this->{cols} < $widget->{cols} ) {
                $this->{cols} = $widget->{cols};
                $this->{cols} += 2 if ( $widget->{border} );
            }
            $this->{rows} += $widget->{rows};
            $this->{rows} += 2 if ( $widget->{border} );
        }
    }
    $widget->{wx} = $this->{wx};
    $widget->{wy} = $this->{wy};
    $widget->{ax} = ($this->{wx}+$this->{ax}) if ( $widget->{type} eq "box" );
    $widget->{ay} = ($this->{wy}+$this->{ay}) if ( $widget->{type} eq "box" );
    $widget->{parent} = $this;                   #Elternwidget merken
    if ( $widget->{act_able}==1 ) {
        push (@{$this->{act_wid}}, $widget);     #Widget in die Liste der aktivierbaren Widgets
        $this->{active}=$this->{act_wid}->[0];   #aktives Widget immer das erste in Liste.
        $this->{active}->{is_act}=1;             #teile dem aktiven Widget mit das es aktiv ist
        $this->{act_able} = 1;
    }
    $this->{put_dir}=$dummy;
    $this->activate_group($group);
}

sub activate_group {
    my $this = shift;

    $this->{group}   = $_[0];
    $this->{widgets} = $this->{group_hash}->{$_[0]};
    $this->{act_wid} = $this->{act_hash}->{$_[0]};
    $this->{active}->{is_act}=0;
    $this->{active}=$this->{act_wid}->[0];
}

sub new_group {
    
    my $this = shift;
    my @widgets = ();
    my @act_list= ();
    
    $this->{group_hash}->{$_[0]} = \@widgets;
    $this->{act_hash}->{$_[0]} = \@act_list;
}

sub move_widgets {
    my $this=shift;
    my $x_diff=shift;
    my $y_diff=shift;

    if ( $this->{orientation} eq "center" ) {
        $this->{ax}+=int($x_diff/2);
        $this->{ay}+=int($y_diff/2);
    }
    elsif ( $this->{orientation} eq "topleft" ) {

    }
    elsif ( $this->{orientation} eq "topright" ) {
        $this->{ax}+=int($x_diff);
    }
    elsif ( $this->{orientation} eq "bottomleft" ) {
        $this->{ay}+=int($y_diff);
    }
    elsif ( $this->{orientation} eq "bottomright" ) {
        $this->{ax}+=int($x_diff);
        $this->{ay}+=int($y_diff);
    }
    elsif ( $this->{orientation} eq "grow" ) {
        $this->{cols}+=int($x_diff);
        $this->{rows}+=int($y_diff);
    }

    $this->{ax}=0 if ( $this->{ax} < 0 );
    $this->{ay}=0 if ( $this->{ay} < 0 );
    
    foreach $widgets_of_group ( values(%{$this->{group_hash}}) ) {
        my @widgets_array = @{$widgets_of_group};
        my $anz_wid = @widgets_array;
        for (my $i=0; $i < $anz_wid; $i++) {
            my $widget=$widgets_array[$i];
            if ( $widget->{type} eq "box" ) {
                $widget->move_widgets($x_diff, $y_diff);
            }
        }
    }
    return;
}

return 1;
