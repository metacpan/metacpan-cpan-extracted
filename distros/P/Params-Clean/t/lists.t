#!perl -T

#################################################################################################################################################################
#
#	TESTS for LISTs
#
#################################################################################################################################################################

	use strict; use warnings;
	use lib "t"; use try;
	use Params::Clean;

#—————————————————————————————————————————————————————————————————————————————————————————————
		
sub Odd { $_=shift; return $_ && /\d+/ && $_%2 }		# check looks like an int and isn't even


try "List (open-ended)",
	(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, qw/Mary had a little lamb/, colour=>'blue', colour=>'red'),
	(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary", [2,1,0], REST),
	(expect [qw/black blue red/], [255, 1, 3], [qw/Mary had a little lamb/], [240,128], "DUMMY", 2);

try "List including end point",
	(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, qw/Mary had a little lamb/, colour=>'blue', colour=>'red'),
	(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary"<=>"lamb", [2,1,0], REST),
	(expect [qw/black blue red/], [255, 1, 3], [qw/Mary had a little lamb/], [240,128], "DUMMY", 2);

try "List excluding end point",
	(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, qw/Mary had a little lamb/, colour=>'blue', colour=>'red'),
	(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary"<="lamb", [2,1,0], REST),
	(expect [qw/black blue red/], [255, 1, 3], [qw/Mary had a little/], [240,128], "DUMMY", 2, "lamb");

try "List with relative posns",
	(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, qw/Mary had a little lamb/, colour=>'blue', colour=>'red'),
	(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary" = [1..4], [2,1,0], REST),
	(expect [qw/black blue red/], [255, 1, 3], [qw/had a little lamb/], [240,128], "DUMMY", 2);

try "List including relative posns",
	(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, qw/Mary had a little lamb/, colour=>'blue', colour=>'red'),
	(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary" & [1..4], [2,1,0], REST),
	(expect [qw/black blue red/], [255, 1, 3], [qw/Mary had a little lamb/], [240,128], "DUMMY", 2);

try "List excluding relative posns",
	(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, qw/Mary had a little lamb/, colour=>'blue', colour=>'red'),
	(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary" ^ [1..4], [2,1,0], REST),
	(expect [qw/black blue red/], [255, 1, 3], [qw/had a little lamb/], [240,128], "DUMMY", 2);

try "List with relative posns (0)",
	(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, qw/Mary Mary quite contrary/, colour=>'blue', colour=>'red'),
	(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary" = [0..3], [2,1,0], REST),
	(expect [qw/black blue red/], [255, 1, 3], [qw/Mary Mary quite contrary/], [240,128], "DUMMY", 2);

try "List including relative posns (negative)",
	(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, qw/Mary Mary quite contrary/, colour=>'blue', colour=>'red'),
	(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary" & [-3..3], [2,1,0], REST),
	(expect [qw/black blue red/], [255, 1, 3], [qw/3 2 1 Mary Mary quite contrary/], [240,128], "DUMMY");

try "List excluding relative posns (0)",
	(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, qw/Mary Mary quite contrary/, colour=>'blue', colour=>'red'),
	(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary" ^ [0..3], [2,1,0], REST),
	(expect [qw/black blue red/], [255, 1, 3], [qw/Mary quite contrary/], [240,128], "DUMMY", 2);

try "List single relative posns (positive)",
	(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, qw/Mary Mary quite contrary/, colour=>'blue', colour=>'red'),
	(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary" = 2, [2,1,0], REST),
	(expect [qw/black blue red/], [255, 1, 3], ["quite"], [240,128], "DUMMY", 2, qw/Mary contrary/);

try "List single relative posns (negative)",
	(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, qw/Mary Mary quite contrary/, colour=>'blue', colour=>'red'),
	(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary" = -2, [2,1,0], REST),
	(expect [qw/black blue red/], [255, 1, 3], [2], [240,128], "DUMMY", qw/Mary quite contrary/);

try "List single+inclusive relative posns",
	(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, qw/Mary had a little lamb/, colour=>'blue', colour=>'red'),
	(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary" & 4, [2,1,0], REST),
	(expect [qw/black blue red/], [255, 1, 3], [qw/Mary lamb/], [240,128], "DUMMY", 2, qw/had a little/);

	#—————————————————————————————————————————————————————————————————————————————————————

my %Mary = (I=>[qw/Mary had a little lamb/], II=>[qw/Mary Mary quite contrary/]);
for (keys %Mary)
{
	try "List including alternative end points $_",
		(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, @{$Mary{$_}}, colour=>'blue', colour=>'red'),
		(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary"<=>["lamb","contrary"], [2,1,0], REST),
		(expect [qw/black blue red/], [255, 1, 3], $Mary{$_}, [240,128], "DUMMY", 2);

	try "List excluding alternative end points $_",
		(call 240, 128, 255, color=>'black', "DUMMY", 1,2,3, @{$Mary{$_}}, colour=>'blue', colour=>'red'),
		(get [NAME "Colour", "Color"], TYPE \&Odd, LIST "Mary"<=["lamb","contrary"], [2,1,0], REST),
		(expect [qw/black blue red/], [255, 1, 3], [@{$Mary{$_}}[0..@{$Mary{$_}}-2]], [240,128], "DUMMY", 2, ${$Mary{$_}}[-1]);
}

	#—————————————————————————————————————————————————————————————————————————————————————


#—————————————————————————————————————————————————————————————————————————————————————————————
