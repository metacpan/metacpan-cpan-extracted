# $Id: main.t,v 1.2 2001/12/13 00:42:55 mpeppler Exp $
#
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $^W=1; $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use Sybase::Simple;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print "$Sybase::CTlib::Version";
foreach (keys(%INC)) {
   print "$_ from $INC{$_}\n";
}

ct_callback(CS_SERVERMSG_CB, \&srv_cb);

# Find the passwd file:
@dirs = ('./.', './..', './../..', './../../..');
foreach (@dirs)
{
    if(-f "$_/PWD")
    {
	open(PWD, "$_/PWD") || die "$_/PWD is not readable: $!\n";
	while(<PWD>)
	{
	    chop;
	    s/^\s*//;
	    next if(/^\#/ || /^\s*$/);
	    ($l, $r) = split(/=/);
	    $Uid = $r if($l eq UID);
	    $Pwd = $r if($l eq PWD);
	    $Srv = $r if($l eq SRV);
	}
	close(PWD);
	last;
    }
}

$Srv = $ENV{DSQUERY} if $ENV{DSQUERY};
$Uid = $ENV{SYBASE_USER} if $ENV{SYBASE_USER};
$Pwd = $ENV{SYBASE_PWD} if $ENV{SYBASE_PWD};

$dbh = new Sybase::Simple $Uid, $Pwd, $Srv;
$dbh and print "ok 2\n"
    or print "not ok 2\n";
$date = $dbh->Scalar("select getdate()");
$date and print "ok 3\n"
    or print "not ok 3\n";
print "$date\n";

$row = $dbh->HashRow("select * from sysusers");
$row and print "ok 4\n"
    or print "not ok 4\n";
{ local $^W = 0;
  foreach (keys(%$row)) {
      print "$_: $row->{$_}\n";
  }
}

$rows = $dbh->ArrayOfHash("select * from sysusers");
$rows and print "ok 5\n"
    or print "not ok 5\n";
foreach (@$rows) {
    print "Name: $_->{name}\tUid: $_->{uid}\n";
}

$data = $dbh->HashOfScalar("select * from sysusers", 'uid', 'name');
$data and print "ok 6\n"
    or print "not ok 6\n";
foreach (keys(%$data)) {
    print "$_: $data->{$_}\n";
}

$data = $dbh->HashOfHash("select * from sysusers", 'uid');
$data and print "ok 7\n"
    or print "not ok 7\n";
foreach (keys(%$data)) {
    print "$_: $data->{$_}->{name}\n";
}

$data = $dbh->HashIter("select * from sysusers", 'uid');
$data and print "ok 8\n"
    or print "not ok 8\n";
while($row = $data->next) {
    print "$row->{uid}: $row->{name}\n";
}

$data = $dbh->ExecSql("create table #ttt ( a char(10), b int)");
$data and print "ok 9\n"
    or print "not ok 9\n";
$data = $dbh->ExecSql("
insert #ttt values('michael', 1)
insert #ttt values('george', 2)
insert #ttt values('foobar', 3)
");
$data and print "ok 10\n"
    or print "not ok 10\n";
$data = $dbh->Scalar("select count(*) from #ttt");
$data == 3 and print "ok 11\n"
    or print "not ok 11\n";


sub srv_cb {
    my($dbh, $number, $severity, $state, $line, $server, $proc, $msg)
	= @_;

    local $^W = 0;

    print "@_\n";
}
