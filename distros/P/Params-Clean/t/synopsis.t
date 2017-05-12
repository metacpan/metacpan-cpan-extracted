#!perl -T

#################################################################################################################################################################
#
#	Test examples given in the synopsis
#
#################################################################################################################################################################

	use lib "t"; use try;
	use Params::Clean;
	no warnings;

#—————————————————————————————————————————————————————————————————————————————————————————————
	
try "Get positional args, named args, and flags",
	 (call qw/ $x, $y, $z,    FU $blue, MAN $man, CHU $group,  PENNANT BANNER /),
	      (get POSN 0, 1, 2,  NAME fu, man, chu,               FLAG pennant,  banner),
	expect qw( $x, $y, $z,    $blue, $man, $group,             1 1 );


try "Any of the three types of argument is optional",
	 (call qw/ TOM $tom, RANDAL $dick, LARRY $harry /),
	      (get NAME tom, randal, larry ),
	expect qw( $tom, $dick, $harry );


try "...or repeatable -- order doesn't matter",
	 (call qw/ posn0 PEARL $p5,   WHITE $s,   RUBY @others /),
	      (get       NAME  pearl, FLAG white, NAME ruby,  POSN 0 ),
	expect qw(       $p5,         1           @others     posn0);


try "If no types specified, ints are taken to mean positional args, text as named",
	 (call qw/ $fee, JACK $fo, $fum /),
	      (get 0,              -1,   jack ),
	expect qw( $fee,           $fum  $fo, );


try "Can also retrieve any args left over after pulling out NAMES/FLAGS/POSNS",
	 (call qw/ FIRST_MATE $gilligan,  SKIPPER $skipper,  GENIUS $prof,  MILLIONAIRE $thurston,  WIFE $lovey, $mary_ann  STAR $ginger, /),
	      (get first_mate, skipper,  millionaire, wife,    star,     REST ),
	expect qw( $gilligan,  $skipper,  $thurston,  $lovey,  $ginger,  GENIUS $prof, $mary_ann );


	my $objects=bless {}, "Class::Name";		#fake class
try "Or collect args that qualify as matching a certain type",
	 (call $objects, qw/ @rest /),
	      (get TYPE "Class::Name", REST ),
	expect $objects, qw( @rest );


	my $files="fake filehandle";
	sub is_filehandle { $_=shift; return /filehandle/i };
try "*2 collect args that qualify as matching a certain type",
	 (call qw/ @rest /, $files),
	      (get TYPE \&is_filehandle, REST ),
	expect $files, qw( @rest );


try "Specify a LIST by giving starting and (optional) ending points",
	 (call qw/ SELECT $query, FROM $tables, WHERE $condition xxx /),
	      (get LIST Select<=From, LIST From<=Where, LIST Where<=>-1 ),
	expect [qw( SELECT $query, )], [qw( FROM $tables, )], [qw( WHERE $condition xxx )];


try "Or by giving a list of positions relative to the LIST's starting point",
	 (call qw/ $blackspy, VS $whitespy /),
	      (get LIST vs = [-1, 1] ),
	expect [qw( $blackspy, $whitespy )];


try "*2 by giving a list of positions relative to the LIST's starting point",
	 (call qw/ $blackspy, VS $whitespy /),
	      (get LIST vs & [-1, 1] ),
	expect [qw( $blackspy, VS $whitespy )];


try "*3 by giving a list of positions relative to the LIST's starting point",
	 (call qw/ $blackspy, VS $whitespy /),
	      (get LIST vs ^ [-1, 1] ),
	expect [qw( $blackspy, $whitespy )];


try "Specify synonymous alternatives using brackets",
	 (call qw/ $either_end, COLOR $tint COLOUR hue OTHER_END /),
	      (get [0, -1], [Colour, Color] ),
	expect [qw( $either_end, OTHER_END )], [qw( $tint hue )];
