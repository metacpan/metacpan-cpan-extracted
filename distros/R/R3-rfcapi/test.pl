# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use R3::rfcapi;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

&get_logon;
$conn=&R3::rfcapi::r3_new_conn($client,
	$usr, $passwd, "E", $host, $sysnr, "", "", 0);
if ($conn)
{
	print "ok 2\n";
	if ($pre4 =~ m/^y.*/i)
	{
		print "R/3 < 40A\n";
		&R3::rfcapi::r3_set_pre4($conn);
	}
	&test_3_4;
}
else
{
	print "not ok 2 - are Host and Sysnr correct?\n";
	print "skipping test 3 and 4\n";
}

sub test_3_4
{
	$func=&R3::rfcapi::r3_new_func($conn, "RFC_GET_FUNCTION_INTERFACE");
	if ($func)
	{
		print "ok 3\n";
		&R3::rfcapi::r3_del_func($func);
	}
	else
	{
		print "not ok 3 - are R/3 Client, User and Passwd correct?\n";
	}
	$itab=&R3::rfcapi::r3_new_itab($conn,"RFC_FUNINT");
	if ($itab)
	{
		print "ok 4\n";
		&R3::rfcapi::r3_del_itab($itab);
	}
	else
	{
		print "not ok 4 \n";
	}
	&R3::rfcapi::r3_del_conn($conn) if $conn;
}

sub get_logon
{
	$|=1;
	print "Please provide logon information for test connection to R/3: \n";
	print "Client: "; $client=<>; chop $client;
	print "User: "; $usr=<>; chop $usr;
	print "Passwd (WARNING! PASSWD IS ECHOED): "; $passwd=<>; chop $passwd;
	print "Host: "; $host=<>; chop $host;
	print "Sysnr: "; $sysnr=<>; chop $sysnr;
	print "R/3 release on $host < 40A (yes/no)? : "; $pre4=<>; chop $pre4;
}
