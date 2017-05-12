# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'


use Test::More tests => 19;
BEGIN { use_ok('Script::Toolbox') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

##############################################################################

$F = Script::Toolbox->new();
##############################################################################
############################### TEST 2 #####################################

$n = $F->Now();
$nn= $F->Now({format=>'%Y%m%d%H%M'});
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
ok( $n->{sec}   == $sec );      #2
ok( $n->{min}   == $min );      #3
ok( $n->{hour}  == $hour);      #4
ok( $n->{mday}  == $mday);      #5
ok( $n->{mon}   == $mon+1);     #6
ok( $n->{year}  == $year+1900); #7
ok( $n->{wday}  == $wday);      #8
ok( $n->{yday}  == $yday);      #9
ok( $n->{isdst} == $isdst);     #10

$str = sprintf "%.4d%.2d%.2d%.2d%.2d", $year+1900,$mon+1,$mday,$hour,$min;
ok( $nn eq $str); #11

$n = $F->Now({offset=>60});
$nn= $F->Now({format=>'%Y%m%d%H%M', offset=>60});
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
ok( $n->{min}   == $min+1 );      #12

$str = sprintf "%.4d%.2d%.2d%.2d%.2d", $year+1900,$mon+1,$mday,$hour,$min+1;
ok( $nn eq $str); #13

$n = $F->Now({diff=>time()-3600});
ok( $n->{seconds} == 3600 ); #14
ok( $n->{minutes} == 60   ); #15
ok( $n->{hours}   == 1    ); #16
ok( $n->{days}  > 0.0416666 && $n->{days} < 0.0416667 ); #17

$n = $F->Now({diff=>time()-(25*3600+61)});
ok( $n->{DHMS} eq "1d 01:01:01"); #18

$t = localtime time()-(25*3600+61);
$n = $F->Now({diff=>"$t"});
ok( $n->{DHMS} eq "1d 01:01:01"); #18
