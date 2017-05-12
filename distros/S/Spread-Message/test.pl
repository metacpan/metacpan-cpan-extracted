#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

my $name   = "$$";

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 8 };

print "=" x 10, "\n" x 2;
print "use Spread::Message;\n";
use Spread::Message;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

print "=" x 10, "\n" x 2;
print "Creating a new Spread::Message\n";
my $mbox = Spread::Message->new(
		spread_name => '4803@localhost',
        name  => $name,
        group => ['polling-changes','polling-ctl'],
        debug => 0,
);
if(defined $mbox)
{
	ok(1);
}
else
{
	print "Can't open a Spread mailbox\n";
	print "Spread must be running on 4803\@localhost\n";
	ok(0);
}

print "=" x 10, "\n" x 2;
print "Connecting and rx()\n";
if($mbox->connect)
{
	ok(1);
	$mbox->rx(2); $mbox->rx(2);
}
else
{
	ok(0);
}

print "=" x 10, "\n" x 2;
print "Leaving Joined groups\n";
print "Joined :", join(",",$mbox->joined), " \n";
$mbox->leave('polling-changes');
print "Joined :", join(",",$mbox->joined), " \n";
$mbox->rx(2,"a test");

if($mbox->new_msg)
{
	ok(1);
}
else
{
	ok(0);
}


print "=" x 10, "\n" x 2;
print "Joining testgrp\n";
if($mbox->join("testgrp"))
{
	ok(1);
	print "Joined :", join(",",$mbox->joined), " \n";
	$mbox->rx(2); $mbox->rx(2);
}
else
{
	ok(0);
}

print "=" x 10, "\n" x 2;
print "Disconnect and connect\n";

$mbox->disconnect;
$mbox->connect;
$mbox->rx(3); $mbox->rx(3);
print "=" x 10, "\n" x 2;
print "Sending message to my self\n";

$mbox->send($mbox->me,"aaa" x 20);
$mbox->rx();
my $msg = $mbox->msg();
if($msg eq 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
{
	ok(1);
}
else
{
	ok(0);
}

print "=" x 10, "\n" x 2;
print "Sending binary message to my self\n";

my $txt = pack("sx2l",12,34);
$mbox->send($mbox->me,$txt);
$mbox->get();
my($a,$b) = unpack("sx2l",$mbox->msg());
if($a == 12 && $b == 34)
{
	ok(1);
}
else
{
	ok(0);
}

# Now lets send a complicated large Perl hash to ourselves
print "=" x 10, "\n" x 2;
print "Sending large complicated Perl Hash to my self\n";
my %hash = (
	'name' => 'Spread::Message',
	'arr'  => [('Spread::Message') x 10000],
	'hash'  => { ('x' , 'y') },
);

$mbox->sends($mbox->me,\%hash);
$mbox->get();
$msg = $mbox->decode();
if($msg->{'name'} eq "Spread::Message")
{
	ok(1);
}
else
{
	ok(0);
}
print "=" x 10, "\n" x 2;

exit;

