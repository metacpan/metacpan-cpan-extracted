#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
package Paw::Statusbar;

@Paw::Statusbar::ISA = qw(Paw);
use Curses;

sub new {
    my $class  = shift;
    my $this   = Paw->new_widget_base;
    my %params = @_;

    $this->{name}      = (defined $params{name})?($params{name}):('_auto_statusbar');    #Name des Fensters (nicht Titel)
    $this->{func_keys} = $params{func_keys};
    $this->{color_pair}= $this->{anz_pairs}-2;
    $this->{cols}      = 73;
    $this->{rows}      = 1;
    bless ($this, $class);
    return $this;
}

sub draw {
    my $this = shift;
    my $sb = $this->{func_keys};
    my $sl = "";

    $this->{wy} = $this->{parent}->{rows}-1;
    $this->{wy} = $this->{parent}->{rows} if ($this->{parent}->{parent}->{box_border}); #ungly
    $this->{wx} = ($this->{parent}->{cols}-72)/2+3;
    if ( ref($sb) eq 'ARRAY' ) {
        for ( my $i=1; $i<11; $i++ ) {
            my $dummy = substr($this->{func_keys}->[$i-1],0,7);
            $dummy .= (' ' x (7-length($dummy)));
            $sl .= $dummy;
        }
    }
    else {
        $sl=$$sb.(' ' x (72-length $$sb));;
    }
    attron(COLOR_PAIR($this->{color_pair}));
    addstr($sl) if ( $this->{parent}->{cols} > 72 );
}

return 1;
