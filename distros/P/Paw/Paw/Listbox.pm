#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
package Paw::Listbox;
use strict;

@Paw::Listbox::ISA = qw(Paw);
use Curses;

=head1 Listbox

B<$lb=Paw::Listbox->new($height, $width, [$colored], [$name]);>

B<Parameter>

     $height  => Number of rows

     $width   => Number of columns

     $colored => 1 turns on the colored mode
                 (see also "add_row") default=0 [optionally]

     $name    => Name of the widget [optionally]

B<Example>

     $lb=Paw::Listbox->new(width=>10, height=>15, colored=>1);

=head2 clear_listbox()

deletes all entrys out of the listbox

B<Example>

     $listbox->clear_listbox();

=head2 add_row($data, $color), add_row(\@data);

adds a data-row into the listbox. When the color mode is activated, you can give a second parameter as color-pair number.
Alternatively you can give a refernce to an array to the listbox and it will put gradually each array element into the box.
If the color mode is on, each second element of the array B<must> be a color-pair number.

B<Example>

     $listbox->add_row("Test", 3);

=head2 del_row($number)

deletes the row with the number "$number". Start counting at zero.

B<Example>

     $listbox->del_row(4);

=head2 change_rows($first, $second);

swaps the $first and the $second row of the listbox.

B<Example>

     $listbox->change_rows($lower, $upper);

=head2 number_of_data()

returns the number of data-rows in the listbox.

B<Example>

     $data=$listbox->number_of_data();

=head2 get_pushed_rows("data"), get_pushed_rows("linenumbers");

returns an array of all pushed data-rows, either the linenumbers or the data.

B<Example>

     @data_rows=$listbox->get_pushed_rows("linenumbers");

=head2 get_all_rows();

returns an array with the complete contents of the listbox.

B<Example>

     @full_data=$listbox->get_all_rows();

=head2 abs_move_widget($new_x, $new_y)

the widget moves to the new absolute screen position.
if you set only one of the two parameters, the other one keeps the old value.

B<Example>

     $listbox->abs_move_widget( new_x=>5 );      #y-pos is the same

=head2 get_widget_pos()

returns an array of two values, the x-position and the y-position of the widget.

B<Example>

     ($xpos,$ypos)=$listbox->get_widget_pos();

=head2 set_border(["shade"])

activates the border of the widget (optionally also with shadows). 

B<Example>

     $widget->set_border("shade"); or $widget->set_border();

=cut

sub new {
    my $class = shift;
    my $this = Paw->new_widget_base;
    my %params = @_;
    my @label  = ();
    my @pushed = ();
    my @colors = ();
    $this->{name}         = (defined $params{name})?($params{name}):('_auto_listbox');    #Name des Fensters (nicht Titel)
    $this->{act_able}     = 1;
    $this->{cols}         = $params{width};
    $this->{rows}         = $params{height};
    $this->{colored}      = (defined $params{colored})?($params{colored}):(0);
    $this->{callback}     = (defined $params{callback})?($params{callback}):(undef);
    $this->{data}         = \@label;
    $this->{colors}       = \@colors;
    $this->{direction}    = 'v';
    $this->{type}         = 'listbox';
    $this->{pushed}       = \@pushed;
    $this->{view_start_y} = 0;
    $this->{active_row}   = 0;
    $this->{used_rows}    = 0;

    bless ($this, $class);
    $this->{view_end} = ($this->{view_start_y}+$this->{rows});

    return $this;
}

sub clear_listbox {
    my $this = shift;

    $this->{data}=[];
    $this->{colors}=[];
    $this->{pushed}=[];
    $this->{active_row} = 0;
    $this->{used_rows} = 0;
    $this->{view_start_y} = 0;
}

sub add_row {
    my $this = shift;
    my $data = $_[0];
    my $color= (defined $_[-1])?($_[-1]):(0);

    if ( ref($data) eq 'ARRAY' ) {
        for ( my $i=0; $i<@{$data}; $i++ ) {
            push (@{$this->{data}},$$data[$i]);
            push (@{$this->{colors}}, $color);
            $this->{pushed}->[$this->{used_rows}] = 0;
            $this->{used_rows}++;
        }
    }
    else {
        push (@{$this->{data}},$data);
        push (@{$this->{colors}}, $color);
        $this->{pushed}->[$this->{used_rows}] = 0;
        $this->{used_rows}++;
    }
}

sub del_row {
    my $this = shift;
    my $pos  = shift;
    my $under= $pos-1;
    my $over = $pos+1;
    my $end  = $this->{used_rows}-1;

    $this->{pushed}->[$pos]=0;
    @{$this->{data}}=(@{$this->{data}}[0 .. $under], @{$this->{data}}[$over .. $end]);
    @{$this->{pushed}}=(@{$this->{pushed}}[0 .. $under], @{$this->{pushed}}[$over .. $end]);
    
    $this->{used_rows}--;
    $this->{active_row}-- if ( $pos <= $this->{active_row} );
    #$this->{parent}->_refresh();
    return;
}

sub change_rows {
    my $this = shift;
    my $pos_a = shift;
    my $pos_b = shift;

    $this->{data}->[$pos_a] = $pos_b;
    my $dummy=$this->{pushed}->[$pos_a];
    $this->{pushed}->[$pos_a]=$this->{pushed}->[$pos_b];
    $this->{pushed}->[$pos_b]=$dummy;
    #    $this->{parent}->_refresh();
}

sub number_of_data {
    my $this = shift;

    return $this->{used_rows};
}

sub get_pushed_rows {
    my $this = shift;
    my $what = shift;
    my @ret  = ();
    my @data = @{$this->{data}};
    
    for ( my $i=0; $i < $this->{used_rows}; $i++) {
        if ( $what eq 'data' ) {
            push (@ret,$data[$i]) if ( $this->{pushed}->[$i] );
        }
        elsif ( $what eq 'linenumbers' ) {
            push (@ret,$i) if ( $this->{pushed}->[$i] );
        }
    }
    return @ret;
}

sub get_all_rows {
    my $this = shift;

    return @{$this->{data}};
}

sub draw {
    my $this = shift;
    my $i = shift;
    $this->{color_pair} = $this->{parent}->{color_pair} if ( not defined $this->{color_pair} );

    $this->{view_end} = ($this->{view_start_y}+$this->{rows});

    my $string = @{$this->{data}}[$i+$this->{view_start_y}];
    $string = '' if not defined $string;
    $string = substr($string, 0, $this->{cols}) if ( defined $string );
    attron(A_BOLD) if ($this->{pushed}->[$i+$this->{view_start_y}]);
    if ( $this->{is_act} and $i+$this->{view_start_y} == $this->{active_row} ) {
        attron(A_REVERSE);
    }
    $string.= ' ' x ($this->{cols} - length($string));
    my $pair=($this->{colored})?($this->{colors}->[$i+$this->{view_start_y}]):($this->{color_pair});
    attron(COLOR_PAIR($pair)) if defined $pair;
    addstr($string);
    attron(COLOR_PAIR($this->{color_pair}));
    attroff(A_BOLD);
    attroff(A_REVERSE);
}

sub key_press {
    my $this = shift;
    my $key  = shift;
    my $active_row = $this->{active_row};

    $key = '' if not defined $key;
#    $key=&{$this->{callback}}($this, $key) if ( defined $this->{callback} );

    if ( $key eq KEY_DOWN and ($active_row < $this->{used_rows}-1) ) {
        $this->{active_row}++;
        if ( $this->{view_end} < $active_row+2 ) {
            $this->{view_start_y}++;
            $this->{view_end} = $this->{view_start_y}+$this->{rows};
        }
        $key = '';
    }
    elsif ( $key eq KEY_UP and ($active_row > 0)) {
        if ( $this->{active_row} > 0 ) {
            $this->{active_row}--;
            if ( $this->{view_start_y} > $this->{active_row} ) {
                $this->{view_start_y} = $this->{active_row};
                $this->{view_end} = $this->{view_start_y}+$this->{rows};
            }
        }
        $key = '';
    }
    elsif ( ($key eq ' ' or $key eq "\n") ) {
        $this->{pushed}->[$active_row] = ~$this->{pushed}->[$active_row];
        $this->key_press(KEY_DOWN);
        if ( $this->{parent}->{parent} and
	     $this->{parent}->{parent}->{type} and
             $this->{parent}->{parent}->{type} eq 'filedialog' and
             $key eq "\n" )
        {
            $this->{parent}->{parent}->{ok}->push_button();
        }
        $key = '';
    }
    elsif ( $key eq KEY_NPAGE ) {
        for ( my $i=0; $i<$this->{rows}; $i++ ) {
            $this->key_press(KEY_DOWN);
        }
    }
    elsif ( $key eq KEY_PPAGE ) {
        for ( my $i=0; $i<$this->{rows}; $i++ ) {
            $this->key_press(KEY_UP);
        }
    }
    elsif ( $key eq KEY_DOWN or $key eq KEY_UP ) {
        $key = '';
    }
    return $key;
}
return 1;
