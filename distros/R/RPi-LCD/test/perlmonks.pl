use warnings;
use strict;

use LWP::Simple;
use RPi::LCD;
use RPi::WiringPi::Constant qw(:all);

# catch a sigint. This allows us to
# perform an emergency pin reset

my $continue = 1;
$SIG{INT} = sub { $continue = 0; };

# prepare and initialize the LCD

my $lcd = RPi::LCD->new;

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

sub display_xp {
    # this is the manager for the bottom LCD
    # row

    $lcd->position(0, 1);
    $lcd->print("r: $next      ");
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
