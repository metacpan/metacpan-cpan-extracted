package DigitalClock;
use strict;
use Qt;
use Qt::isa qw(Qt::LCDNumber);
use Qt::slots
	stopDate => [],
	showTime => [];
use Qt::attributes qw(
	showingColon
	normalTimer
	showDateTimer
);

#
# Constructs a DigitalClock widget
#

sub NEW {
    shift->SUPER::NEW(@_);
    showingColon = 0;
    setFrameStyle(&Panel | &Raised);
    setLineWidth(2);
    showTime();
    normalTimer = startTimer(500);
    showDateTimer = -1;
}

#
# Handles timer events and the digital clock widget.
# There are two different timers; one timer for updating the clock
# and another one for switching back from date mode to time mode
#

sub timerEvent {
    my $e = shift;
    if($e->timerId == showDateTimer) {		# stop showing date
	stopDate();
    } elsif(showDateTimer == -1) {		# normal timer
	showTime();
    }
}

#
# Enters date mode when the left mouse button is pressed
#

sub mousePressEvent {
    my $e = shift;
    showDate() if $e->button == &LeftButton;
}

#
# Shows the durrent date in the internal lcd widget.
# Fires a timer to stop showing the date.
#

sub showDate {
    return if showDateTimer != -1;		# already showing date
    my $date = Qt::Date::currentDate();
    my $s = sprintf("%2d %2d", $date->month, $date->day);
    display($s);				# sets the LCD number/text
    showDateTimer = startTimer(2000);		# keep this state for 2 secs
}

#
# Stops showing the date.
#

sub stopDate {
    killTimer(showDateTimer);
    showDateTimer = -1;
    showTime();
}

#
# Shows the current time in the internal lcd widget.
#

sub showTime {
    showingColon = !showingColon;
    my $s = substr(Qt::Time::currentTime()->toString, 0, 5);
    $s =~ s/^0/ /;
    $s =~ s/:/ / unless showingColon;
    display($s);
}

1;

