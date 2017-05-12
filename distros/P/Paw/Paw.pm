#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
require Exporter;
use Carp;
use strict;
package Paw;

$Paw::VERSION = "0.54";

use Curses;

=head1 General

Apart from this documentation there are also some commentated examples of some Widgets,
as well as a complete example for the GUI of a Setup-program (app2.pl).


=head2 using widgets

A new Widget is always created by

     $WIDGET_REFERENCE=Paw::WIDGETNAME->new(PARAMETERNAME=>VALUE).

The PARAMETERs must be passed as HASH (PARAMETERNAME=>VALUE) to the widget,
even if there is only one parameter for the widget.
The methods of a widget are used by

     $WIDGET_REFERENCE->METHOD(PARAMETER)
     $WIDGET_REFERENCE->METHOD(PARAMETER1=>VALUE1, PARAMETER2=>VALUE2)


If the method permits only one or zero parameters, it's not necessary to designate the parameter in a HASH,
for example

     $window->put($widget).

If more than 1 parameter is possible, then each parameter must be designated by it's name,
for example

     $window->abs_move_curs(new_x=>5, new_y=>6) #is okay,

while

     $window->abs_move_curs(5) # is not okay
     $window->put_dir("h")     # is quite permitted.

=head2 Initialisation

Every program that uses this modul looks the same in the first lines of code.

     #!/usr/bin/perl
     use Curses;
     use widget;
     ($columns, $rows)=Paw::init_widgetset();

$columns and $rows contains the terminal width and height.
This values can be used to calculate the size or position of other windows, for example

     $main_win=Paw::Window->new(abs_x=>1, abs_y=>1,
                               height=$rows-3, width=>$columns-2,
                               color=>1, statusbar=>1);

=head2 Colors

While the initialisation of the widgetset, some colorpairs are set.

     init_pair(1, COLOR_WHITE, COLOR_BLUE);   #default colors
     init_pair(31, COLOR_BLACK, COLOR_BLACK); #shadow
     init_pair(30, COLOR_BLACK, COLOR_CYAN);  #pulldown menu
     init_pair(29, COLOR_BLACK, COLOR_BLUE);  #filedialog

Already defined colors are black, red, green, yellow, blue, magenta, cyan, and white
New colorpairs can be created by :

     init_pair(pair, foreground_color, background_color);

Further information about the colormodel can be found in the documentation of
the curses lib (man ncurses, perldoc Curses).

=head2 Widgetpacker

There are two ways how to get widgets into a window.
The first one is to use the put($widget) function of the window,
the second way is to use boxes (recommended).

without boxes:

     #put the $label2 into the window
     $win2->put($label2);                      
     #tell to packer to put the next widget horizontally to the $label2
     $win2->put_dir("h");   # horizontal packen    
     #keep on putting widgets ...
     $win2->put($butt1);    # Button for Faktor 2 
     $win2->put($label3);   # Faktor 3             
     $win2->put($butt2);    # Button for Faktor 3 
     $win2->put($label4);   # Faktor 4             
     $win2->put($butt3);    # Button for Faktor 4
     #switch the packer to vertikal-mode...
     $win2->put_dir("v");
     #...to get the label under the other widgets.
     $win2->put($label5);   # "Ergebnis : ..."

We will get

     $label2 $butt1 $label3 $butt2 $label4 $butt3                                        
     $label5

or

     Faktor 2 [ ] Faktor 3 [ ] Faktor 4 [ ]
     Ergebnis : 200

This type of widget-packing is nice for smaller GUIs and surely a fast solution but
you will come very fast to the boundaries of your possibilities.
Then the boxes seems to be the better solution.

A box takes up several widgets and puts them always either horizontal or vertically.
The Clou at a box is that it can also take up other boxes.
It is possible that a horizontal box is to be packed into a vertical box and this in any depth.
If you  know the widgetpacker of GTK or TK, you know this widgetpacker too.


     ###########################################
     # 7 Buttons building an H
     ###########################################

     $vbox0->put($b1);

     $hbox1->put($b2);
     $hbox1->put($b3);

     $vbox0->put($hbox1);
     $vbox0->put($b4);

     $hbox0->put($vbox0);

     $vbox1->put($b5);
     $vbox1->put($b6);
     $vbox1->put($b7);

     $hbox0->put($vbox1);

     $win->put($hbox0);

We will get:

     [1]   [5]
     [2][3][6]
     [4]   [7]

=head1 SEE ALSO

Paw::Box          container for other Widgets

Paw::Button       simple Button (optionally with label)

Paw::Filedialog   filedialog Widget

Paw::Label        simple text label

Paw::Line         h/v line (seperator for menus)

Paw::Listbox      box with selectable lines

Paw::Menu         pulldown menus

Paw::Popup        popup window with text and buttons

Paw::Progressbar  a progressbar

Paw::Radiobutton  a group of buttons but only one can be selected

Paw::Scrollbar    scrollbar for other widgets (listbox...) no mouse support

Paw::Statusbar    bottomline for windows

Paw::Text_entry   enter one line of text

Paw::Textbox      box with more lines of text (buggy !!!)

Paw::Window       container for other widgets

=head1 COPYRIGHT

Copyright (c) 1999 SuSE GmbH, Nuernberg, Germany. All rights reserved.

=cut


#
# "Subroutine %s redefined" Warning sucks - so it got to be killed.
#
$SIG{'__WARN__'} = sub {
    for ( $_[0] ) {
        /Subroutine [\w\d_\-]+ redefined at/ && do {
            # okay, maybe I want to see a warning....
            return;
        };
	# Return all other errors
	warn $_;
    }
};

sub new_widget_base {
    my $class      = shift;
    my $this       = {};      #Fensterdaten

    $this = {
        parent        => 0,      #Elternwidget
        name          => '',     #Name des Widget
        rows          => 0,      #Widgethoehe
        cols          => 0,      #Widgetbreite
        wx            => 0,      #Cursorposition x
        wy            => 0,      #      "        y
        type          => '',     #Widget Bezeichnung
        border        => 0,      #Rahmen Bit 1=AN/AUS 2=Shade/NoShade
        direction     => 'h',
        is_act        => 0,
        act_able      => 0,
        wx            => 0,
        wy            => 0,
        ax            => 0,
        ay            => 0,            
        screen_cols   => COLS,
        screen_rows   => LINES,
        #anz_pairs    => COLOR_PAIRS,   # not supportet by perl curses :-(
        anz_pairs     => 32,
        size_is_dirty => 0,
        main_win      => 0,
        time_counter  => 0,
    };
    bless ($this, $class);
    return $this;
}
sub _empty_callback {
    return;
}

sub size_is_dirty {
    return;
}

sub get_name {
    my $this=shift;
    return $this->{name};
}

sub set_border {
    my $this = shift;
    my $param = shift;

    $param = '' if ( not $param );
    $this->{border} = 1;
    $this->{border} = $this->{border}+2 if ( $param eq 'shade' );
}

sub unset_border {
    my $this = shift;

    $this->{border} = 0;
}

sub abs_move_widget {
    my $this   = shift;
    my %params = @_;

    $this->{wx} = $params{new_x} if defined $params{new_x};
    $this->{wy} = $params{new_y} if defined $params{new_y};
}

sub get_widget_pos {
    my $this = shift;

    return ( $this->{wx}, $this->{wy} );
}

sub set_color {
    my $this = shift;
    $this->{color_pair} = shift;
}

#
# catch the Window Change Signal - this rocks
#
sub catch_SIGWINCH {

    my $old_x = COLS;
    my $old_y = LINES;
    Curses::endwin();
    Curses::refresh();
    @Paw::terminal_size = (COLS,LINES);
    $Paw::main_win->size_is_dirty(old_x=>$old_x, old_y=>$old_y, new_x=>COLS, new_y=>LINES);
}

sub init_widgetset {

    #
    # Curses Initialisierung
    #

    #my $anz_pairs = COLOR_PAIRS;  # not supportet :-(
    my $anz_pairs = 32;
    initscr();
    start_color();
    keypad(1);
    noecho();
    $SIG{WINCH}=\&catch_SIGWINCH;  #slightly unstable ? got not reproduceable segfaults
    init_pair(1, COLOR_WHITE, COLOR_BLUE);             #default Color
    init_pair($anz_pairs-1, COLOR_BLACK, COLOR_BLACK); #Shadow of Pop-Up
    init_pair($anz_pairs-2, COLOR_BLACK, COLOR_CYAN);  #Pulldown Menu
    init_pair($anz_pairs-3, COLOR_BLACK, COLOR_BLUE);  #Filedialog
    halfdelay(1);
    @Paw::terminal_size = (COLS,LINES);
    return (COLS,LINES);
}

sub Paw_main_loop {
    my $main_win = shift;
    $Paw::main_win = $main_win;

    my $i = '';
    $main_win->_refresh();
    while ( not $main_win->{close_it} and ($i ne $main_win->{quit_key}) ) {
#        $this->{main_win} = $main_win;
        $i = getch();              # Tastendruck einlesen
        &{$main_win->{time_function}} if defined $main_win->{time_function};
        if ( $i ne -1 ) {
            $main_win->key_press($i);  # Taste sofort ans Widgetset
            $main_win->_refresh();
        }
        else {
            $main_win->_refresh() if defined $main_win->{time_function};
        }
    };
    Curses::clear();
    $main_win->{close_it}=0;
    endwin();
}
