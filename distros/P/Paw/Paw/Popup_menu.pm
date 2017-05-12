#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information

package Paw::Popup_menu;
use Curses;
use strict;
use Paw::Window;
use Paw::Listbox;
use Curses;
@Paw::Menu::ISA = qw(Paw);

=head1 Listbox

B<$lb= new Paw::Popup_menu ( \@data, [$size], [$width], [$default], [$color], [\&callback], [$name]);>

B<Parameter>

     \@data     => Reference to an array that contains the entries

     $size      => Number of entries that are shown without scrolling,
                   if the widget is pushed [default is 5]

     $width     => Number of columns [default is 15]

     $default   => Number of the default element (starting at 0) 
                   [default is 0]

     $name      => Name of the widget [optionally]

     $color     => the colorpair must be generated with
                   Curses::init_pair(pair_nr, COLOR_fg, COLOR_bg)
                   [optionally]
     
     \&callback => will be called when the value has changed. 
                   the $this reference is given to it and no return value will be parsed

B<Example>

     $data = [ "one", "two", "three", "four" ];
     $pm=Paw::Popup_menu->new( data => $data, width=>10, size=>8 );

=head2 get_choice()

returns the choosen value of the box as string

B<Example>

  $choice = $pm->get_choice();

=head2 set_choice($number)

sets the choosen value of the box. $number is the element number in the array

B<Example>

  $pm->set_choice(3);


=cut


sub new {
    my $class  = shift;
    my $this   = Paw->new_widget_base;
    my %params = @_;

    bless ($this, $class);
    $this->{name}       = (defined $params{name})?($params{name}):('_auto_popup_menu');
    $this->{cols}       = (defined $params{width})?($params{width}):(15);
    $this->{size}       = (defined $params{size})?($params{size}):(5);
    $this->{rows}       = 1;
    $this->{data}       = $params{data};
    $this->{choosen}    = (defined $params{default})?($params{default}):(0);
    $this->{act_able}   = 1;
    $this->{auto_popup} = (defined $params{auto_popup})?($params{auto_popup}):(0);
    $this->{color_pair} = (defined $params{color})?($params{color}):(undef);
    $this->{callback}   = (defined $params{callback})?($params{callback}):(undef);

    my $window = Paw::Window->new( abs_x   => $this->{ax}, 
				   abs_y   => $this->{ay}, 
				   callback=> \&_win_cb,
				   height  => $this->{size}, width=>$this->{cols} );
    $window->set_border();
    $window->set_border('shade') if defined $params{'shade'};
    my $listbox = Paw::Listbox->new(
				    name     => '__lb',
				    width    => $this->{cols},
				    height   => $this->{size},
				   );
    foreach ( @{$params{data}} ) {
	$listbox->add_row($_);
    }
    $window->put($listbox);
    $window->{parent}=$this;
    $this->{window}  = $window;
    $this->{listbox} = $listbox;
    return $this;
}

sub key_press {
    my $this = shift;
    my $key  = shift;
    
    $key = '' if not defined $key;
    
    if ( $key eq "\n" or $key eq ' ' ) {
	$this->{'window'}->{ax} = $this->{wx}+$this->{parent}->{ax};
	$this->{'window'}->{ay} = $this->{wy}+2+$this->{parent}->{ay};
	$this->{'window'}->set_focus('__lb');
	$this->{'window'}->raise();
	&{$this->{callback}}($this) if ( defined $this->{callback} );
	return '';
    }
    else {
	return $key;
    }
}

sub get_choice {
    my $this = shift;

    my $active_row = $this->{listbox}->{active_row};
    my @data = @{$this->{data}};
    $this->{choosen} = $active_row;
    return $this->{data}->[$this->{choosen}];
}

sub set_choice {
    my $this = shift;
    my $choice = shift;
    my $box_rows = $this->{listbox}->{rows};

    $choice = $this->{listbox}->number_of_data()-1 if ( $choice >= $this->{listbox}->number_of_data() );
    $this->{listbox}->{view_start_y} = $choice;
    $this->{listbox}->{active_row} = $choice;
}

sub draw {
    my $this = shift;
    my $active_row = $this->{listbox}->{active_row};
    my @data = @{$this->{data}};
    $this->{color_pair} = $this->{parent}->{color_pair} if ( not defined $this->{color_pair} );
    $this->{window}->{color_pair} = $this->{color_pair};
    $this->{window}->set_focus('__lb');

    $this->{choosen} = $active_row;
    my $string = $this->{data}->[$this->{choosen}];
    if ( length($string) > $this->{cols}-2 ) {
	$string  = substr($string, 0, ($this->{cols}-2));
	$string .= "v";
    }
    else {
	$string .= ("_"x($this->{cols}-length($string)-2));
	$string .= "v";
    }
    attron(COLOR_PAIR($this->{color_pair}));
    if ( $this->{is_act} == 1 ) {
	attron(A_REVERSE);
	addstr($string);
	attroff(A_REVERSE);
    }
    else {
	addstr($string);
    }
}

sub _win_cb {
    my $this = shift;
    my $i;

    do {
	$i = getch();                  # read key
	if ( $i eq ' ' ) {
	    $i = -1;
	}
	elsif ( $i eq "\n" ) {
	    return;
	}
	if ( $i ne -1 ) {
	    $this->key_press($i);      # keycode to widgetset
	    $this->_refresh();
	}
    } while ( $i ne "\n" );
}
