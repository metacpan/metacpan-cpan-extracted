# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 60 };
use OpenOffice::Parse::SXC;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.



test();


sub test {
  my $SXC		= OpenOffice::Parse::SXC->new;
  -f "test_data.sxc" && ok(1);

  # First, parse the 10x10 AND other spreadsheets:
  $SXC->set_options( worksheets	=> [ "10x10", "other" ] ) && ok(1);

  $SXC->parse_file( "test_data.sxc" ) && ok(1);
  use Data::Dumper;
  my @expected_data	= (
			   "a1,b1,c1,d1,e1,f1,g1,h1,1",
			   "a2,b2,c2,d2,e2,f2,g2,h2,2",
			   "a3,b3,c3,d3,e3,f3,g3,h3,3",
			   "a4,b4,c4,d4,e4,f4,g4,h4,4",
			   "a5,b5,c5,d5,e5,f5,g5,h5,5",
			   "a6,b6,c6,d6,e6,f6,g6,h6,6",
			   "a7,b7,c7,d7,e7,f7,g7,h7,7",
			   "a8,b8,c8,d8,e8,f8,g8,h8,8",
			   "a9,b9,c9,d9,e9,f9,g9,h9,9",
			   "a10,b10,c10,d10,e10,f10,g10,h10,10",
			   "a,b,c,d,e,f,g,h,",
			   "a1,b1,c1,d1,e1,f1,g1,h1,i1,j1,1",
			   "a2,b2,c2,d2,e2,f2 g2 h2,i2,j2,2",
			   "a3,b3,c3,d3,e3,f3,g3,h3,i3,j3,3",
			   "a4,b4,c4,d4,e4,f4,g4,h4,i4,j4,4",
			   "a5,b5,c5,d5,e5,f5,g5,h5,i5,j5,5",
			   "a6,b6,c6,d6,e6,f6,g6 h6 i6 g7 h7 i7 g8 h8 i8,j6,6",
			   "a7,b7 b8 b9,c7,d7,e7,f7,j7,7",
			   "a8,c8,d8,e8,f8,j8,8",
			   "a9,c9,d9,e9,f9,g9,h9,i9,j9,9",
			   "a10,b10,c10,d10,e10,f10,g10,h10,i10,j10,10",
			   "a,b,c,d,e,f,g,h,i,j,",
			  );
  my @rows		= $SXC->parse_sxc_rows;
  $SXC->clear_parse_sxc_rows;
  for( 0 .. $#rows ) {
    ok( $expected_data[$_] eq join(",",@{$rows[$_]} ) );
  }
#  print STDERR Dumper( [@rows] );


  # The types worksheet:

  $SXC->set_options( worksheets	=> [ "types" ],
		     no_trim	=> 1 ) && ok(1);
  $SXC->parse_file( "test_data.sxc" ) && ok(1);

  @expected_data	= (
			   "Numeric,12345",
			   "Percent,12.50%",
			   "Currency,\$19.95",
			   "Time,12:55:00 pm",
			   "Boolean,TRUE",
			   "Scientific,3.00E+005",
			  );
  @rows			= $SXC->parse_sxc_rows;
  $SXC->clear_parse_sxc_rows;
  for( 0 .. $#rows ) {
    ok( $expected_data[$_] eq join(",",@{$rows[$_]} ) );
  }

  # The texts worksheet:

  $SXC->set_options( worksheets	=> [ "texts" ],
		     no_trim	=> 0 ) && ok(1);
  $SXC->parse_file( "test_data.sxc" ) && ok(1);

  @expected_data	=
    (
     "This text has   lots    of       spaces,,,,,",
     ",,,,,",
     ",,,,,",
     ",,,,,",
     ",,,,,",
     ",,    hidden text at c6 with leading + trailing spaces    ,,,",
     ",,,,,",
     ",,,,,",
     ",Text at B9 with trailing spaces      ,,,,",
     ",,,,,",
     ",,,,,",
     ",,,,,",
     ",,,,,",
     ",,,,e14 is hidden on two axes, and is grouped on one.,",
     ",grouped text at b15 with lots of strange characters: 1234567890--=+_)(*&^%\$#\@!/><|}{[]\\';\":`~,,,,",
     ",,,,,",
     ",,,,,",
     ",,,,,",
     ",,,,,",
     "cell at a20 has wordwrap on, and has a very, very, very long text string in it.  In fact, I really don't know how long a string OpenOffice will allow me to put into a cell, but at the very least, I should put in a reasonable ammount.,,,,,",
     ",,,,,",
     ",,,,,",
     ",,,,Hidden Cell at B24 has a string with newlines embedded\nSee, this is line 2\nAnd this is line 3,",
    );

  @rows			= $SXC->parse_sxc_rows;
  $SXC->clear_parse_sxc_rows;
  for( 0 .. $#rows ) {
    ok( $expected_data[$_] eq join(",",@{$rows[$_]} ) );
  }
  ok( 1 );
#      for( @rows ) {
#        print STDERR join(",", @$_),"\n";
#      }

}



