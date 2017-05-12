#!/usr/bin/perl -w

use strict;

use Paw;    # needed for widgets
use Curses;      # needed for getch() and more
use Paw::Window;
use Paw::Popup_menu;
use Paw::Listbox;
use Paw::Label;

#
# init - as always
#
my ($columns, $rows)=Paw::init_widgetset;
my $choice = [ "one", "two", "three" ,"four", "five", "six", "seven", "and a long one"];
init_pair(2, COLOR_BLACK, COLOR_BLUE);

#
# pick the value with $pop->get_choice()
#
my $pop = new Paw::Popup_menu( data=>$choice, size=>4, 
                               width=>12, shade=>1, callback=>\&cb );
my $text = $pop->get_choice();
my $label = new Paw::Label( text => "you choose : $text" );

my $win=Paw::Window->new(quit_key=>KEY_F(10), height=>$rows, width=>$columns, 
			 orientation=>"grow" );

$win->abs_move_curs(new_x=>5,new_y=>5);
$win->put($pop);
$pop->set_choice(6);
$win->put($label);

# generate a listbox with border - self explaining.

$win->raise();

sub cb {
    $text = $pop->get_choice();
    $label->set_text("you choose : $text");
}
#
#
#
