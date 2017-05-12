# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use TUXEDO;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
my $fldid = FML32Buffer->mkfldid( TUXEDO::FLD_FML32, 123 );
print "The fldid for a FLD_FML32 of num 123 is $fldid\n";

my $tuxclient = TuxedoClient->new();
$tuxclient->attributes->usrname("fred");
$tuxclient->attributes->cltname("perl");
print "Hit enter to logon..\n";
$line = <STDIN>;
$rval = $tuxclient->logon;
if ( $rval == -1 )
{
	$errmsg = TUXEDO::tuxerrormsg();
	print "$errmsg\n";
	exit(0);
}

my $fml32 = FML32Buffer->new(100);
$fml32->AddField("TA_CLASS", "T_CLIENT");
$fml32->AddField("TA_OPERATION", "GET");

$tuxclient->call(".TMIB",$fml32,$fml32,0);
$clientid = $fml32->GetField("TA_CLIENTID",0);
print "Successfully logged on.  Client id = $clientid\n";

print "Hit enter to logoff..\n";
$line = <STDIN>;
$rval = $tuxclient->logoff;
exit(0);

