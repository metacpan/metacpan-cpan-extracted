#!perl -T

#################################################################################################################################################################
#
#	PARSING ARBITRARY ARRAYS: TESTS for PARAMS::CLEAN
#
#################################################################################################################################################################

	use strict; use warnings;
	use lib "t"; use try;
	use Params::Clean;

#—————————————————————————————————————————————————————————————————————————————————————————————


sub parser { my @args = args PARSE \@_, POSN 0, -1, 3, NAME 'smart', 'bond';
			 is_deeply \@args, [qw/begin end middle 86 7/], 'PARSE \@_'; }
	parser("begin", bond=>007, "middle", smart=>86, "end");


my @args=(1=>'money', 2=>'show', 3=>'get_ready', "extra", Four=>'go', "leftovers");
try "PARSE \@",
	(call),
	(get PARSE \@args, NAME 1,2,3, 'Four', REST),
	(expect qw/money show get_ready go extra leftovers/);

try "PARSE {}",
	(call "nothing"),
	(get PARSE {qw/black white red_all_over black jack black/}, FLAG qw/black white union jack/),
	(expect 3, 1, undef, 1);

try "PARSE []",
	(call),
	(get PARSE [SELECT=> 1, 2, 3, FROM=> 4, 5, 6, WHERE=> 7,8,9 ], LIST "WHERE", LIST "FROM", LIST "SELECT"),
	(expect ["WHERE", 7,8,9], ["FROM", 4,5,6], ["SELECT", 1,2,3]);

sub return_args { return [1,2,3], {4=>5}, {6=>7}, \"foo", ["loner"] }
try 'PARSE &',
	(call "xxx"),
	(get PARSE \&return_args, TYPE "SCALAR", TYPE "ARRAY", TYPE "HASH"),
	(expect \"foo", [[1, 2, 3], ["loner"]], [{4=>5}, {6=>7}]);


#—————————————————————————————————————————————————————————————————————————————————————————————

# try "",
# 	(call ),
# 	(get ),
# 	(expect qw//);

#—————————————————————————————————————————————————————————————————————————————————————————————
