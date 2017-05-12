# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Regex-Number-GtLt.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use lib qw!Regex-Number-GtLt/lib!;

use Test::More tests => 3;
BEGIN { use_ok('Regex::Number::GtLt') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $ok=1;
for my $i(1..1000){
  my $gre = Regex::Number::GtLt::rxgreater(4,$i);
  for (map sprintf('%04d',$_), 0 .. $i){
    $ok = 0 if /$gre/;
  }
  for (map sprintf('%04d',$_), $i+1 .. 1000){
    $ok = 0 if !/$gre/;
  }
}
ok($ok == 1,'rxgreater');


$ok=1;
for my $i(1..1000){
  my $lre = Regex::Number::GtLt::rxsmaller(4,$i);
  for (map sprintf('%04d',$_), 0 .. $i-1){
    $ok = 0 if !/$lre/;
  }
  for (map sprintf('%04d',$_), $i+1 .. 1000){
    $ok = 0 if /$lre/;
  }
}
ok($ok == 1,'rxsmaller');

