#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
package Paw::Text_entry;
use strict;

@Paw::Text_entry::ISA = qw(Paw);
use Curses;

=head1 Textentry Widget

B<$te=Paw::Text_entry->new($width, [$cursor_color], [$color], [$name], [\&callback], [$text], [$side], [$echo], [$max_length] );>

B<Parameter>

     width        => width of the text-entry (in other words: columns)

     color        => the colorpair must be generated with
                   Curses::init_pair(pair_nr, COLOR_fg, COLOR_bg)
                   [optionally]

     cursor_color => same like color but only for the cursor

     name         => name of the widget [optionally]

     callback     => reference to the function that will be
                   executed each time you press a key in the entry.
                   [optionally]

     text         => default text for the entry [optionally]

     orientation  => "left"(default) or "right"
                   for left/right-justified text.

     echo         => 0, 1  oder 2 : 0=no echo of the entered text,
                   1=Stars instead of characters, 2=full echo (default)
                   (0 and 1 good for passwords) [optional]

     max_length   => maximum length of the entry (default = 1024)

B<Example>

     $te=Paw::Text_entry->new(width=>15, text=>"PLEASE ENTER NAME",
                                  max_length=>25); 

B<Callback>

The callback function will be started each time you press a key in the text-entry.
The object reference ($this) and the key value will be given to the callback. 
This will give you the chance to allow only digits or whatever you want. 
You B<must> return the key-value or no text will ever reach into the widget.

sub callback {
   my $this = shift;
   my $key  = shift;

   [... do some stuff ...]

   return $key;
}

=head2 get_text()

returns the text of the entry.

B<Example>

     $text=$te->get_text();

=head2 set_text($text)

set the text in the entry to $text.

B<Example>

     $te->set_text("default");

=head2 abs_move_widget($new_x, $new_y)

the widget moves to the new absolute screen position.
if you set only one of the two parameters, the other one keeps the old value.

B<Example>

     $te->abs_move_widget( new_x=>5 );      #y-pos is the same

=head2 get_widget_pos()

returns an array of two values, the x-position and the y-position of the widget.

B<Example>

     ($xpos,$ypos)=$te->get_widget_pos();

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
    my %cursor;

    $this->{name}        = (defined $params{name})?($params{name}):('_auto_entry');    #Name des Fensters (nicht Titel)
    $this->{string}      = (defined $params{text})?($params{text}):('');
    $this->{cols}        = $params{width};
    $this->{side}        = (defined $params{orientation})?($params{orientation}):('left');
    $this->{echo}        = (defined $params{echo})?($params{echo}):(2);
    $this->{max_length}  = (defined $params{max_length})?($params{max_length}):(1024);
    $this->{color_pair}  = (defined $params{color})?($params{color}):();
    $this->{cursor_color}= (defined $params{cursor_color})?($params{cursor_color}):(undef);
    $this->{act_able}    = 1;
    $this->{rows}        = 1;
    $this->{type}        = 'text_entry';
    $this->{print_style} = 'char';
    $this->{callback}    = $params{callback};
    
    $this->{cursor}   = \%cursor;

    bless ($this, $class);
    $this->{cursor}->{rcx} = ( $this->{side} eq 'right' )?($this->{cols}):0;
    $this->{cursor}->{vcx} = length $this->{string} if ( $this->{side} eq 'right' );
    $this->{cursor}->{rcy} = 0;
    $this->{cursor}->{vcy} = 0;

    return $this;
}

sub draw {
    my $this    = shift;
    my $str_len = ($this->{string})?(length $this->{string}):(0);
    my $dummy   = $this->{string};
    my $vcx     = $this->{cursor}->{vcx};
    my $rcx     = $this->{cursor}->{rcx};
    $this->{color_pair} = $this->{parent}->{color_pair} if ( not defined $this->{color_pair} );

    $vcx = 0 if ( not $vcx );

    #$this->{string} = $dummy         if ( $this->{echo} == 2 );
    $this->{string} = "*" x $str_len if ( $this->{echo} == 1 );
    $this->{string} = "HIDDEN"       if ( $this->{echo} == 0 );

    # bei Breite  == 0 wird die Breite des Parent Widgets genommen
    if ( $this->{cols} == 0 ) {
        $this->{cols} = $this->{parent}->{cols}-$this->{wx};
    }
    # Text Entry aktiv und String ist groesser als Text Entry ?
    if ( $this->{is_act} and ($str_len >= $this->{cols}) ) {
        if ( $vcx+$this->{cols} < $str_len and $rcx == 0 ) {
            $this->{text}=substr($this->{string}, $vcx, $vcx+$this->{cols});
        }
        elsif ( $this->{cols} <= $str_len and $rcx <= $this->{cols} ) {
            $this->{text}=substr($this->{string}, $vcx-$rcx, $vcx-$rcx+$this->{cols});
        }
    }
    # Text Entry NICHT aktiv und String ist groesser als Text Entry ?
    elsif ( $str_len > $this->{cols} ) {
        $this->{text}=substr $this->{string}, 0, $this->{cols};
    }
    # String passt ins Text Entry evtl. sogar kleiner
    else {
        if ( $this->{side} eq 'left' ) {
            if ( $rcx == 0 and $vcx == 0 ) {
                $this->{text}=$this->{string} . ( '_' x ( $this->{cols}-$str_len) );
            }
            else {
                $this->{text}=substr $this->{string}, $vcx-$rcx;
            }
        }
        elsif ( $this->{side} eq 'right' ) {
            $this->{text}=( '_' x ( $this->{cols}-$str_len ) . $this->{string} );
        }
    }
    if (length $this->{text} < $this->{cols} ) {
        $this->{text}.= ( '_' x ( $this->{cols}-length $this->{text}) );
    }
    if ( $this->{side} eq 'right' and $vcx<$rcx ) {
        $this->{text}=( '_' x ( $rcx-$vcx ) . $this->{string} );
    }
    $this->{string}=$dummy;
    attron(COLOR_PAIR($this->{color_pair}));
    if ( $this->{is_act} ) {
        attron(A_REVERSE);
        for ( my $i=0; $i<$this->{cols}; $i++ ) {
	    if ( $this->{cursor}->{rcx} == $i ) {
		attroff(A_REVERSE);
		attron(COLOR_PAIR($this->{cursor_color})) if ( defined $this->{cursor_color} );
	    }
            my $subst=substr($this->{text}, $i, 1);
            addch( $subst );
	    attron(COLOR_PAIR($this->{color_pair}));
            attron(A_REVERSE);
        }
    }
    else {
        addstr($this->{text});
    }
    return;
}

sub get_text {
    my $this = shift;

    return ( $this->{string} );
}

sub set_text {
    my $this = shift;

    if ( length $_[0] < length $this->{string} ) {
        $this->{cursor}->{rcx} = 0;
        $this->{cursor}->{vcx} = 0;
    }
    $this->{string} = $_[0];
    #$this->{parent}->_refresh();
}

sub key_press {
    my $this = shift;
    my $key  = shift;
    my $vcx  = $this->{cursor}->{vcx};
    my $rcx  = $this->{cursor}->{rcx};

    $vcx = 0 if ( not $vcx );

    $key = "" if ( not $key );
    my $new_string = $this->{string};
    $key=&{$this->{callback}}($this, $key) if ( defined $this->{callback} );
    while ( $key ne KEY_UP and $key ne KEY_DOWN and $key ne "\t" and $key ne "\n") {
        if ( $key eq KEY_BACKSPACE ) {
            $key = '';
            $new_string = ( substr($new_string,0,$vcx-1) . substr($new_string,$vcx) ) if ( $vcx );
            $vcx-- if ( $vcx > 0 );
            $rcx-- if ( $rcx > 0 and $this->{side} eq 'left' );
        }
        elsif ( $key eq KEY_DC ) {
            $key = "";
            if ( $vcx < length($new_string) ) {
                $new_string = ( substr($new_string,0,$vcx) . substr($new_string,$vcx+1) );
            }
            $rcx++ if ($rcx < $this->{cols} and $this->{side} eq 'right');
        }
        elsif ( $key eq KEY_LEFT ) {
            $key = "";
            $vcx-- if ( $vcx > 0 );
            $rcx-- if (
                       ($rcx > 0 and $this->{side} eq 'left') or
                       ($rcx > $this->{cols}-length $new_string and 
			$this->{side} eq 'right' and $rcx > 0)
                      );
        }
        elsif ( $key eq KEY_RIGHT ) {
            $key = "";
            $vcx++ if ( $vcx < length $new_string );
            $rcx++ if ( $rcx < $this->{cols} and 
			( $rcx < length $new_string or $this->{side} eq 'right' ) );
        }
        # special keys.
        elsif ( length($key) > 1 ) {
            return $key;
        }
        if ( length $new_string < $this->{max_length} ) {
            $new_string = ( substr($new_string,0,$vcx) . $key . substr($new_string,$vcx) );
            if ( $this->{side} eq 'right' ) {
                $vcx += length $key;
            }
            else {
                $rcx += length $key if ( $rcx < $this->{cols} );
                $vcx += length $key;
            }
        }
        $this->{cursor}->{vcx} = $vcx;
        $this->{cursor}->{rcx} = $rcx;
        $this->{string} = $new_string;
        $this->{parent}->_refresh();
        $key = getch();
        $key = '' if $key eq -1;  #kill the -1 or the "0" will not work ?-(
        $key=&{$this->{callback}}($this,$key) if ( defined $this->{callback} );
    }
    $this->{parent}->next_active() if ( $key eq "\n" );
    return $key;
}
return 1;
