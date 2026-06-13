use warnings;
use strict;

use LWP::Simple;
use RPi::WiringPi;
use RPi::Const qw(:all);

# catch a sigint. This allows us to
# perform an emergency pin reset

my $continue = 1;
$SIG{INT} = sub { $continue = 0; };

# initialize using the BCM GPIO pin
# numbering scheme

my $pi = RPi::WiringPi->new();#setup => 'gpio');

# this is the button pin that when an edge-change
# (interrupt) happens, we switch from XP to remaining
# XP

my $button = 24;

# prepare and initialize the LCD

my $lcd = $pi->lcd;

my %args = (
    cols => 16,
    rows => 2,
    bits => 4,
    rs => 5,
    strb => 6,
    d0 => 4,
    d1 => 17,
    d2 => 27,
    d3 => 22,
    d4 => 0,
    d5 => 0, 
    d6 => 0, 
    d7 => 0,
);

$lcd->init(%args);

# set up a pin with a button, and set an
# interrupt handler to do something when
# the button is pressed

my $button_pin = $pi->pin($button);

# we're going to interrupt when the pin
# goes LOW (off), so we'll pull it HIGH
# with the built-in pull up resistor.

# Only when the button is pressed, will the
# pin briefly go LOW, and this triggers
# an interrupt

$button_pin->pull(PUD_UP);

# the second arg to interrupt_set() is the
# name of the perl sub I've defined below
# that I want handling the interrupt

$button_pin->interrupt_set(
    EDGE_FALLING, 
    'button_press'
);

# unfortunately, at this time, the core C
# interrupt handler doesn't accept params, so
# I've got no choice but to use globals for now

my $button_presses = 0;
my ($posts, $xp, $next);

while ($continue){
    my (
        $sec,$min,$hour,$mday,$mon,
        $year,$wday,$yday,$isdst
    ) = localtime();

    $min = "0$min" if length $min == 1;

    # get my post and xp count from PM
    
    ($posts, $xp) = perlmonks();

    # manually get xp needed for next level

    $next = 16000 - $xp;
    
    # set the LCD cursor to top row, first
    # column, and print my num of PM posts

    $lcd->position(0, 0);
    $lcd->print("p: $posts"); 
   
    # sub for bottom line, because the
    # code needs to be called also in our
    # interrupt handler. What's printed depends
    # on the cumulative number of button presses

    display_xp();

    # on top row of the LCD at column 12,
    # we print the time

    $lcd->position(11, 0);
    $lcd->print("$hour:$min");

    print "$hour:$min posts: $posts, " .
          "xp: $xp, next lvl: $next\n";

    # rinse, repeat every minute

    sleep 60;
}

# wipe the LCD clean

$lcd->clear;

# reset pins to default state

$pi->cleanup;

sub button_press {
    # this is the interrupt handler

    print "button pressed\n";
    $button_presses++;
    display_xp();
}
sub display_xp {
    # this is the manager for the bottom LCD
    # row

    # print XP for 1 and odd number of button
    # presses, and print XP remaining to next level
    # on 0 and even number of presses

    $lcd->position(0, 1);
    if ($button_presses % 2){
        $lcd->print("x: $xp     ");
    }
    else {
        $lcd->print("r: $next      ");
    }
}
sub perlmonks {
    my $url = "http://perlmonks.org/?node_id=789891";
    my $page = get $url;
    my @content = split /\n/, $page;

    my ($xp, $posts);
    my $i = 0;

    for (@content){
        if (/Experience:/){
            my $line = $i;
            $line += 2;
            $xp = $1 if $content[$line] =~ /(\d+)/;
        }
        if (/Writeups:/){
            my $line = $i;
            $line += 2;
            $posts = $1 if $content[$line] =~ />(\d+)/;
        }
        $i++;
    }
    return ($posts, $xp);
}
