#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
package Paw::Scrollbar;
use strict;

@Paw::Scrollbar::ISA = qw(Paw);
use Curses;

=head1 Scrollbar

B<$sb=Paw::Scrollbar->new($widget, [$name]);  #a little bit buggy>

B<Parameter>

     $name      => Name des Widgets [optional]

     $widget    => A reference to the widget which will be
                   "scrollbared".

B<Example>

     $sb=Paw::Scrollbar->new(widget=>$listbox, name=>"List Scrollbar");

=cut

sub new {
    my $class  = shift;
    my $this   = Paw->new_widget_base;
    my %params = @_;

    $this->{name}      = (defined $params{name})?($params{name}):('_auto_scrollbar');    #Name des Fensters (nicht Titel)
    $this->{widget}    = $params{widget};
    $this->{direction} = 'v';
    $this->{type}      = 'scrollbar';
    if ( $this->{direction} eq 'v' ) {
        $this->{cols} = 1;
        $this->{rows} = $this->{widget}->{rows};
    }
    elsif ( $this->{direction} eq 'h' ){
        $this->{rows} = 1;
        $this->{cols} = $this->{widget}->{cols};
    }    
    bless ($this, $class);
    return $this;
}

sub draw {
    my $this = shift;
    my $line = $_[0];
    my @box  = ();
    
    if ( $this->{direction} eq 'v' ) {
        $this->{wx}   = $this->{widget}->{wx}+$this->{widget}->{cols}+1;
        $this->{wy}   = $this->{widget}->{wy};
    }
    elsif ( $this->{direction} eq "h" ){
        $this->{wy}   = $this->{widget}->{wy}+$this->{widget}->{rows};
        $this->{wx}   = $this->{widget}->{wx};
    }
    #return @box if ( $this->{widget}->{rows} > $this->{widget}->{used_rows} );
    $this->{color_pair} = $this->{parent}->{color_pair};
    attron(COLOR_PAIR($this->{color_pair}));
    my $full=$this->{widget}->{used_rows};
    my $ar=$this->{widget}->{active_row};
    my $piece=( (($full)/($this->{rows})) );
    for ( my $i=0; $i<$this->{rows}; $i++ ) {
        if ( $ar == int($piece*$i) ) {
            $box[$this->{last_time}] = '|' if ( defined $this->{last_time} );
            $this->{last_time}=$i;
        }
        $box[$i]='|';
        $box[$this->{last_time}] = '#';
    }
    addch($box[$line]);
}
return 1;
