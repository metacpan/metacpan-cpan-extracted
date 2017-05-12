# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Number::Spell;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my %tests =(
        '1'     =>      'one',
        '12'    =>      'twelve',
        '523'   =>      'five hundred twenty three',
        '1542'  =>      'one thousand five hundred forty two',
        '5000'  =>      'five thousand',
        '24538000'      =>      'twenty four million five hundred thirty eight thousand',
        '20000000000'   =>      'twenty billion');

my %tests_eu =(
        '24538000'      =>      'twenty four million five hundred thirty eight thousand',
        '20000000000'   =>      'twenty thousand million',
        '9512023398683872'      =>      'nine thousand five hundred twelve billion twenty three thousand three hundred ninty eight million six hundred eighty three thousand eight hundred seventy two'
);

my $c=2;
my $k;
foreach $k(keys %tests){
  my $r=spell_number($k);
  if($r eq $tests{$k}){
    print "ok $c\n";
  }else{
    print "not ok $c\n";
    print "   $k spelled to\n";
    print "   \"$r\" should have spelled to\n";
    print "   \"$tests{$k}\"\n";    
  }
  $c++;
}


foreach (keys %tests_eu){
  
  my $r=spell_number($k,Format=>'eu');
  if($r eq $tests_eu{$k}){
    print "ok $c\n";
  }else{
    print "not ok $c\n";
    print "   $k (eu) spelled to\n";
    print "   \"$r\" should have spelled to\n";
    print "   \"$tests{$k}\"\n";    
  }
  $c++;
}

