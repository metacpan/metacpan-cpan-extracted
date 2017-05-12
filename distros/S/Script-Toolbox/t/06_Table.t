# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

sub printM($$$)
{
	my ($ref, $r, $file) = @_;

	open ( FH,  "> ${file}.1" );
	map { print FH "$_\n"; } @{$ref};
	open ( FH,  "> ${file}.2" );
	map { print FH "$_\n"; } @{$r};
}

sub my_eq_array($$)
{
    my( $x, $y ) = @_;

    my $c1 = scalar @{$x};
    my $c2 = scalar @{$y};
    return 0 if ( $c1 != $c2 );

    for ( my $i=0; $i < $c1; $i++ )
    {
        return 0 if( $x->[$i] ne  $y->[$i] );
    }
    return 1;
}

#########################
#########################

use Test::More tests => 12;
BEGIN { use_ok('Script::Toolbox') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

##############################################################################
unlink "/tmp/06_Table.log",<*.1>,<*.2>;

$F = Script::Toolbox->new({logdir=>{mod=>'=s',mand=>1,default=>'/tmp'}});
##############################################################################
############################### TEST 2 #####################################
$rep1 = {
	    'title' => 'Test2',
		'head'  => ['Feld1', 'Feld2', 'Feld3'],
		'data'  => [
					[ 'aaa', 'bb          ', 'cc  ' ],
					[ 11111, 2222222, 3 ]
				   ]
		};
$r = $F->Table( $rep1 );
$ref = ["== Test2 ==",
		"Feld1 Feld2   Feld3",
		"----- ------- -----",
		"aaa   bb      cc   ",
		"11111 2222222 3    ",
		];
printM($ref, $r, 'AA');
ok(my_eq_array($ref, $r));

############################### TEST 3 #####################################
$rep2 = {
	'title'	=> 'Test3',
	'data'	=> [
				{ 'F1' => 'aaaa', 'F2' => 'bbb   ', 'F3' => 'c' },
				{ 'F1' => 'dddd', 'F2' => 'eee   ', 'F3' => 'f' }
			   ]
};

$r = $F->Table( $rep2 );
$ref = ["== Test3 ==",
		"F1   F2  F3",
		"---- --- --",
		"aaaa bbb c ",
		"dddd eee f ",
		];
printM($ref, $r, 'BB');
ok(my_eq_array($ref, $r));



############################### TEST 4 #####################################
$rep4 = {
	'title'	=> 'Test4',
	'head'	=> ['Feld1', 'Feld2', 'Feld3'],
	'data'	=> [
				[ '11:11:11', -33.456, 'cc  ' ],
				[ '12:23:00', 2222222, 3 ],
				[ '11:11', 222, 3333333333333333 ] ]
};
$r = $F->Table( $rep4 );
$ref = ["== Test4 ==",
		"Feld1          Feld2 Feld3               ",
		"-------- ----------- --------------------",
		"11:11:11     -33.456 cc                  ",
		"12:23:00 2222222.000 3                   ",
		"11:11        222.000 3.33333333333333e+15",
		];
$ref2= ["== Test4 ==",
		"Feld1          Feld2 Feld3           ",
		"-------- ----------- ----------------",
		"11:11:11     -33.456 cc              ",
		"12:23:00 2222222.000 3               ",
		"11:11        222.000 3333333333333333",
		];
printM($ref, $r, 'DD');
ok(my_eq_array($ref, $r) || my_eq_array($ref2, $r));

############################### TEST 5/6 #####################################
$rep5 = {
	'title'	=> 'Test5',
	'head'	=> ['Feld1', 'Feld2', 'Feld3'],
	'data'  => [],
};
$r = $F->Table( $rep5 );
$ref = [];
printM($ref, $r, 'EE');
#ok(eq_array($ref, $r));
ok( -z 'EE.1' && -z 'EE.2', 'empty array is ok' );
ok( system("grep 'WARNING: no data for Table()' /tmp/6_Table.log >/dev/null 2>&1") / 256 );


############################### TEST 7 #####################################
$rep6 = {
	'data'	=> [
				[ '11:11:11',  33.456, 'cc  ' ],
				[ '12:23:00', 2222222, 3 ],
				[ '11:11', 222, 3333333333333333 ] ]
};
$r = $F->Table( $rep6 );
$ref = ["== Title ==",
		"Col-0          Col-1 Col-2               ",
		"-------- ----------- --------------------",
		"11:11:11      33.456 cc                  ",
		"12:23:00 2222222.000 3                   ",
		"11:11        222.000 3.33333333333333e+15"
	   ];
$ref2= ["== Title ==",
		"Col-0          Col-1 Col-2           ",
		"-------- ----------- ----------------",
		"11:11:11      33.456 cc              ",
		"12:23:00 2222222.000 3               ",
		"11:11        222.000 3333333333333333",
		];
printM($ref, $r, 'FF');
ok(my_eq_array($ref, $r) || my_eq_array($ref2, $r));


############################### TEST 8 #####################################
$rep7 = 
	 [
		'This is the title',
		[ '--H1--', '--H2--','--H3--'],
		[ '11:11:11',  33.456, 'cc  ' ],
		[ '12:23:00', 2222222, 3 ],
		[ '11:11', 222, 3333333333333333 ] 
	];
$r = $F->Table( $rep7 );
$ref = ["== This is the title ==",
		"--H1--        --H2-- --H3--              ",
		"-------- ----------- --------------------",
		"11:11:11      33.456 cc                  ",
		"12:23:00 2222222.000 3                   ",
		"11:11        222.000 3.33333333333333e+15"
	   ];
$ref2= ["== This is the title ==",
		"--H1--        --H2-- --H3--          ",
		"-------- ----------- ----------------",
		"11:11:11      33.456 cc              ",
		"12:23:00 2222222.000 3               ",
		"11:11        222.000 3333333333333333",
		];
printM($ref, $r, 'GG');
ok(my_eq_array($ref, $r) || my_eq_array($ref2, $r));



############################### TEST 9 #####################################
$rep8 = [ "1;2;3","44;55;66","777;888;999" ];
$r = $F->Table( $rep8 );
$ref = [
		"== Title ==",
		"Col-0 Col-1 Col-2",
		"----- ----- -----",
		"    1     2     3",
		"   44    55    66",
		"  777   888   999"
	   ];
printM($ref, $r, 'HH');
ok(my_eq_array($ref, $r));



############################### TEST 10 #####################################
$rep9 = [ "1,2,3","44,55,66","777,888,999" ];

$r = $F->Table( $rep9, ',' );
$ref = [
		"== Title ==",
		"Col-0 Col-1 Col-2",
		"----- ----- -----",
		"    1     2     3",
		"   44    55    66",
		"  777   888   999"
	   ];
printM($ref, $r, 'II');
ok(my_eq_array($ref, $r));


############################### TEST 11 #####################################
$rep10 = [ "1;2;3","44;55;66","7.77;8.88;9.99" ];

$r = $F->Table( $rep10 );
$ref = [
		"== Title ==",
		"   Col-0    Col-1    Col-2",
		"-------- -------- --------",
		"    1.00     2.00     3.00",
		"   44.00    55.00    66.00",
		"    7.77     8.88     9.99"
	   ];
printM($ref, $r, 'JJ');
ok(my_eq_array($ref, $r));


############################### TEST 12 #####################################
$rep11 = {
	'title'	=> 'Test12',
	'data'	=> {
				'line1' => { 'F1' => 'aaaa', 'F2' => 'bbb   ', 'F3' => 'c' },
				'line2' => { 'F1' => 'dddd', 'F2' => 'eee   ', 'F3' => 'f' }
			   }
};

$r = $F->Table( $rep11 );
$ref = ["== Test12 ==",
		"KEY   F1   F2  F3",
		"----- ---- --- --",
		"line1 aaaa bbb c ",
		"line2 dddd eee f ",
		];
printM($ref, $r, 'BB');
ok(my_eq_array($ref, $r));


unlink "/tmp/06_Table.log",<*.1>,<*.2>;
