# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..30\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::KeyboardDistance qw(:all);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use Getopt::Std;
our $opt_d;
getopts('d');
my $debug = $opt_d || undef;

my $test = 2;
my @tests = (
  [qw(SHACKLEFORD SHACKELFORD),1],
  [qw(DUNNINGHAM CUNNINGHAM),1],
  [qw(NICHELSON NICHULSON),1],
  [qw(JONES JOHNSON),0],
  [qw(MASSEY MASSIE),1],
  [qw(ABROMS ABRAMS),1],
  [qw(HARDIN MARTINEZ),0],
  [qw(ITMAN SMITH),0],

  [qw(JERALDINE GERALDINE),1],
  [qw(MARHTA MARTHA),1],
  [qw(MICHELLE MICHAEL),0],
  [qw(JULIES JULIUS),1],
  [qw(YANYA TONYA),1],
  [qw(DWAYNE DUANE),0],
  [qw(SEAN SUSAN),0],
  [qw(JON JOHN),1],
  [qw(JON JAN),0],

  [qw(BROOKHAVEN BRROKHAVEN),1],
  [q("BROOK HALLOW"),q("BROOK HLLW"),1],
  [q(HALLOW),q(HLLW),1],
  [qw(DECATUR DECATIR),1],
  [qw(FITZRUREITER FITZENREITER),1],
  [qw(HIGBEE HIGHEE),1],
  [qw(HIGBEE HIGVEE),1],
  [qw(LACURA LOCURA),1],
  [qw(IOWA IONA),0],
  [qw(1ST IST),1],
  [qw(1ST QST),1],
  [qw(MATCH MATCH),1],
);

#$debug = 1;
if($debug) {
  print "max qwerty: ",$qwerty_max_distance,"\n";
  print "max dvorak: ",$dvorak_max_distance,"\n";
}

my $thresh = 0.875;
print "qwerty_keyboard_distance vs dvorak_keyboard_distance\n" if($debug);
foreach my $ar (@tests) {
  my($x,$y) = @{$ar}[0,1];
  my $qdst = qwerty_keyboard_distance_match($x,$y);
  my $ddst = dvorak_keyboard_distance_match($x,$y);
  $debug && printf("% -35s: q:%%%3.2f%s  d:%%%3.2f%s\n",
    "($x,$y)",
    100*$qdst,
    $qdst >= $thresh ? 'y' : 'n',
    100*$ddst,
    $ddst >= $thresh ? 'y' : 'n',
    );
  unless($debug) {
    print "ok $test\n" if $qdst && $ddst;
    print "not ok $test\n" unless $qdst && $ddst;
  }
  ++$test;
}


