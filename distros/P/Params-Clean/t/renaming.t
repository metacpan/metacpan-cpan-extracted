#!perl -T

#################################################################################################################################################################
#
#	RENAMING TESTS for PARAMS::CLEAN
#
#################################################################################################################################################################

	use strict; use warnings;
	use lib "t"; use try;

#—————————————————————————————————————————————————————————————————————————————————————————————

	use Params::Clean PARSE=>"USE", POSN=>"Pos", NAME=>"Named", FLAG=>"Flag", LIST=>"Plist", REST=>"OTHERS", TYPE=>"Kind";

try "POSN as Pos, NAME as Named",
	(call "begin", bond=>007, "middle", smart=>86, "end"),
	(get Pos 0, -1, 3, Named 'smart', 'bond'),
	(expect qw/begin end middle 86 7/);

try "NAME as Named, REST as OTHERS",
	(call 1=>'money', 2=>'show', 3=>'get_ready', "extra", Four=>'go', "leftovers"),
	(get Named 1,2,3, 'Four', OTHERS),
	(expect qw/money show get_ready go extra leftovers/);

try "FLAG as Flag, PARSE as Use",
	(call qw/unused data/),
	(get USE [qw/black white red_all_over black jack black/], Flag, qw/black white union jack/),
	(expect 3, 1, undef, 1);

try "TYPE as Kind",
	(call [1,2,3], {4=>5}, {6=>7}, \"foo", ["loner"]),
	(get Kind "SCALAR", Kind "ARRAY", Kind "HASH"),
	(expect \"foo", [[1, 2, 3], ["loner"]], [{4=>5}, {6=>7}]);

try "LIST as PLIST",
	(call SELECT=> 1, 2, 3, FROM=> 4, 5, 6, WHERE=> 7,8,9),
	(get Plist "WHERE", Plist "FROM", Plist "SELECT"),
	(expect ["WHERE", 7,8,9], ["FROM", 4,5,6], ["SELECT", 1,2,3]);



#—————————————————————————————————————————————————————————————————————————————————————————————

# try "",
# 	(call ),
# 	(get ),
# 	(expect qw//);

#—————————————————————————————————————————————————————————————————————————————————————————————
