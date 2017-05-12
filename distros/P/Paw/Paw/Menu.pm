#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
package Paw::Menu;
use strict;
use Paw::Window;
use Paw::Button;

@Paw::Menu::ISA = qw(Paw);
use Curses;

=head1 Pulldown Menu

B<$pdm=Paw::Paw->Menu->new($title, [$name], [$border]);>

B<Parameter>

     $title  => visible title

     $name   => name of the widget [optionally]

     $border => only "shade" as option so far [optionally]

B<Example>

     $pdm=Paw::Menu->new(title=>"Datei", border=>"shade");

=head2 add_menu_point($text, \&callback), add_menu_point($other_menu)

generates a new menupoint (with name "$text") and branches on the function "callback", if it is activated.
There is also the possibility to give just another menu and you will get a Pulldown Menu in the Pulldown Menu. 

B<Example>

     $men->add_menu_point("Beep", \&menu_beep);

     #Pulldownmenu "$men" in Pulldownmenu "$men2".
     $men2->add_menu_point($men); 

=cut

sub new {
    my $class  = shift;
    my $this   = Paw->new_widget_base;
    my %params = @_;
    my @points = ();

    $this->{name}      = (defined $params{name})?($params{name}):('_auto_menu');    #Name des Fensters (nicht Titel)
    $this->{title}    = $params{title};
    $this->{shade}    = $params{border};
    $this->{act_able} = 1;
    $this->{rows}     = 1;
    $this->{points}   = \@points;
    $this->{type}     = 'pull_down_menu';
    $this->{window}   = Paw::Window->new(name=>'auto_pulldown_window', callback=>(\&_menu_callback), abs_x=>0, abs_y=>0, height=>-1, width=>0, color=>$this->{anz_pairs}-2);
    $this->{callback} = \&_menu_callback;
    $this->{color_pair} = $this->{anz_pairs}-2;
    
    $this->{window}->{parent} = $this;
    $this->{window}->put_dir('v');
    $this->{window}->set_border($params{border});

    bless ($this, $class);
    $this->{cols}=length $this->{title};
    #$this->{window}->{cols}=$this->{cols};
    return $this;
}

sub _menu_callback {
    my $this = shift;
    my $key  = 'x';

    #    $this->{parent}->{active}=$this;
    while ( $key ne KEY_LEFT and $key ne KEY_RIGHT and unpack ('C',$key) ne '27' and $key ne "\n") {
        $key = getch();
        $this->key_press($key);
        $this->{parent}->{parent}->_refresh();
        $this->_refresh();
        $this->draw_border($this->{parent}->{shade});
    }
    $this->{parent}->{opened}=0;
    #
    # mit Cursor links, Cursor rechts wird auf das linke/rechte
    # Pulldown Menu geschaltet. Es sei denn das PullDownMenu liegt
    # in einem PullDownMenu, dann wird ein PDM zurueck geschaltet
    # - alles klar ?
    #
    if ( $key eq KEY_LEFT and (not $this->{parent}->{parent}->{parent} or $this->{parent}->{parent}->{parent}->{type} ne 'pull_down_menu') ) {
        $this->next_active();
        $this->{parent}->{parent}->prev_active();
        $this->{parent}->{parent}->{active}->{opened}=1;
    }
    elsif ( $key eq KEY_RIGHT and (not $this->{parent}->{parent}->{parent} or $this->{parent}->{parent}->{parent}->{type} ne 'pull_down_menu') ) {
        $this->prev_active();
        $this->{parent}->{parent}->next_active();
        $this->{parent}->{parent}->{active}->{opened}=1;
    }
    else {
        $this->{parent}->{parent}->{active}->{opened}=0;
        $this->{parent}->{parent}->activate_group('_default');
        $this->{parent}->{parent}->{active}->{is_act}=1;
    }
    return;
}

sub add_menu_point {
    my $this     = shift;
    my $point    = shift;
    my $anz      = @{$this->{points}};
    my $widget   = 0;
    my $callback;

    if ( ref $point ) {
        $widget = $point;
        $callback = $widget->{callback};
        if ( $widget->{cols} > $this->{cols} ) {
            $this->{cols} = $widget->{cols};
            $this->{window}->{cols} = $this->{cols};
        }
        # PDM in PDM ?
        if ( $widget->{type} eq 'pull_down_menu' ) {
            $widget->{title} = $widget->{title} . ' -->';
            $widget->{window}->{ax} = $this->{window}->{cols}+3;
            $widget->{window}->{ay} = $this->{window}->{rows}+2+3;
        }
    }
    else {
        $callback=shift;
        if ( (length $point) > ($this->{window}->{cols}-2) ) {
            $this->{cols} = (length $point);
            $this->{window}->{cols} = $this->{cols}+2;
        }
        $widget=Paw::Button->new(name=>"auto_button_$point", text=>$point, callback=>$callback);
    }
    $this->{window}->{rows} = $this->{window}->{rows}+$widget->{rows};
    $this->{window}->put($widget);
    push @{$this->{points}}, $widget;
    push @{$this->{points}}, $callback;

    return;
}

sub draw {
    my $this    = shift;
    my $title   = $this->{title};

    if ( $this->{window}->{ax} == 0 ) {
        $this->{window}->{ax} = $this->{parent}->{ax}+$this->{wx}+1;
        $this->{window}->{ay} = $this->{parent}->{ay}+2;
    }
    attron(A_REVERSE) if ( $this->{is_act} );
    attron(COLOR_PAIR($this->{color_pair}));
    addstr($title);
}

sub key_press {
    my $this = shift;
    my $key  = shift;

    while ( $key eq ' ' or $key eq "\n" or $this->{parent}->{active}->{opened}) {
        $key = '';
        $this->{parent}->{active}->{window}->raise();
    }
    return $key;
}


return 1;
