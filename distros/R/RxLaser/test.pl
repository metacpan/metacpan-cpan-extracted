# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use RxLaser;
$loaded = 1;
print "ok 1\n";

######################### End of magic.

my $chip = new RxLaser;

#--------------------------------------- test 2
print $chip->_Horiz(12) eq pack('CCCCCC', 27,38,107,49,50,72) ? "ok 2" : "not ok 2", "\n";

#--------------------------------------- test 3
print $chip->_Vert(8) eq pack('CCCCC', 27,38,108,56,67) ? "ok 3" : "not ok 3", "\n";

#--------------------------------------- test 4
if( open UB, ">ub92.prn" ){
    print UB $chip->formub92, "                       ";
    print "ok 4\n";
    close UB;
}
else { print "not ok 4\n"; }

#--------------------------------------- test 5
print "ok 5\n";

#--------------------------------------- test 6
if( open FOUR85 , ">485.prn" ){
    print FOUR85 $chip->form485, "                 ";
    print "ok 6\n";
    close FOUR85;
}
else { print "not ok 6\n"; }

#--------------------------------------- test 7
if( open FOUR86 , ">486.prn" ){
    print FOUR86 $chip->form486, "                 ";
    print "ok 7\n";
    close FOUR86;
}
else { print "not ok 7\n"; }

#--------------------------------------- test 8
if( open FOUR87 , ">487.prn" ){
    print FOUR87 $chip->form487, "                 ";
    print "ok 8\n";
    close FOUR87;
}
else { print "not ok 8\n"; }

#--------------------------------------- test 9
if( open FOUR1500 , ">1500.prn" ){
    print FOUR1500 $chip->form1500, "                 ";
    print "ok 9\n";
    close FOUR1500;
}
else { print "not ok 9\n"; }
#--------------------------------------- test 10
print $chip->reset eq pack('CC', 27,69) ? "ok 10" : "not ok 10", "\n";

#--------------------------------------- test 11
my @b = split( ' ', $chip->pcl_unpack( $chip->_Vert(8) ) );
my @c = (27,38,108,56,67);
my ($i,$ok ) = 0;
$| = 1;
#print "C\tB\n";
for( $i = 0; $i < @b ; $i++ )
{
	if( $c[$i] == $b[$i] ){ $ok++; }
#	print "$c[$i]\t$b[$i]\n";
}
print @b == $ok ? "ok 11" : "not ok 11", "\n";
