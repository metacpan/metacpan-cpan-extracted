#!perl -T

#################################################################################################################################################################
#
#	TESTS for PARAMS::CLEAN
#
#################################################################################################################################################################

	use strict; use warnings;
	use lib "t"; use try;

#—————————————————————————————————————————————————————————————————————————————————————————————
		
BEGIN { use_ok "Params::Clean" }

	diag("Testing Params::Clean $Params::Clean::VERSION, Perl $], $^X");


try "Simplest names/posns",
	(call "begin", bond=>007, "middle", smart=>86, "end"),
	(get 0, -1, 3, 'smart', 'bond'),
	(expect qw/begin end middle 86 7/);

try "Simplest names/posns in different order",
	(call "begin", bond=>007, "middle", smart=>86, "end"),
	(get 6, 'smart', -4, 0, 'bond'),
	(expect qw/end 86 middle begin 7/);

try "NAMEd int params",
	(call 1=>'money', 2=>'show', 3=>'get_ready', "extra", Four=>'go', "leftovers"),
	(get NAME 1,2,3, 'Four', REST),
	(expect qw/money show get_ready go extra leftovers/);

try "Multiple matches return array-ref",
	(call darryl=>"brother", darryl=>"other_brother"),
	(get qw/Larry Darryl/),
	(expect undef, [qw/brother other_brother/]);

try "Flags",
	(call qw/black white red_all_over black jack black/),
	(get FLAG, qw/black white union jack/),
	(expect 3, 1, undef, 1);

try "Alternative param names",
	(call 'hey', color=>123, over=>'there', colour=>321),
	(get ['colour', 'color'], [-3, 0], REST),
	(expect [123, 321], [qw/hey there/], 'over');

try "Alternative param names in different order",	#order of alternatives doesn't matter
	(call 'hey', colour=>123, over=>'there', color=>321),
	(get ['colour', 'color'], [0, -3], REST),
	(expect [123, 321], [qw/hey there/], 'over');

	#—————————————————————————————————————————————————————————————————————————————————————

	sub Odd { $_=shift; return $_ && /\d+/ && $_%2 }		# check looks like an int and isn't even
try "TYPE grabbing (Odd function)",
	(call 1,2,3,4,5,6,7,11,13,19,1024),
	(get TYPE \&Odd, REST),
	(expect [1,3,5,7,11,13,19], 2,4,6,1024);

try "TYPE grabbing (Scalar/array/hash refs)",
	(call [1,2,3], {4=>5}, {6=>7}, \"foo", ["loner"]),
	(get TYPE "SCALAR", TYPE "ARRAY", TYPE "HASH"),
	(expect \"foo", [[1, 2, 3], ["loner"]], [{4=>5}, {6=>7}]);

try "TYPE grabbing (file globs)",
	(call this=>"that", these=>"those", 90210, \*STDIN),
	(get [qw/this these/], TYPE "GLOB", -2),
	(expect [qw/that those/], \*STDIN, 90210);

SKIP: {
		eval "use FileHandle";
		skip "FileHandle test (no FileHandle module to load!)" if $@;
		
		my $F=new FileHandle; my $H=new FileHandle;
		try "TYPE grabbing (file objects)",
			(call 1,2,3, $F, this=>"that", $H),
			(get TYPE "FileHandle", "this", REST),
			(expect [$F, $H], "that",  1, 2, 3);
	}

try "TYPE grabbing [single array-ref element]",
	(call [42]),
	(get TYPE "ARRAY"),
	(expect [42]);

	#—————————————————————————————————————————————————————————————————————————————————————

try "Lists (combo)",
	(call SELECT=> 1, 2, 3, FROM=> 4, 5, 6, WHERE=> 7,8,9),
	(get LIST "WHERE", LIST "FROM", LIST "SELECT"),
	(expect ["WHERE", 7,8,9], ["FROM", 4,5,6], ["SELECT", 1,2,3]);

diag "Spits out a couple of expected errors...";
try "Lists (notWIM)",
	(call SELECT=> 1, 2, 3, FROM=> 4, 5, 6, WHERE=> 7,8,9),
	(get LIST "SELECT", LIST "FROM", LIST "WHERE"),	# won't quite do what you might expect because SELECT will slurp everything first!
	(expect ["SELECT", 1,2,3, "FROM", 4,5,6, "WHERE", 7,8,9], undef, undef);

try "Lists (combo endings)",
	(call SELECT=> 1, 2, 3, FROM=> 4, 5, 6, WHERE=> 7,8,9),
	(get LIST "SELECT"<="FROM", LIST "FROM"<="WHERE", LIST "WHERE"<=>-1),
	(expect ["SELECT", 1,2,3], ["FROM", 4,5,6], ["WHERE", 7,8,9]);

try "Lists (hard breaks)",
	(call SELECT=> 1, 2, 3, "STOP", FROM=> 4, 5, 6, "STOP", WHERE=> 7,8,9),
	(get TYPE sub {$_[0]eq "STOP"}, LIST "SELECT", LIST "FROM", LIST "WHERE"),
	(expect [qw/STOP STOP/], ["SELECT", 1,2,3], ["FROM", 4,5,6], ["WHERE", 7,8,9]);

try "Lists (positional)",
	(call SELECT=> 1, 2, 3, FROM=>"foobar", WHERE=> 7,8,9),
	(get LIST 0 = [1..3], LIST "FROM" ^ 1, LIST 7<=>-1),
	(expect [1,2,3], ["foobar"], [7,8,9]);

	#—————————————————————————————————————————————————————————————————————————————————————

try "Used args",
	(call cheddar=>1, brie=>2, camenbert=>3, limburger=>4),
	(get "cheddar", [qw/cheddar limburger brie camenbert/], "limburger"),
	(expect 1, [2,3,4], undef);

try "Used args (flag-name) I",
	(call cheddar=>"cheese"),
	(get FLAG "cheddar", NAME "cheddar", REST),
	(expect 1, undef, "cheese");

try "Used args (name-flag) I",
	(call cheddar=>"cheese"),
	(get NAME "cheddar", FLAG "cheddar", REST),
	(expect "cheese", undef);

try "Used args (flag-name) II",
	(call cheddar=>"cheese"),
	(get FLAG "cheese", NAME "cheddar", REST),
	(expect 1, "cheese");

try "Used args (name-flag) II",
	(call cheddar=>"cheese"),
	(get NAME "cheddar", FLAG "cheese", REST),
	(expect "cheese", undef);

	#—————————————————————————————————————————————————————————————————————————————————————



#—————————————————————————————————————————————————————————————————————————————————————————————

__END__

try "",
	(call ),
	(get ),
	(expect qw//);


#—————————————————————————————————————————————————————————————————————————————————————————————
