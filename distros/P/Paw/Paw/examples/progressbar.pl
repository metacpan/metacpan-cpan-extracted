#!/usr/bin/perl -w
#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
#
# see also perldoc Paw::Progressbar


use Paw; 
use Curses;
use Paw::Window;
use Paw::Label;
use Paw::Progressbar;

##################################################
# Paw stuff ( 2 Labels, 2 Progressbar )
##################################################
($columns, $rows)=Paw::init_widgetset;
init_pair(2, COLOR_CYAN, COLOR_BLACK);
$win=Paw::Window->new(height=>$rows, width=>$columns,
		      quit_key=>KEY_F(10), time_function=>\&tf);

$value = -20;
$label = new Paw::Label( text => 'Stupid Value (color): ' );
$stupid = new Paw::Progressbar( 
			       from=>-20, to=>20, 
			       blocks=>20, variable => \$value,
			       color => 2
			      );
$win->put($label);
$win->put($stupid);

$value2 = getdf('/');
$label2 = new Paw::Label( text => 'Space on partition / (mono) : ' );
$free = new Paw::Progressbar( 
			     variable => \$value2
			    );
$win->put($label2);
$win->put($free);

$win->raise();

##################################################
# Timefunktion for the main Window
##################################################
sub tf {
    $value = -20 if $value++ == 20;
    $value2 = getdf('/');
    
}

##################################################
# space for partition $part
##################################################
sub getdf {
    my $part = shift;
    my $percentage;

    open PIPE, "/bin/df -k $part |" or 
         quit("Cannot run /bin/df");
    while(<PIPE>) {
         ($percentage) = /(\d+)%/;
    }
    close PIPE or quit("/bin/df failed");
    $percentage;
}
