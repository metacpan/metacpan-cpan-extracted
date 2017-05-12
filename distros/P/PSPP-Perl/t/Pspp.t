# -*-perl-*-
# Before `make install' is performed this script should be runnable
# with `make test' as long as libpspp-core-$VERSION.so is in
# LD_LIBRARY_PATH.  After `make install' it should work as `perl
# PSPP.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 36;
use Text::Diff;
use File::Temp qw/ tempfile tempdir /;
BEGIN { use_ok('PSPP') };

#########################

sub compare
{
    my $file = shift;
    my $pattern = shift;
    return ! diff ("$file", \$pattern);
}

my $pspp_cmd = $ENV{PSPP_TEST_CMD};

if ( ! $pspp_cmd)
{
    $pspp_cmd="pspp";
}

sub run_pspp_syntax
{
    my $tempdir = shift;
    my $syntax = shift;

    my $syntaxfile = "$tempdir/foo.sps";

    open (FH, ">$syntaxfile");
    print FH "$syntax";
    close (FH);

    system ("cd $tempdir; $pspp_cmd -o raw-ascii $syntaxfile");
}

sub run_pspp_syntax_cmp
{
    my $tempdir = shift;
    my $syntax = shift;

    my $result = shift;

    run_pspp_syntax ($tempdir, $syntax);

    my $diff =  diff ("$tempdir/pspp.list", \$result);

    if ( ! ($diff eq ""))
    {
	diag ("$diff");
    }

    return ($diff eq "");
}


# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{
  my $d = PSPP::Dict->new();
  ok (ref $d, "Dictionary Creation");
  ok ($d->get_var_cnt () == 0);

  $d->set_label ("My Dictionary");
  $d->set_documents ("These Documents");

  # Tests for variable creation

  my $var0 = PSPP::Var->new ($d, "le");
  ok (!ref $var0, "Trap illegal variable name");
  ok ($d->get_var_cnt () == 0);

  $var0 = PSPP::Var->new ($d, "legal");
  ok (ref $var0, "Accept legal variable name");
  ok ($d->get_var_cnt () == 1);

  my $var1 = PSPP::Var->new ($d, "legal");
  ok (!ref $var1, "Trap duplicate variable name");
  ok ($d->get_var_cnt () == 1);

  $var1 = PSPP::Var->new ($d, "money", 
			  (fmt=>PSPP::Fmt::DOLLAR, 
			   width=>4, decimals=>2) );
  ok (ref $var1, "Accept valid format");
  ok ($d->get_var_cnt () == 2);

  $d->set_weight ($var1);


  # Tests for system file creation
  # Make sure a system file can be created
  {
      my $tempdir = tempdir( CLEANUP => 1 );
      my $tempfile = "$tempdir/testfile.sav";
      my $syntaxfile = "$tempdir/syntax.sps";
      my $sysfile = PSPP::Sysfile->new ("$tempfile", $d);
      ok (ref $sysfile, "Create sysfile object");

      $sysfile->close ();
      ok (-s "$tempfile", "Write system file");
  }
}


# Make sure we can write cases to a file
{
  my $d = PSPP::Dict->new();
  PSPP::Var->new ($d, "id",
			 (
			  fmt=>PSPP::Fmt::F, 
			  width=>2, 
			  decimals=>0
			  )
			 );

  PSPP::Var->new ($d, "name",
			 (
			  fmt=>PSPP::Fmt::A, 
			  width=>20, 
			  )
			 );

  $d->set_documents ("This should not appear");
  $d->clear_documents ();
  $d->add_document ("This is a document line");

  $d->set_label ("This is the file label");

  # Check that we can write system files
  {
      my $tempdir = tempdir( CLEANUP => 1 );
      my $tempfile = "$tempdir/testfile.sav";
      my $sysfile = PSPP::Sysfile->new ("$tempfile", $d);

      my $res = $sysfile->append_case ( [34, "frederick"]);
      ok ($res, "Append Case");

      $res = $sysfile->append_case ( [34, "frederick", "extra"]);
      ok (!$res, "Appending Case with too many variables");

      $sysfile->close ();
      ok (-s  "$tempfile", "existance");
  }

  # Check that sysfiles are closed properly
  {
      my $tempdir = tempdir( CLEANUP => 1 );
      my $tempfile = "$tempdir/testfile.sav";
      {
	  my $sysfile = PSPP::Sysfile->new ("$tempfile", $d);

	  my $res = $sysfile->append_case ( [21, "wheelbarrow"]);
	  ok ($res, "Append Case 2");

	  # Don't close.  We want to test that the destructor  does that 
	  # automatically 
      }
      ok (-s "$tempfile", "existance2");

    ok (run_pspp_syntax_cmp ($tempdir, <<SYNTAX, <<RESULT), "Check output");

        GET FILE='$tempfile'.
	DISPLAY DICTIONARY.
	DISPLAY FILE LABEL.
	DISPLAY DOCUMENTS.
	LIST.
SYNTAX
1.1 DISPLAY.  
+--------+-------------------------------------------+--------+
|Variable|Description                                |Position|
#========#===========================================#========#
|id      |Format: F2.0                               |       1|
|        |Measure: Scale                             |        |
|        |Display Alignment: Right                   |        |
|        |Display Width: 8                           |        |
+--------+-------------------------------------------+--------+
|name    |Format: A20                                |       2|
|        |Measure: Nominal                           |        |
|        |Display Alignment: Left                    |        |
|        |Display Width: 20                          |        |
+--------+-------------------------------------------+--------+

File label:
This is the file label

Documents in the active file:

This is a document line

id                 name
-- --------------------
21 wheelbarrow          

RESULT


  }

  # Now do some tests to make sure all the variable parameters 
  # can be written properly.

  {
      my $tempdir = tempdir( CLEANUP => 1 );
      my $tempfile = "$tempdir/testfile.sav";      
      my $dict = PSPP::Dict->new();
      ok (ref $dict, "Dictionary Creation 2");

      my $int = PSPP::Var->new ($dict, "integer", 
				(width=>8, decimals=>0) );

      $int->set_label ("My Integer");
      
      $int->add_value_label (99, "Silly");
      $int->clear_value_labels ();
      $int->add_value_label (0, "Zero");
      $int->add_value_label (1, "Unity");
      $int->add_value_label (2, "Duality");

      my $str = PSPP::Var->new ($dict, "string", 
				(fmt=>PSPP::Fmt::A, width=>8) );


      $str->set_label ("My String");
      ok ($str->add_value_label ("xx", "foo"), "Value label for short string");
      diag ($PSPP::errstr);
      $str->add_value_label ("yy", "bar");

      $str->set_missing_values ("this", "that");

      my $longstr = PSPP::Var->new ($dict, "longstring", 
 				(fmt=>PSPP::Fmt::A, width=>9) );


      $longstr->set_label ("My Long String");
      my $re = $longstr->add_value_label ("xxx", "xfoo");
      ok ($re, "Value label for long string");

      $int->set_missing_values (9, 99);

      my $sysfile = PSPP::Sysfile->new ("$tempfile", $dict);


      $sysfile->close ();

      ok (run_pspp_syntax_cmp ($tempdir, <<SYNTAX, <<RESULT), "Check output 2");
GET FILE='$tempfile'.
DISPLAY DICTIONARY.
SYNTAX
1.1 DISPLAY.  
+----------+---------------------------------------------+--------+
|Variable  |Description                                  |Position|
#==========#=============================================#========#
|integer   |My Integer                                   |       1|
|          |Format: F8.0                                 |        |
|          |Measure: Scale                               |        |
|          |Display Alignment: Right                     |        |
|          |Display Width: 8                             |        |
|          |Missing Values: 9; 99                        |        |
|          +---------+-----------------------------------+        |
|          |        0|Zero                               |        |
|          |        1|Unity                              |        |
|          |        2|Duality                            |        |
+----------+---------+-----------------------------------+--------+
|string    |My String                                    |       2|
|          |Format: A8                                   |        |
|          |Measure: Nominal                             |        |
|          |Display Alignment: Left                      |        |
|          |Display Width: 8                             |        |
|          |Missing Values: "this    "; "that    "       |        |
|          +---------+-----------------------------------+        |
|          | xx      |foo                                |        |
|          | yy      |bar                                |        |
+----------+---------+-----------------------------------+--------+
|longstring|My Long String                               |       3|
|          |Format: A9                                   |        |
|          |Measure: Nominal                             |        |
|          |Display Alignment: Left                      |        |
|          |Display Width: 9                             |        |
|          +---------+-----------------------------------+        |
|          |xxx      |xfoo                               |        |
+----------+---------+-----------------------------------+--------+

RESULT

  }

}

sub generate_sav_file 
{
    my $filename = shift;
    my $tempdir = shift;

    run_pspp_syntax_cmp ($tempdir, <<SYNTAX, <<RESULT);
data list notable list /string (a8) longstring (a12) numeric (f10) date (date11) dollar (dollar8.2) datetime (datetime17)
begin data.
1111 One   1 1/1/1 1   1/1/1+01:01
2222 Two   2 2/2/2 2   2/2/2+02:02
3333 Three 3 3/3/3 3   3/3/3+03:03
.    .     . .         .
5555 Five  5 5/5/5 5   5/5/5+05:05
end data.


variable labels string 'A Short String Variable'
  /longstring 'A Long String Variable'
  /numeric 'A Numeric Variable'
  /date 'A Date Variable'
  /dollar 'A Dollar Variable'
  /datetime 'A Datetime Variable'.


missing values numeric (9, 5, 999).

missing values string ("3333").

add value labels
  /string '1111' 'ones' '2222' 'twos' '3333' 'threes'
  /numeric 1 'Unity' 2 'Duality' 3 'Thripality'.

variable attribute
    variables = numeric
    attribute=colour[1]('blue') colour[2]('pink') colour[3]('violet')
    attribute=size('large') nationality('foreign').


save outfile='$filename'.
SYNTAX

RESULT

}


# Test to make sure that the dictionary survives the sysfile.
# Thanks to Rob Messer for reporting this problem
{
    my $tempdir = tempdir( CLEANUP => 1 );
    my $tempfile = "$tempdir/testfile.sav";
    my $sysfile ;

    {
	my $d = PSPP::Dict->new();

	PSPP::Var->new ($d, "id",
			(
			 fmt=>PSPP::Fmt::F, 
			 width=>2, 
			 decimals=>0
			 )
			);

	$sysfile = PSPP::Sysfile->new ("$tempfile", $d);
    }

    my $res = $sysfile->append_case ([3]);

    ok ($res, "Dictionary survives sysfile");
}


# Basic reader test
{
 my $tempdir = tempdir( CLEANUP => 1 );

 generate_sav_file ("$tempdir/in.sav", "$tempdir");

 my $sf = PSPP::Reader->open ("$tempdir/in.sav");

 my $dict = $sf->get_dict ();

 open (MYFILE, ">$tempdir/out.txt");
 for ($v = 0 ; $v < $dict->get_var_cnt() ; $v++)
 {
    my $var = $dict->get_var ($v);
    my $name = $var->get_name ();
    my $label = $var->get_label ();

    print MYFILE "Variable $v is \"$name\", label is \"$label\"\n";
    
    my $vl = $var->get_value_labels ();

    print MYFILE "Value Labels:\n";
    print MYFILE "$_ => $vl->{$_}\n" for keys %$vl;
 }

 while (my @c = $sf->get_next_case () )
 {
    for ($v = 0; $v < $dict->get_var_cnt(); $v++)
    {
	print MYFILE "val$v: \"$c[$v]\"\n";
    }
    print MYFILE "\n";
 }

 close (MYFILE);

ok (compare ("$tempdir/out.txt", <<EOF), "Basic reader operation");
Variable 0 is "string", label is "A Short String Variable"
Value Labels:
3333     => threes
1111     => ones
2222     => twos
Variable 1 is "longstring", label is "A Long String Variable"
Value Labels:
Variable 2 is "numeric", label is "A Numeric Variable"
Value Labels:
1 => Unity
3 => Thripality
2 => Duality
Variable 3 is "date", label is "A Date Variable"
Value Labels:
Variable 4 is "dollar", label is "A Dollar Variable"
Value Labels:
Variable 5 is "datetime", label is "A Datetime Variable"
Value Labels:
val0: "1111    "
val1: "One         "
val2: "1"
val3: "13197686400"
val4: "1"
val5: "13197690060"

val0: "2222    "
val1: "Two         "
val2: "2"
val3: "13231987200"
val4: "2"
val5: "13231994520"

val0: "3333    "
val1: "Three       "
val2: "3"
val3: "13266028800"
val4: "3"
val5: "13266039780"

val0: ".       "
val1: ".           "
val2: ""
val3: ""
val4: ""
val5: ""

val0: "5555    "
val1: "Five        "
val2: "5"
val3: "13334630400"
val4: "5"
val5: "13334648700"

EOF

}


# Check that we can stream one file into another
{
 my $tempdir = tempdir( CLEANUP => 1 );

 generate_sav_file ("$tempdir/in.sav", "$tempdir");

 my $input = PSPP::Reader->open ("$tempdir/in.sav");

 my $dict = $input->get_dict ();

 my $output = PSPP::Sysfile->new ("$tempdir/out.sav", $dict);

 while (my (@c) = $input->get_next_case () )
 {
   $output->append_case (\@c);
 }

 $output->close ();


 #Check the two files are the same (except for metadata)

 run_pspp_syntax ($tempdir, <<SYNTAX);
 get file='$tempdir/in.sav'.
 display dictionary.
 list.

SYNTAX

 system ("cp $tempdir/pspp.list $tempdir/in.txt");

 run_pspp_syntax ($tempdir, <<SYNTAX);
 get file='$tempdir/out.sav'.
 display dictionary.
 list.

SYNTAX
 
 ok (! diff ("$tempdir/pspp.list", "$tempdir/in.txt"), "Streaming of files");
}



# Check that the format_value function works properly
{
 my $tempdir = tempdir( CLEANUP => 1 );

 run_pspp_syntax ($tempdir, <<SYNTAX);

data list list /d (datetime17).
begin data.
11/9/2001+08:20
end data.

save outfile='$tempdir/dd.sav'.

SYNTAX

 my $sf = PSPP::Reader->open ("$tempdir/dd.sav");

 my $dict = $sf->get_dict ();

 my (@c) = $sf->get_next_case ();

 my $var = $dict->get_var (0);
 my $val = $c[0];
 my $formatted = PSPP::format_value ($val, $var);
 my $str = gmtime ($val - PSPP::PERL_EPOCH);
 print "Formatted string is \"$formatted\"\n";
 ok ( $formatted eq "11-SEP-2001 08:20", "format_value function");
 ok ( $str eq "Tue Sep 11 08:20:00 2001", "Perl representation of time");
}


# Check that attempting to open a non-existent file results in an error
{
  my $tempdir = tempdir( CLEANUP => 1 );

  unlink ("$tempdir/no-such-file.sav");

  my $sf = PSPP::Reader->open ("$tempdir/no-such-file.sav");

  ok ( !ref $sf, "Returns undef on opening failure");

  ok ("$PSPP::errstr" eq "Error opening \"$tempdir/no-such-file.sav\" for reading as a system file: No such file or directory.",
      "Error string on open failure");
}


# Missing value tests. 
{
 my $tempdir = tempdir( CLEANUP => 1 );

 generate_sav_file ("$tempdir/in.sav", "$tempdir");

 my $sf = PSPP::Reader->open ("$tempdir/in.sav");

 my $dict = $sf->get_dict ();


 my (@c) = $sf->get_next_case ();

 my $stringvar = $dict->get_var (0);
 my $numericvar = $dict->get_var (2);
 my $val = $c[0];

 ok ( !PSPP::value_is_missing ($val, $stringvar), "Missing Value Negative String");

 $val = $c[2];

 ok ( !PSPP::value_is_missing ($val, $numericvar), "Missing Value Negative Num");

 @c = $sf->get_next_case (); 
 @c = $sf->get_next_case (); 

 $val = $c[0];
 ok ( PSPP::value_is_missing ($val, $stringvar), "Missing Value Positive");

 @c = $sf->get_next_case (); 
 $val = $c[2];
 ok ( PSPP::value_is_missing ($val, $numericvar), "Missing Value Positive SYS");

 @c = $sf->get_next_case (); 
 $val = $c[2];
 ok ( PSPP::value_is_missing ($val, $numericvar), "Missing Value Positive Num");
}


#Test reading of custom attributes
{
    my $tempdir = tempdir( CLEANUP => 1 );

    generate_sav_file ("$tempdir/in.sav", "$tempdir");

    my $sf = PSPP::Reader->open ("$tempdir/in.sav");

    my $dict = $sf->get_dict ();

    my $var = $dict->get_var_by_name ("numeric");

    my $attr = $var->get_attributes ();

    open (MYFILE, ">$tempdir/out.txt");

    foreach $k (keys %$attr)
    {
	my $ll = $attr->{$k};
	print MYFILE "$k =>";
	print MYFILE map "$_\n", join ', ', @$ll;
    }

    close (MYFILE);

    ok (compare ("$tempdir/out.txt", <<EOF), "Custom Attributes");
colour =>blue, pink, violet
nationality =>foreign
size =>large
EOF

}
