#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
package Paw::Window;
use strict;
use Paw::Container;
use Paw::Box;
use Paw::Statusbar;

@Paw::Window::ISA = qw(Paw Paw::Container Exporter );
use Curses;

=head1 Window

B<$window=Paw::Window->new($height, $width, [$abs_x], [$abs_y], [$color], [$name], [\&callback], [\$statusbar], [$orientation], [\&time_function]);>

B<Parameter>

     $height         => number of rows

     $width          => number of columns

     $abs_x          => absolute x-coordinate at the screen
                        [optionally]

     $abs_y          => absolute y-coordinate at the screen
                        [optionally]

     $color          => the colorpair must be generated with
                        Curses::init_pair(pair_nr, COLOR_fg, COLOR_bg)
                        [optionally]

     $name           => name of the widget [optionally]

     \&callback      => reference to the function which will be
                        executed on each key-press.
                        [optionally]

     $quit_key       => Key-Code which terminates the window
                        [optionally]

     \@statusbar     => Reference of an array with 10 elements
                        [optionally]

     \$statusbar     => a reference on a scalar-string wich should
                        appear as text in the statusbar [optional]
                        Since it concerns a reference,
                        the text can be changed at run time.

     $orientation    => "topleft", "topright", "bottomleft",
                        "bottomright", "center"  "grow"
                        are the possible parameters.
                        They indicate how the box will behave on
                        modifications of the terminal size.
                        Either it keeps it's distance to the
                        indicated terminal side, it remains
                        centered or it grows/shrinks with
                        the new terminal size
                        (default is "center") [optionally].

     $title          => Title of the box (will be shown in the top-left
                        corner of the box [optionally]

     \&time_function => This function will be called about
                        every 0,1 seconds as long as
                        the window has the focus.

B<Example>

     $window=Paw::Window->new(height=>20, width=>10,
                                  color=>2, callback=>\&function,
                                  statusbar=>\$status, quit_key=>KEY_F(10));

B<Callback>

The callback method usually is a loop which constantly checks the keyboard for pressed keys and passes
those key-codes to the active widget. The internal callback routine, which one is used if none
callback Function for the window is defined, for example :

     sub Paw_main_loop {
    
         my $main_win = $_[0];
     
         my $i = "";
         $main_win->_refresh();
         while ( not $main_win->{close_it} and
                     ($i ne $main_win->{quit_key}) )
         {
             $this->{main_win} = $main_win;
             $i = getch();                  # read key
             &{$main_win->{time_function}} if ( defined $main_win->{time_function} );
             if ( $i ne -1 ) {
                 $main_win->key_press($i);  # keycode to widgetset
                 $main_win->_refresh();
             }
             else {
                 $main_win->_refresh() if ( defined $main_win->{time_function} );
             }
         };
         Curses::clear();
         $main_win->{close_it}=0;
         endwin();
     }

if the getch() Function don't receive a key-code for about 0,1 seconds, then
it will be left again and "$i" contains the value " -1 ".
$widget->key_press($i) passes the key-code to the active widget.

=head2 get_window_parameter()

returns the most important parameters of the window.

B<Example>

     ($cols, $rows, $color)=$win->get_window_parameter();

=head2 put_dir($direction)

sets the pack-direction of the next widget. "v"ertically or "h"orizontally.
This function can be walked around by using boxes.

B<Example>

     $win->put_dir("h");

=head2 close_win();

The window loses the focus. If no other window takes over the focus, the program ends.

B<Example>

     $win->close_win();

=head2 put($widget)

put the widget into the window.

B<Example>

     $win->put($button0);

=head2 set_border(["shade"])

activate the border of the window, optionally with shadow.

B<Example>

     $win->set_border("shade"); oder $win->set_border();

=head2 set_focus($widget_name)

Sets the focus not on the next widget but on the "$widget_name" named one.
Required however that the widget has a name. 

B<Example>

     $win->set_focus($button0);

=head2 abs_move_curs($new_x, $new_y);

Sets the packer to the absolute position in the box (negative values lay outside of the box).

B<Example>

     $win->abs_move_curs(new_y=>5, new_x=>2);

=head2 rel_move_curs($new_x, $new_y);

Sets the packer relative to the current position in the box (also negative values are possible).

B<Example>

     $win->rel_move_curs(new_x=>-5);

=cut

sub new {
    my $class     = shift;
    my $this      = Paw->new_widget_base;
    my %params    = @_;
    my @widgets;                           #Fensterinhalt - Widgets Pointer
    my @act_wid;
    my %group;
    my %act_group;
    my @func_keys_dflt = ( '1=', '2=', '3=', '4=', '5=', '6=', '7=', '8=', '9=Menu', '10=Quit' );

    $this->{name}      = $params{name};    #Name des Fensters (nicht Titel)
    $this->{event_func}= (defined $params{callback})?($params{callback}):(\&Paw::Paw_main_loop);
    $this->{ax}        = (defined $params{abs_x})?($params{abs_x}):(0);   #absolute Position im Schirm
    $this->{ay}        = (defined $params{abs_y})?($params{abs_y}):(0);   #    "        "     "    "
    $this->{rows}      = $params{height};  #Fensterhoehe
    $this->{cols}      = $params{width};   #Fensterbreite
    $this->{color_pair}= (defined $params{color})?($params{color}):(1);
    $this->{quit_key}  = (defined $params{quit_key})?($params{quit_key}):(-2);
    $this->{statusbar} = (defined $params{statusbar})?($params{statusbar}):(0);
    $this->{func_keys} = (ref($params{statusbar}))?($params{statusbar}):(\@func_keys_dflt);
    $this->{title}     = (defined $params{title})?($params{title}):('');
    $this->{orientation}= (defined $params{orientation})?($params{orientation}):('center');
    $this->{time_function} = (defined $params{time_function})?($params{time_function}):();
    $this->{widgets}   = \@widgets;        #Array of all Widget Pointer
                                           #for the refresh
    $this->{act_wid}   = \@act_wid;        #Array of all activate able Widgets
                                           #for switching between Widgets
    $this->{act_hash}  = \%act_group;
    $this->{group_hash}= \%group;
    $this->{group}     = '_default';
    $this->{put_dir}   = 'v';
    $this->{type}      = 'window';
    $this->{prev_wid}  = {rows=>0};
    $this->{is_act}    = 1;
    $this->{close_it}  = 0;
    $this->{growing}   = 0;
    
    bless ($this, $class);
    if ( not defined $this->{name} ) {
        $this->{name} = ( $this->{title} )?($this->{title}):('auto_window');
    }
    $this->{group_hash}->{'_default'}=\@widgets;
    $this->{act_hash}->{'_default'}=\@act_wid;
    $this->new_group('_menu');
    return $this;
};

sub size_is_dirty {
    my $this = shift;
    my %params = @_;
    my $new_x = $params{new_x};
    my $new_y = $params{new_y};
    my $old_x = $params{old_x};
    my $old_y = $params{old_y};
    
    my $x_diff=$new_x-$old_x;
    my $y_diff=$new_y-$old_y;
    clear();
    $this->clear_screen();
    $this->move_widgets($x_diff, $y_diff);
    
    $this->_refresh();
}

sub get_window_parameter {
    my $this = shift;
    
    return ($this->{cols}, $this->{rows}, $this->{color_pair});
}
sub set_box_pos {
    my $this = shift;
    my $widget = 0;
    
    foreach my $widgets_of_group ( values(%{$this->{group_hash}}) ) {
        my @widgets_array = @{$widgets_of_group};
        my $anz_wid = @widgets_array;
        for (my $i=0; $i < $anz_wid; $i++) {
            $widget=$widgets_array[$i];
            if ( $widget->{type} eq 'box' ) {
                $widget->{ax}=$this->{ax}+$widget->{wx};
                $widget->{ay}=$this->{ay}+$widget->{wy};
                $widget->set_box_pos();
            }
        }
    }
    return;
}


sub next_active {
    my $this = shift;

    $this->{active}->{is_act}=0;
    shift @{$this->{act_wid}};
    push @{$this->{act_wid}}, $this->{active};
    $this->{active}=$this->{act_wid}[0];
    $this->{active}->{is_act}=1;
    $this->_refresh();
    return $this->{active};
}

sub prev_active {
    my $this = shift;

    $this->{active}->{is_act}=0;
    my $last=pop @{$this->{act_wid}};
    unshift @{$this->{act_wid}}, $last;
    $this->{active}=$this->{act_wid}[0];
    $this->{active}->{is_act}=1;
    $this->_refresh();
    return $this->{active};
}

sub key_press {
    my $this = shift;
    my $key  = $_[0];

    $key = '' if ( not defined $key );

    # Taste ans Widget durchreichen, wenn es die Taste
    # nicht auswerten kann, wird sie zurueckgegeben.
    $key=$this->{active}->key_press($key) if ( $this->{active}->{act_able} );
    return '' if ( $key eq '' );
    
    if ($key eq "\t" or $key eq KEY_DOWN or $key eq KEY_RIGHT) {
        $this->next_active();
        $key = 0;
    }
    # Key up aktiviert vorheriges Widget
    elsif ( $key eq KEY_UP or $key eq KEY_LEFT) {
        $this->prev_active();
        $key = 0;
    }
    elsif ( $key eq KEY_F(9) and @{$this->{group_hash}->{'_menu'}} and ( not $this->{parent} or $this->{parent}->{type} ne 'pull_down_menu') ) {
        my $old_active=($this->{active});
        ($this->{group} eq '_menu')?($this->activate_group('_default')) : ($this->activate_group('_menu'));
        $this->{active}->{is_act}=1;
        $this->_refresh();
        $key=0;
    }
    $this->{active}->{is_act}=1;
    $this->_refresh();
    return $key;
}


sub put_dir {
    my $this = shift;

    $this->{put_dir}=$_[0];

    # jump to the left if put_dir is set to v
    $this->{wx} = 0 if ( $_[0] eq 'v' );
}

sub close_win {
    my $this = shift;

    $this->{close_it} = 1;
}

return 1;
