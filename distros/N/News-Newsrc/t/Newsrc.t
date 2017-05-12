# -*- perl -*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..125\n";}
END {print "not ok 1\n" unless $loaded;}
use News::Newsrc;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $N = 1;

sub Not{ print "not " };
sub OK { print "ok ", ++$N, "\n" }

#GLOBALS
my $Verbose;
my @Test_files = qw(t/newsrc t/.newsrc t/newsrc.bak t/.newsrc.bak);

$ENV{HOME} = 't';

test_new	 ();
test_load        ();
test_load_errs   ();
test_save        ();
test_save_bak    ();
test_save_load   ();
test_save_as     ();
test_import      ();
test_export      ();
test_groups      ();
test_subscription();
test_where       ();
test_moves       ();
test_adds        ();
test_marks       ();
test_predicates  ();
test_lists       ();
test_get_articles();
test_set_articles();

unlink @Test_files;

sub test_new
{
    print "#new\n";

    new News::Newsrc;    	 OK;
    new News::Newsrc "t/fodder"; OK;

    unlink "t/no_file";

    eval { new News::Newsrc "t/no_file" };
    $@ =~ m(Can't load t/no_file:) or Not; OK;

    my $no_file = new News::Newsrc "t/no_file", create => 1; OK;
    $no_file->save;
    new News::Newsrc "t/no_file"; OK;
}


sub test_load
{
    print "#load\n";

    my @test = (["t/.newsrc", "a: 1,3\n\n", ""            , 1 , "a: 1,3\n" ],
		["t/newsrc" , "b! 1-10\n ", "t/newsrc"    , 1 , "b! 1-10\n"],
		[""         , ""          , "t/newsrc.bak", "", ""         ]);

    my $t;
    my $rc = new News::Newsrc;

    unlink @Test_files;
    for $t (@test)
    {
	my($write_file, $contents, $load_file, $e_return, $e_dump) = @$t;
	write_file($write_file, $contents);
	my $return = $rc->load($load_file);
	my $dump = $rc->_dump();
	printf("#%-12s %s -> %s: %s\n", 
	       "load($load_file)", $contents, $return, $dump);
	$return eq $e_return and $dump eq $e_dump or Not; OK;
    }
}


sub test_load_errs
{
    print "#load errors\n";

    my @test = ([ 't/.newsrc', 'a'      , 'Bad newsrc line' ],
		[ 't/.newsrc', 'a: 10-1', 'Bad article list']);

    my $t;
    my $rc = new News::Newsrc;

    unlink @Test_files;
    for $t (@test)
    {
	my($file, $contents, $error) = @$t;
	write_file($file, $contents);
	my $return = eval { $rc->load() };
	printf("#%-12s %-10s -> %s %s", 
	       "load", $contents, defined $return ? 't' : 'f', $@);
	not $return and $@ =~ /$error/ or Not; OK;
    }
}


sub test_save
{
    print "#save\n";

    unlink @Test_files;
    my $rc = new News::Newsrc;
    my $scan ="a: 1,3\n";
    $rc->_scan($scan);
    $rc->save();
    my $read = read_file('t/.newsrc');
    printf("#%-12s %20s -> %s", "save", $scan, $read);
    $scan eq $read or Not; OK;
}


sub test_save_bak
{
    print "#save_bak\n";
    unlink @Test_files;
    my $rc = new News::Newsrc;

    $rc->save();
    my $result = defined -e 't/.newsrc.bak' ? 1 : 0;
    printf("#%-12s %-20s -> %d\n", "save", "", $result);
    $result and Not; OK;

    $rc->save();
    $result = defined -e 't/.newsrc.bak' ? 1 : 0;
    printf("#%-12s %-20s -> %d\n", "save", "", $result);
    $result or Not; OK;
}


sub test_save_load
{
    print "#save_load\n";
    my $rc = new News::Newsrc;

    write_file('t/newsrc', '');
    $rc->load('t/newsrc');
    unlink @Test_files;
    $rc->save();

    my $result = defined -e 't/newsrc' ? 1 : 0;
    printf("#%-12s %-20s -> %d\n", "save", "", $result);
    $result or Not; OK;
}


sub test_save_as
{
    print "#save_as\n";
    my $rc = new News::Newsrc;

    unlink @Test_files;
    $rc->save_as('t/newsrc');
    my $result = defined -e 't/newsrc' ? 1 : 0;
    printf("#%-12s %-20s -> %d\n", "save", "", $result);
    $result or Not; OK;

    unlink @Test_files;
    $rc->save();
    $result = defined -e 't/newsrc' ? 1 : 0;
    printf("#%-12s %-20s -> %d\n", "save", "", $result);
    $result or Not; OK;
}


sub test_import
{
    print "#import\n";

    my $lines = <<LINES;
a: 1,3
b! 1-10
c: 1,3,5,9-9000
LINES
    my @lines = split /\n/, $lines;
    my $rc = new News::Newsrc;

    $rc->import_rc(@lines);
    $rc->_dump eq $lines or Not; OK;

    $rc->import_rc(\@lines);
    $rc->_dump eq $lines or Not; OK;
}


sub test_export
{
    print "#export\n";

    my $contents = <<CONTENTS;
a: 1,3
b! 1-10
c: 1,3,5,9-9000
CONTENTS

    my $rc = new News::Newsrc;
    $rc->_scan($contents);

    my @lines = $rc->export_rc;
    join('',  @lines) eq $contents or Not; OK;

    my $lines = $rc->export_rc;
    join('', @$lines) eq $contents or Not; OK;
}


sub test_groups
{
    print "#groups\n";

    my @test = (["add_group('a')            ", "a:\n"        , 1],
		["add_group('b')            ", "a:\nb:\n"    , 1],
		["add_group('c')            ", "a:\nb:\nc:\n", 1],
		["add_group('c')            ", "a:\nb:\nc:\n", 0],
		["add_group('c', replace=>1)", "a:\nb:\nc:\n", 1],
		["del_group('b')            ", "a:\nc:\n"    , 1],
		["del_group('x')            ", "a:\nc:\n"    , 0]);
	 
    my $rc = new News::Newsrc;

    my $t;
    for $t (@test)
    {
	my($op, $eDump, $eReturn) = @$t;
	my $return = eval "\$rc->$op";
	my $dump   = $rc->_dump();
	print "#$op\n$dump, $return\n";
	$dump eq $eDump and $return == $eReturn or Not; OK;
    }
}


sub test_subscription
{
    print "#subscription\n";

    my @test = (["unsubscribe('a')", "a!\nc:\n"],
		["subscribe('a')  ", "a:\nc:\n"],
		["subscribe('d')  ", "a:\nc:\nd:\n"],
		["unsubscribe('e')", "a:\nc:\nd:\ne!\n"]);
	 
    my $rc = new News::Newsrc;
    $rc->add_group("a");
    $rc->add_group("c");

    my $t;
    for $t (@test)
    {
	my($op, $expected) = @$t;
	eval "\$rc->$op";
	my $result = $rc->_dump();
	print "#$op\n$result";
	$result eq $expected or Not; OK;
    }
}


sub test_where
{
    print "#where\n";

    my $test = <<TEST;
'e'                       e
'h'                       e h
'a',where=>'first'        a e h
'z',where=>'last'         a e h z
'g',where=>'alpha'        a e g h z
'f',where=>[number=>2]    a e f g h z
'r',where=>[number=>-1]   a e f g h r z
'p',where=>[before=>'r']  a e f g h p r z
't',where=>[after=>'r']   a e f g h p r t z
'w',where=>[number=>100]  a e f g h p r t z w
'x',where=>[before=>'b']  a e f g h p r t z w x
'y',where=>[after=>'b']   a e f g h p r t z w x y
TEST
    
    my $rc = new News::Newsrc;

    for (split(/\n/, $test))
    {
	my($op, @groups) = split;
	eval "\$rc->add_group($op)";
	my $result   = $rc->_dump;
	my $expected = join(":\n", @groups, '');
	print "#$op\n$result";
	$result eq $expected or Not; OK;
    }
}


sub test_moves
{
    print "#moves\n";
    
    my @groups = qw(a b d e f g c);
    
    my $test = <<TEST;
'c',where=>'alpha'        a b c d e f g
'a',where=>'alpha'        a b c d e f g
'g',where=>'alpha'        a b c d e f g
'b'                       a c d e f g b
'c',where=>'first'        c a d e f g b
'g',where=>'last'         c a d e f b g
'f',where=>[number=>2]    c a f d e b g
'e',where=>[number=>-1]   c a f d b e g
'g',where=>[before=>'b']  c a f d g b e
'a',where=>[after=>'d']   c f d a g b e
'd',where=>[number=>-100] d c f a g b e
'f',where=>[before=>'x']  d c a g b e f
'c',where=>[after=>'x']   d a g b e f c
TEST
    
    my $rc = new News::Newsrc;
    
    my $group;
    for $group (@groups) { $rc->add_group($group) }

    for (split(/\n/, $test))
    {
	my($op, @groups) = split;
	eval "\$rc->move_group($op)";
	my $result   = $rc->_dump;
	my $expected = join(":\n", @groups, '');
	print "#$op\n$result";
	$result eq $expected or Not; OK;
    }
}


sub test_adds
{
    print "#adds\n";

    my @test = 
	(['add_group'        , []   ],
	 ['subscribe'        , []   ],
	 ['unsubscribe'      , []   ],
	 ['mark'             , [1]  ], 
	 ['mark_list'        , [[1]]],
	 ['mark_range'       , [1,1]],
	 ['unmark'           , [1]  ], 
	 ['unmark_list'      , [[1]]],
	 ['unmark_range'     , [1,1]],
	 ['marked_articles'  , []   ],
	 ['unmarked_articles', [1,1]],
	 ['get_articles'     , []   ],
	 ['set_articles'     , [1]  ]);
    
    my $rc = new News::Newsrc;
    my $group = 'a';

    my $test;
    for $test (@test)
    {
	my($method, $args) = @$test;
	$rc->$method($group++, @$args, where=>'first');
    }

    my $result   = join(' ', $rc->groups);
    my $expected = join(' ', reverse 'a'..'m');
    $result eq $expected or Not; OK;
    print "#$result\n";
}


sub test_marks
{
    print "#marks\n";

    my @test1 = 
	(["mark        ('a', 1      )", "a: 1\nb:\nc:\n"                   ],
	 ["mark        ('b', 4      )", "a: 1\nb: 4\nc:\n"                 ],
	 ["mark_list   ('c', [1,3,5])", "a: 1\nb: 4\nc: 1,3,5\n"           ],
	 ["mark_list   ('b', [1..10])", "a: 1\nb: 1-10\nc: 1,3,5\n"        ],
	 ["mark_range  ('a', 3, 5   )", "a: 1,3-5\nb: 1-10\nc: 1,3,5\n"    ],
	 ["unmark      ('a', 3      )", "a: 1,4-5\nb: 1-10\nc: 1,3,5\n"    ],
	 ["unmark_list ('b', [3..5] )", "a: 1,4-5\nb: 1-2,6-10\nc: 1,3,5\n"],
	 ["unmark_range('c', 5, 10  )", "a: 1,4-5\nb: 1-2,6-10\nc: 1,3\n"  ]);

    my $r1 = $test1[-1]->[1];

    my @test2 = 
	(["mark        ('d', 1    )",  $r1 . "d: 1\n"],
	 ["mark_list   ('e', [1,2])",  $r1 . "d: 1\ne: 1-2\n"],
	 ["mark_range  ('f', 3, 5 )",  $r1 . "d: 1\ne: 1-2\nf: 3-5\n"]);

    my $r2 = $test2[-1]->[1];

    my @test3 = 
	(["unmark      ('g', 1    )",  $r2 . "g:\n"],
	 ["unmark_list ('h', [1,2])",  $r2 . "g:\nh:\n"],
	 ["unmark_range('i', 3, 5 )",  $r2 . "g:\nh:\ni:\n"]);

    my $rc = new News::Newsrc;
    $rc->add_group('a');
    $rc->add_group('b');
    $rc->add_group('c');

    my $t;
    for $t (@test1, @test2, @test3)
    {
	my($op, $expected) = @$t;
	eval "\$rc->$op";
	my $result = $rc->_dump();
	print "#$op\n$result";
	$result eq $expected or Not; OK;
    }
}


sub test_predicates
{
    print "#predicates\n";

    my @test = 
	(["exists",     ['a'    ], 1],
	 ["exists",     ['b'    ], 1],
	 ["exists",     ['e'    ], 0],
	 ["subscribed", ['a'    ], 1],
	 ["subscribed", ['b'    ], 0],
	 ["subscribed", ['e'    ], 0],
	 ["marked",     ['a', 1 ], 1],
	 ["marked",     ['a', 6 ], 0],
	 ["marked",     ['b', 4 ], 1],
	 ["marked",     ['c', 25], 0],
	 ["marked",     ['e', 1 ], 0],
	 ["exists",     ['e'    ], 0]);

    my $rc = new News::Newsrc;
    $rc->load("t/fodder");

    my $t;
    for $t (@test)
    {
	my($op, $args, $expected) = @$t;
	my $result = $rc->$op(@$args);
	print "#$op(@$args) -> $result\n";
	($result xor $expected) and Not; OK;
    }
}


sub test_lists
{
    print "#lists\n";

    my $rc = new News::Newsrc;
    $rc->load("t/fodder");

    my $n = $rc->num_groups;
    print "#num_groups -> $n\n";
    $n==5 or Not; OK;

    my @test = 
	(["groups                      ", "c a f b d"],
	 ["sub_groups                  ", "c a d"    ],
	 ["unsub_groups                ", "f b"      ],
	 ["marked_articles  ('a')      ", "1 2 3 4 5"],
	 ["marked_articles  ('x')      ", ""         ],
	 ["unmarked_articles('a', 1, 9)", "6 7 8 9"  ],
	 ["unmarked_articles('y', 3, 5)", "3 4 5"    ]);

    my $t;
    for $t (@test)
    {
	my($op, $expected) = @$t;
	my @result = eval "\$rc->$op";
	my $result = join(' ', @result);
	print "#$op -> $result\n";
	$result eq $expected or Not; OK;
    }

    $rc->load("t/fodder");

    for $t (@test)
    {
	my($op, $expected) = @$t;
	my $result = eval "\$rc->$op";
	   $result = join(' ', @$result);
	print "#$op -> $result\n";
	$result eq $expected or Not; OK;
    }
}


sub test_get_articles
{
    print "#get_articles\n";

    my $get = <<GET;
c 20-21,33,38
a 1-5
f
b 3-8,15,20
d 1,3,7
x
GET
    my $rc = new News::Newsrc;
    $rc->load("t/fodder");

    for (split(/\n/, $get))
    {
	my($group, $expected) = (split, '');
	my $result = $rc->get_articles($group);
	print "#$group -> $result\n";
	$result eq $expected or Not; OK;
    }
}


sub test_set_articles
{
    print "#set_articles\n";

    my $set = <<SET;
c
a 1-5,81
f 5
y 23,26,31-91
z
SET

    my $rc = new News::Newsrc;
    $rc->load("t/fodder");

    for (split(/\n/, $set))
    {
	my($group, $expected) = (split, '');

	my $ok = $rc->set_articles($group, $expected);
	print "#$group -> $ok\n";
	$ok or Not; OK;

	my $result = $rc->get_articles($group);
	print "#$group -> $result\n";
	$result eq $expected or Not; OK;

	$ok = $rc->set_articles($group, '----');
	print "#$group -> $ok\n";
	$ok and Not; OK;

	$result = $rc->get_articles($group);
	print "#$group -> $result\n";
	$result eq $expected or Not; OK;
    }
}


sub write_file
{
    my($name, $contents) = @_;
    $name or return;
    open(FILE, "> $name") or die "Can't open $name: $!\n";
    print FILE $contents;
    close FILE;
}


sub read_file
{
    my($name) = @_;
    open(FILE, "$name") or die "Can't open $name: $!\n";
    my $contents = join('', <FILE>);
    close FILE;
    $contents;
}

