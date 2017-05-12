#!/usr/local/bin/perl

use lib 'blib/lib';

use ProLite qw(:core :commands :colors :styles :dingbats :effects);

my $s = new ProLite(id=>1, device=>'/dev/ttyS0', debug=>0, charDelay=>2000);

$| = 1;
print "Sending data...";

$err = $s->connect();
die "Can't connect to device - $err" if $err;

$s->wakeUp();
$s->setClock();

print ".";
$s->setPage(26, "            ...Loading...");
$s->runPage(26);

$s->setPage(25, RESET, dimRed, stackingL, "Ready.", chain(24));
$s->setPage(24, red,		appearL, "Ready.", chain(23));
$s->setPage(23, brightRed,	appearL, "Ready.", chain(24));


print ".";
$s->setPage(1, RESET, dimRed, blank, "The ",
	red, "current ",
	yellow, "date is", blank,
	"<FD><FT>",
	chain(25)
);


print ".";
$s->setPage(2, RESET,
	dimRed, "dimRed ",
	red, "red ",
	brightRed, "brightRed ",
	orange, "orange ",
	brightOrange, "brightOrange ",
	dimYellow, "dimYellow ",
	yellow, "yellow ", 
	brightYellow, "brightYellow ",
	dimLime, "dimLime ",
	lime, "lime ",
	brightLime, "brightLime ",
	brightGreen, "brightGreen ",
	green, "green ",
	dimGreen, "dimGreen ",
	rainbow, "rainbow ",
	
	blank,
	
	yellowSRedOnGreen, "yellowSRedOnGreen ",
	redSGreen, "redSGreen ",
	redSYellow, "redSYellow ",
	greenSRed, "greenSRed ",
	greenSYellow, "greenSYellow ", 
	greenOnRed, "greenOnRed ",
	redOnGreen, "redOnGreen ",
	orangeSBlackOnGreen, "orangeSBlackOnGreen ",
	limeSBlackOnRed, "limeSBlackOnRed ",
	greenSBlackOnRed, "greenSBlackOnRed ", 
	redSBlackOnGreen, "redSBlackOnGreen ", 

	chain(25)
);

print ".";
$s->setPage(3, RESET, red,
	normal, uncondensed, "normal ",
	condensed, "condensed ",
	bold, uncondensed, "bold ",
	bold, condensed, "bold-condensed  ",
	italic, uncondensed, "italic ",
	italic, condensed, "italic-condensed  ",
	boldItalic, uncondensed, "boldItalic  ",
	boldItalic, condensed, "boldItalic-condensed  ",
	normalFlash, "normalFlash ",
	boldFlash, "boldFlash ",
	italicFlash, "italicFlash ",
	boldItFlash, "boldItFlash ",
	chain(25)
);

print ".";
$s->setPage(4, RESET,
	"telephone ", telephone, " ",
	"glasses ", glasses, " ",
	"rocket ", rocket, " ",
	"monster ", monster, " ",
	"key ", key, " ",
	"shirt ", shirt, " ",
	"helicopter ", helicopter, " ",
	"car ", car, " ",
	"tank ", tank, " ",
	"house ", house, " ",
	"teaPot ", teaPot, " ",
	"knifeFork ", knifeFork, " ",
	"duck ", duck, " ",
	"motorcycle ", motorcycle, " ",
	"bicycle ", bicycle, " ",
	"crown ", crown, " ",
	"twinHearts ", twinHearts, " ",
	"arrowR ", arrowR, " ",
	"arrowL ", arrowL, " ",
	"arrowDL ", arrowDL, " ",
	"arrowUL ", arrowUL, " ",
	"beerGlass ", beerGlass, " ",
	"chair ", chair, " ",
	"shoe ", shoe, " ",
	"wineGlass ", wineGlass, " ",
	chain(25)
);

# 	autoL openOutL coverOutL date cyclingL closeRT closeLT closeInT scrollUpL
# 	scrollDownL overlapL stackingL comic1L comic2L beep pauseT appearL randomL
# 	shiftLeftL currentTime magicL thankyou welcome linkPage target current
# 	dayLeft hourLeft minLeft secLeft

print ".";
$s->setPage(5, RESET,
	openOutL, "Open-Out",
	coverOutL, "Cover-Out",
	cyclingL, "Cycling",
	"                 ",
	"Close-Right", closeRT, 
	"Close-Left", closeLT, 
	"Close-In", closeInT, 
	scrollUpL, "Scroll-Up",
	scrollDownL, "Scroll-Down",
	overlapL, "Overlap",
	stackingL, "Stacking", 
	comic1L, "Comic 1",
	comic2L, "Comic 2",
#	beep, "Beep",
	"Pause", pauseT, 
	appearL, "Appear",
	randomL, "Random",
	shiftLeftL, "Shift Left",
	currentTime, 
	magicL, "Magic",
	thankyou,
	welcome,
	target,
	current,
	dayLeft,
	hourLeft,
	minLeft,
	secLeft,	
	chain(25)
);

print ".";
$s->runPage(25);
$s->setPage(26, appearL, "Goodbye");


print "
Select:
  (1) Date and Time
  (2) Colors
  (3) Fonts
  (4) Graphic Symbols
  (5) Transition Effects
  (q) Quit.
";

print "-> ";
while($entry = <STDIN>)
{
	chomp $entry;
	
	$s->runPage(1) if $entry eq '1';
	$s->runPage(2) if $entry eq '2';
	$s->runPage(3) if $entry eq '3';
	$s->runPage(4) if $entry eq '4';
	$s->runPage(5) if $entry eq '5';
	$s->runPage(26) if $entry eq 'q';
	exit 0 if $entry =~ /^q/i;
	
	print "-> ";
}

sleep 1;

