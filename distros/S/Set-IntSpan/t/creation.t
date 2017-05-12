# -*- perl -*-

use strict;
use Set::IntSpan 1.17;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

sub Table { map { [ split(' ', $_) ] } split(/\s*\n\s*/, shift) }

my $Err = "Set::IntSpan::elements: infinite set";

my @New = 
([''              , '-'      , ''             ,  []		     ],
 ['     '         , '-'      , ''             ,  []		     ],
 [' ( - )  '      , '(-)'    , $Err           ,  [[undef, undef]]    ],
 ['-_2 -     -1  ', '-2--1'  , '-2,-1'        ,  [[-2,-1]]	     ],
 ['-'             , '-'      , ''             ,  []		     ],
 ['0'             , '0'      , '0'            ,	 [[0,0]]	     ],
 ['1'             , '1'      , '1'            ,  [[1,1]]	     ],
 ['1-1'           , '1'      , '1'            ,  [[1,1]]	     ],
 ['-1'            , '-1'     , '-1'           ,  [[-1,-1]]	     ],
 ['1-2'           , '1-2'    , '1,2'          ,  [[1,2]]	     ],
 ['-2--1'         , '-2--1'  , '-2,-1'        ,  [[-2,-1]]	     ],
 ['-2-1'          , '-2-1'   , '-2,-1,0,1'    ,  [[-2,1]]	     ],
 ['1,2-4'         , '1-4'    , '1,2,3,4'      ,  [[1,4]]	     ],
 ['1-3,4,5-7'     , '1-7'    , '1,2,3,4,5,6,7',	 [[1,7]]	     ],
 ['1-3,4'         , '1-4'    , '1,2,3,4'      ,  [[1,4]]	     ],
 ['1,2,4,5,6,7'   , '1-2,4-7', '1,2,4,5,6,7'  ,	 [[1,2],[4,7]]	     ],
 ['1,2-)'         , '1-)'    , $Err           ,  [[1,undef]]	     ],
 ['(-0,1-)'       , '(-)'    , $Err           ,  [[undef,undef]]     ],
 ['(-)'           , '(-)'    , $Err           ,  [[undef,undef]]     ],
 ['1-)'           , '1-)'    , $Err           ,  [[1,undef]]	     ],
 ['(-1'           , '(-1'    , $Err           ,  [[undef,1]]         ],
 ['-3,-1-)'       , '-3,-1-)', $Err           ,  [[-3,-3],[-1,undef]]],
 ['(-1,3'         , '(-1,3'  , $Err           ,  [[undef,1],[3,3]]   ],
);

my @New_list = 
(
 ['1', '2', '1-2'],
 ['1-5', '2', '1-5'],
 ['1-5', '2-8', '1-8'],
 ['1-5', '2-8', '10-20', '1-8,10-20'],
 ['(-5', '2-8', '10-20', '(-8,10-20'],
 ['(-5', '2-8', '10-)', '(-8,10-)'],
 ['40-45', '20-25', '10-15', '1', '12-13', '1,10-15,20-25,40-45' ]
);

my @New_array =
(
 [ [					 ], "-"		  ],
 [ [ 1					 ], "1"		  ],
 [ [ 1, 1				 ], "1"		  ],
 [ [ 1, 2				 ], "1-2"	  ],
 [ [ 1, 2, 2				 ], "1-2"	  ],
 [ [ 1, 3, 3				 ], "1,3"	  ],
 [ [ 1, 3				 ], "1,3"	  ],
 [ [ 1, 3, 3				 ], "1,3"	  ],
 [ [ 1, 3, 4				 ], "1,3,4"	  ],
 [ [ 1, 3, 4, 4				 ], "1,3,4"	  ],
 [ [ 1, 2, 4				 ], "1-2,4"	  ],
 [ [ 1, 2, 4, 4				 ], "1-2,4"	  ],
 [ [ 1, 2, 4, 5				 ], "1-2,4-5"	  ],
 [ [ 1, 2, 4, 5, 5			 ], "1-2,4-5"	  ],
 [ [ 3, 2, 1                             ], "1-3"         ],
 [ [ [ undef, -1 ]                       ], "(--1"        ],
 [ [ 5, [ undef, 1 ], 3    		 ], "(-1,3,5" 	  ],
 [ [ 5, [ undef, 1 ], 3, 4 		 ], "(-1,3-5" 	  ],
 [ [ 5, [ undef, 1 ], 3, [ 8, undef ], 4 ], "(-1,3-5,8-)" ],
 [ [ 5, [ undef, 1 ], 3, [ 6, undef ], 4 ], "(-1,3-)"     ],
 [ [ 5, [ undef, 2 ], 3, [ 4, undef ], 4 ], "(-)"         ],
 [ [ [ 1, 5 ], [ 3, 8 ], 27              ], "1-8,27"      ],
 [ [ 1, [ 5, 8 ], 5, [ 7, 9 ], 2         ], "1-2,5-9"     ],
);

print "1..", @New * 7 + @New_list + @New_array, "\n";
New      ();
Elements ();
Sets     ();
Spans    ();
New_list ();
New_array();


sub New
{
    print "#new\n";

    for my $test (@New)
    {
        my $set    = new Set::IntSpan $test->[0];
	my $result = $set->run_list();
	printf "#new %-14s -> %s\n", $test->[0], $result;
	$result eq $test->[1] or Not; OK

	my $copy = new Set::IntSpan $set;
	$result = $copy->run_list();
	printf "#new %-14s -> %s\n", $test->[0], $result;
	$result eq $test->[1] or Not; OK;
    }
}


sub Elements
{
    print "#elements\n";

    my($set, $expected, @elements, $elements, $result);

    for my $t (@New)
    {
        $set      = new Set::IntSpan $t->[0];
	$expected = $t->[2];

	eval { @elements = elements $set };
	if ($@)
	{
	    printf "#elements %-14s -> %s\n", $t->[0], $@;
	    $@ =~/$expected/ or Not; OK;
	}
	else
	{
	    $result = join(',', @elements );
	    printf "#elements %-14s -> %s\n", $t->[0], $result;
	    $result eq $expected or Not; OK;
	}

	eval { $elements = elements $set };
	if ($@)
	{
	    printf "#elements %-14s -> %s\n", $t->[0], $@;
	    $@ =~ /$expected/ or Not; OK;
	}
	else
	{
	    $result = join(',', @$elements );
	    printf "#elements %-14s -> %s\n", $t->[0], $result;
	    $result eq $expected or Not; OK;
	}
    }
}

sub Sets
{
    print "#sets\n";

    for my $t (@New)
    {
	my $set      = new Set::IntSpan $t->[0];
	my @sets     = sets $set;
	my @expected = map { $_ eq '-' 
				 ? ()
				 : new Set::IntSpan $_ } split /,/, $t->[1];

	equal_sets(\@sets, \@expected) or Not; OK;
    }
}

sub equal_sets
{
    my($a, $b) = @_;

    @$a == @$b or return 0;

    while (@$a)
    {
	my $a = shift @$a;
	my $b = shift @$b;

	ref $a eq 'Set::IntSpan' or return 0;
	ref $b eq 'Set::IntSpan' or return 0;

	equal $a $b or return 0;
    }

    1
}

sub Spans
{
    print "#spans\n";

    for my $t (@New)
    {
	my $set1     = new Set::IntSpan $t->[0];
	my @spans    = spans $set1;
	my $expected = $t->[3];
	equal_lists(\@spans, $expected) or Not; OK;

	my $set2    = new Set::IntSpan $t->[3];
	equal $set1 $set2 or Not; OK;
	print "set1 $set1, set2 $set2\n";
	
    }
}

sub equal_lists
{
    my($a, $b) = @_;

    # print "a <@$a>, b <@$b>\n";
    @$a==@$b or return 0;

    my @a = @$a;
    my @b = @$b;

    while (@a)
    {
	my $aa = shift @a;
	my $bb = shift @b;

	if    (ref     $aa and ref     $bb) { equal_lists($aa, $bb) 		  or return 0 }
	elsif (defined $aa and defined $bb) { $aa == $bb	    		  or return 0 }
	else  				    { not defined $aa and not defined $bb or return 0 }
    }

    1
}


sub New_list
{
    for my $t (@New_list)
    {
	my @run_lists = @$t;
	my $expected = pop @run_lists;
	my $set = new Set::IntSpan @run_lists;
	my $actual = $set->run_list;
	$set->equal($expected) or Not; OK;
    }
}


sub New_array
{
    for my $t (@New_array)
    {
	my $actual = new Set::IntSpan $t->[0];
	my $expected = $t->[1];
	$actual eq $expected or Not; OK;
    }
}
