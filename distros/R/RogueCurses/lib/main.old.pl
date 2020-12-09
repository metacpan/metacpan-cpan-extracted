### BEGIN { $Curses::OldCurses = 1; }

use Curses;

$win = initscr;

my $i = 0;

while ($i++ > 10) {
	addch($i,$i,'@');
$win->refresh;
	
};

while (1) {};

endwin;
