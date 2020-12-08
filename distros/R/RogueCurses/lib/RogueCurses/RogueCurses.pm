################
# main program #
################


### BEGIN { $Curses::OldCurses = 1; }
use Curses;

use lib '.';
use lib './lib';
use RogueCurses::screen;
use RogueCurses::interface;

my $screen = RogueCurses::screen->new(); ### (20,10)
my $interface = RogueCurses::interface->new();

while (1) {

	$screen->blit_char_in_window(2,2,'@');

	$screen->update_window;

	sleep(1);

	my ($chr, $key) = $interface->get_char_and_key;
###	if ($key == 'q') { last; };

###	$screen->update;

};

$screen->close;
