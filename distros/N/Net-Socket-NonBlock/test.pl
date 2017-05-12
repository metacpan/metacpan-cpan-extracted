# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;

$^W++;

use Test;
BEGIN { plan tests => 8 };
use Net::Socket::NonBlock;
print "module loaded..........................";
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $SockNest = Net::Socket::NonBlock->new(SilenceT => 10,
                                          #debug    => $^W,
                                          debug    => 0,
                                         )
	or die "Can not create socket nest: $@";


# Autoflush on
$| = 1;

my $IOerr = [];

my $Incoming = undef;

my $LocalAddr = 'localhost';

my $Server = $SockNest->Listen('LocalAddr'  => $LocalAddr,
                               'Proto'      => 'tcp',
                               'Accept'     => sub { $Incoming = $_[0]; return 1; },
                               'Listen'     => 10,
                               'MaxClients' => 1,
                               )
	or die "Could not create server: $@";


print "server created.........................";
ok(2);

my $Client = $SockNest->Connect(PeerAddr => $LocalAddr,
                                PeerPort => $SockNest->LocalPort($Server),
                                Proto    => 'tcp',)
	or die "Can not create client connection: $@";

print "client connection created..............";
ok(3);

my $Res = $SockNest->IO($IOerr);
#foreach (@{$IOerr}) { warn $_; };

$Incoming or die "Client connection was not picked up by server\n";

print "client connection picked up............";
ok(4);

my $SockCount = ($SockNest->NestProperties())->{'Sockets'};
($SockCount == 3)
	or die "Total number of open sockets is $SockCount but have to be 3\n";
print "sockets counted........................";
ok(5);

my $ServerStr = 'server '.time()."\r\n";
$SockNest->Puts($Incoming, $ServerStr);

my $tmpStr = '';
while (!length($tmpStr))
	{
	$Res = $SockNest->IO($IOerr);
	#foreach (@{$IOerr}) { warn $_; };
	$tmpStr = $SockNest->Gets($Client);
	if (!defined($tmpStr))
		{ die "Unexpected socket error: $@"; };
	};

if ($tmpStr ne $ServerStr)
	{ die sprintf("String \"%s\" expected from server but \"%s\" received\n", SafeStr($ServerStr), SafeStr($tmpStr)); };

print "data transferred from server to client.";
ok(6);

my $ClientStr = 'client '.time()."\r\n";
$SockNest->Puts($Client, $ClientStr);

$tmpStr = '';
while (!length($tmpStr))
	{
	$Res = $SockNest->IO($IOerr);
	#foreach (@{$IOerr}) { warn $_; };
	$tmpStr = $SockNest->Gets($Incoming);
	if (!defined($tmpStr))
		{ die "Unexpected socket error: $@"; };
	};

if ($tmpStr ne $ClientStr)
	{ die sprintf("String \"%s\" expected from server but \"%s\" received\n", SafeStr($ServerStr), SafeStr($tmpStr)); };

print "data transferred from client to server.";
ok(7);

$SockNest->Close($Client);
$SockNest->Close($Incoming);
$SockNest->Close($Server);

$Res = $SockNest->IO($IOerr);
#foreach (@{$IOerr}) { warn $_; };

$SockCount = ($SockNest->NestProperties())->{'Sockets'};
($SockCount == 0)
	or die "Total number of open sockets is $SockCount but have to be 0\n";
print "all sockets closed.....................";

ok(8);

print "All tests passed\n";
