# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 8 };
use Teradata::BTET qw(:all);
ok(1); # If we made it this far, we're ok.

#########################

$TDLOGON = $ENV{'TDLOGON'};
die ">>>> Please specify TDLOGON\n" unless $TDLOGON;

$VERBOSE = $ENV{'TEST_VERBOSE'};

print "connect......................";
$dbh = Teradata::BTET::connect($TDLOGON)
  or die "Could not connect";
is_ok(check_ec(), 2);

print "prepare......................";
$sth = $dbh->prepare("select * from dbc.dbcinfo")
  or die "Could not prepare";
is_ok(check_ec(), 3);

print "open,fetch,close.............";
$sth->open();
while ( @z = $sth->fetchrow_list()) {
   if ($VERBOSE) {
      print " data: @z\n";
   }
}
$sth->close();
is_ok(check_ec(), 4);

print "fetchrow_hash................";
$sth = $dbh->prepare("select 2+5 wise_men")
  or die "Could not prepare";
$sth->open();
while ( %z = $sth->fetchrow_hash ) {
   if ($VERBOSE) {
      foreach $k (keys %z) { print " key <$k> value <$z{$k}>\n"; }
   }
   is_ok($z{'wise_men'} == 7, 5);
}
$sth->close();

print "ANSI date....................";
$sth = $dbh->prepare("set session dateform=ansidate");
$sth->execute;
$sth = $dbh->prepare("select 1010911 (date)");
$sth->open;
$ansidate = $sth->fetchrow_list;
print " date: $ansidate\n" if $VERBOSE;
$sth->close;
is_ok($ansidate eq '2001-09-11', 6);

print "quiet errors.................";
$Teradata::BTET::msglevel = 0;
$sth = $dbh->prepare("select * from vanity.of_vanities")
  && $sth->close();
is_ok($errorcode == 3802, 7);

print "disconnect...................";
$dbh->disconnect;
is_ok(check_ec(), 8);


#--- Was it okay?
sub is_ok {
 my ($cond, $n) = @_;

 if ($cond) {
    print "ok $n\n";
 } else {
    print "not ok $n\n";
 }
}

#--- Check the Teradata error code.
sub check_ec {
 return (Teradata::BTET::errorcode == 0);
}
