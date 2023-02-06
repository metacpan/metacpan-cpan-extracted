use strict;
use warnings;
use PDL;
use strict;
use warnings;
use PDL::Graphics::Prima::Simple;

use PDL::Constants qw(PI);
# Prepare some goofy data
my $x = sequence(100)/100*24;
my $y = sin($x*PI/12);
use PDL::NiceSlice;
$y(0:24) .= sin($x(0:24)*PI/12)**7;
$y(75:99) .= sin($x(75:99)*PI/12)**7;

# Plot it with a goofy title, and use formatting for the tick marks
plot(
	-data => ds::Pair($x, $y),
	title => 'Need for Coffee',
	x => {
		format_tick => sub {
			my $time_of_day = shift;
			my $hour = $time_of_day % 12;
			my $ampm = ($time_of_day % 24 > 12) ? 'PM' : 'AM';
			return "$hour $ampm";
		},
	},
	onKeyUp => sub {
		print "You pressed a key!\n";
		print "Got args [", join('], [', @_), "]\n";
	},
);
