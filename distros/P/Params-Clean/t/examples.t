#!perl -T

#################################################################################################################################################################
#
#	Test the examples given in the docs
#
#################################################################################################################################################################

		use Params::Clean;
		use Test::More 'no_plan';
		no warnings;

#—————————————————————————————————————————————————————————————————————————————————————————————
		
#head1 DESCRIPTION
#head2 Basics

	marine("begin", bond=>007, "middle", smart=>86, "end");
	sub marine
	{
		my ($first, $last, $between, $maxwell, $james)=args 0,-1, 3, 'smart','bond';
		#==>"begin"  "end"  "middle"    86       007
		is_deeply [$first, $last, $between, $maxwell, $james], ["begin",  "end",  "middle",    86,       007];
		
		my ($last, $max, $between, $first, $jim) = args(6, 'smart', -4, 0, 'bond');
		#same thing in a different order
		is_deeply [$last, $max, $between, $first, $jim], ["end", 86,  "middle",  "begin",   007];
	}


	my ($brother, $other_brother)=qw/VOLDSTAD PAPENFUSS/;
	human(darryl=>$brother, darryl=>$other_brother);
	sub human
	{
		my ($larry, $darryls) = args Larry, Darryl;
		#==> undef  [$brother, $other_brother]
		is_deeply [$larry, $darryls], [ undef,  [$brother, $other_brother]];
	}


#head2 POSN/NAME/FLAG identifiers

	tract(1=>money, 2=>show, 3=>'get ready', Four, go);
	sub tract
	{
		my ($one,  $two,  $three,  $four) = args NAME 1, 2, 3, four;
		#==> money  show  get ready go
		is_deeply [$one,  $two,  $three,  $four], [ money,  show,  "get ready", go];
		
		#Without the NAMES identifier, the 1/2/3 would be interpreted as positions:
		# $two would end up as "2" (the third element of @_), $three as "show", etc.
	}


	scribe(black, white, red_all_over, black, jack, black);
	sub scribe
	{
		my ($raid, $surrender, $rule, $britannia)
		                                    = args FLAG qw/black white union jack/;
		#==>  3        1        undef      1
		is_deeply [$raid, $surrender, $rule, $britannia], [  3,        1,        undef,      1];
	}


#head2 Alternative parameter names

	text(hey=>there, colour=>123, over=>here, color=>321);
	sub text
	{
		my    ($horses,    $hues,           $others)
		 =args [hey, hay],  [colour, color],  [4, 5];
		  #===> there        [123, 321]        [over, here]
		is_deeply [$horses,    $hues,           $others], [ there,        [123, 321],        [over, here]];
	}


	lime(alpha, Jack=>"B. Nimble", verbosity, verbosity);
	sub lime
	{
		my    ($start,         $verb,     $water_bearer,     $pomp) 
		 =args [0, FIRST], FLAG verbosity, [NAME Jack, Jill], pomposity;
		  #===> alpha             2          B. Nimble
		is_deeply [$start,         $verb,     $water_bearer,     $pomp], [ alpha, 2, "B. Nimble", undef];
	}



#head2 The REST

	our $I=bless [], "foo";
	$I->conscious(earth, sky, plants, sun, fish, animals, holiday);
	
	package foo;
		use Params::Clean;
	sub conscious
	{
		($self, @days[1..6], @sabbath) = args 0, 1..6, REST;
		#===>
		main::is_deeply [$self, @days[1..6], @sabbath], [$main::I, earth, sky, plants, sun, fish, animals, holiday];
	}
package main;



#head2 Identifying args by type

	#Assume we have created some filehandle objects with a module like IO::All
	my $LOGFILE=bless [], "IO::All";
	my $INPUT = my $OUTPUT = $LOGFILE;
	version($INPUT, $OUTPUT, some, random, stuff, $LOGFILE);
	sub version
	{
		my ($files, @leftovers) = args TYPE "IO::All", REST;
		#===> [$INPUT, $OUTPUT, $LOGFILE], some, random, stuff
		is_deeply [$files, @leftovers], [ [$INPUT, $OUTPUT, $LOGFILE], some, random, stuff];
	}


	stance(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, oops, 13, 2048);
		sub Even { $_=shift; return $_ && /^\d+$/ && $_%2==0 }  
		# check looks like an int and is even
	sub stance
	{
		my ($odds, $evens, @others) 
		  = args TYPE sub {shift()%2}, TYPE \&Even, REST;     
		    # one inline coderef and one ref to a sub
		
		#===> [1,3,5,7,9,13], [2,4,6,8,10,2048], oops
		is_deeply [$odds, $evens, @others], [ [1,3,5,7,9,13], [2,4,6,8,10,2048], oops];
	}




#head2 Lists
#head3 Absolute lists

	dominant(some, stuff, Start=> C, G, A, E, F, C, End, something, 'else');
	sub dominant
	{
		my ($notes, @rest) = args LIST Start<=>End, REST;    # including end point
		#===> [Start,C,G,A,E,F,C,End], some, stuff, something, else
		is_deeply [$notes, @rest], [ [Start,C,G,A,E,F,C,End], some, stuff, something, 'else'];
		{
		my ($notes, @rest) = args LIST Start<=End, REST;     # excluding end point
		#===> [Start,C,G,A,E,F,C], some, stuff, End, something, else
		is_deeply [$notes, @rest], [ [Start,C,G,A,E,F,C], some, stuff, End, something, 'else'];
		}
	}


	my @fields=qw/A B C D E/; my $table="FOO"; my @conditions=qw/2 4 6 8 0/;
	query(SELECT=>@fields, FROM=>$table, WHERE=>@conditions);
	sub query
	{
		my ($select, $from, $where)
		  = args LIST SELECT<=FROM, LIST FROM<=WHERE, LIST WHERE;  #explicit endings
		  #===> [SELECT, @fields], [FROM, $table], [WHERE, @conditions]
		is_deeply [$select, $from, $where], [ [SELECT, @fields], [FROM, $table], [WHERE, @conditions]];
		{  
		# But this is not what we want -- the first list grabs everything
diag "Spits out a couple of expected errors...";
		my ($select, $from, $where)
		  = args LIST SELECT, LIST FROM, LIST WHERE;               #oops!
		  #===> [SELECT, @fields, FROM, $table, WHERE, @conditions], undef, undef
		is_deeply [$select, $from, $where], [ [SELECT, @fields, FROM, $table, WHERE, @conditions], undef, undef];
		} 
		{ 
		my ($where, $from, $select)     # note the reversed order
		  = args LIST WHERE, LIST FROM, LIST SELECT;               #this is OK
		  #===> [WHERE, @conditions], [FROM, $table], [SELECT, @fields]
		is_deeply [$where, $from, $select], [ [WHERE, @conditions], [FROM, $table], [SELECT, @fields]];
		}
	}



#head3 Relative lists

	merge(black =>vs=> white);
	sub merge
	{
		my ($spys) = args LIST vs=[-1, 1];
		#===> [black, white]      # -1=posn before "vs", +1=posn after "vs"
		is_deeply [$spys], [ [black, white] ];     # -1=posn before "vs", +1=posn after "vs"
	}



	my ($a, $b, $c, $d, $e, $f) = qw/a b c d e f/;
	due(First=>$a, $b, $c, Second=>$d, $e, Third=>$f);
	sub due
	{
		my ($first, $second, $third)
		  = args LIST First=[1,2,3], LIST Second & 2, LIST Third^[-1..+1];
		#===> [$a, $b, $c], [Second, $e], [$e, $f]
		is_deeply [$first, $second, $third], [ [$a, $b, $c], [Second, $e], [$e, $f]];
	}



#head3 General notes about lists
	my ($red, $green, $blue)=qw/R G B/; my @scrabble=qw/q w e r t y/;
	let(foo, Colour=> $red, $green, $blue, Begin=>@scrabble=>Stop, bar);
	sub let
	{
		my ($rgb, $tiles, @rest)
		 = args LIST [Colour,Color]=[1,2,3], LIST [Start,Begin]<=>[Stop,-1], REST;
		#===> [$red,$green,$blue], [Begin,@scrabble,End], foo, bar
		is_deeply [$rgb, $tiles, @rest], [ [$red,$green,$blue], [Begin,@scrabble,Stop], foo, bar];
	}



#head2 Using up arguments

	side(left=>right);
	sub side
	{
		my ($dextrous, $sinister, @others) = args NAME left, FLAG left, REST;
		#===> right      undef      ()
		is_deeply [$dextrous, $sinister, @others], [ right,      undef,      ()];
		#"left" was not found as a FLAG because it was already used as a NAME
		
		# But...
		
		my ($sinister, $dextrous, @others) = args FLAG left, NAME left, REST;
		#===>   1        undef      right
		is_deeply [$sinister, $dextrous, @others], [   1,        undef,      right];
		#now "left" was not found as a NAME because it was found first as a FLAG
	}

	
	my $fh="FAKE FILEHANDLE";
	sub handle { $_=shift; return /handle/i };
	tend(Input=>$fh, Pipe=> "/dev/null");
	sub tend
	{
		my ($file, $input, $pipe)=args TYPE \&handle, NAME Input, LIST Pipe=[-1, 1];
		#===> $fh,  $fh,   [$fh, /dev/null]
		is_deeply [$file, $input, $pipe], [ $fh,  $fh,   [$fh, "/dev/null"]];
	}




#head1 UIDs


	use UID Stop;                  # create a unique ID
	way(Delimiter=>"Stop", Stop "Morningside Crescent");
	sub way
	{
		my ($tube, $telegram) = args Stop, Delimiter;
		#===>"Morningside Crescent", "Stop"
		is_deeply [$tube, $telegram], ["Morningside Crescent", "Stop"];
	}
