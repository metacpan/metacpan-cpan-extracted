# This -*- perl -*- code tests the ::Dispatch class

# $Id: dispatch.t,v 1.6 2003/01/14 20:32:34 lem Exp $

use Queue::Dir;
use SMS::Handler;
use Net::SMPP 1.04;
use SMS::Handler::Dispatcher;

BEGIN {
    @cases = 
	(
	 [ ".HELLO\nbody0", '.HELLO', 'body0' ],
	 [ ".HELLO\n\nbody1", '.HELLO', "\nbody1" ],
	 [ ".HELLO  body2", '.HELLO', "body2" ],
	 [ ".HELLO  \nbody3", '.HELLO', "\nbody3" ],
	 );
};

use Test::More tests => 14 + 4 * @cases;

package MyPackage;
use Test::More;
use SMS::Handler;
use SMS::Handler::Dispatcher;

@ISA = qw(SMS::Handler::Dispatcher);

sub new
{
    my $class = shift;
    bless 
    {
	cmds =>
	{
	    HELLO	=> \&main::hello_cmd,
	    BYE		=> \&main::bye_cmd,
	},
    }, $class;
}

sub dispatch_error
{
    fail("dispatch_error: Something bad happened in the dispatch");
    SMS_CONTINUE;
}

package main;

our @Args = ();

sub hello_cmd 
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

    pass("in call to hello_cmd");

#    diag("Msg: $$r_msg");
#    diag("Body: $$r_body");

    my $msg = $$r_msg;
    my $bod = $$r_body;

    @Args = ($msg, $bod);

    $$r_msg =~ s/^\.HELLO\s*//;

    return 1;
}

sub bye_cmd 
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

    pass("in call to bye_cmd");

#    diag("Msg: $$r_msg");
#    diag("Body: $$r_body");

    my $msg = $$r_msg;
    my $bod = $$r_body;

    @Args = ($msg, $bod);

    $$r_msg =~ s/^\.BYE\s*(\S+\s+\S+)\s*//;

    return 1;
}

our @PDU_keys = ( qw(
		     source_addr_ton
		     source_addr_npi
		     source_addr
		     dest_addr_ton
		     dest_addr_npi
		     destination_addr
		     short_message)
		  );

sub _build_pdu {
    my $cmd = shift;
    my $self = new Net::SMPP::PDU;
    $self->$_(31415) for @PDU_keys;
    $self->short_message($cmd);
    return $self;
}

my $pdu = _build_pdu('no match');

my $test = new MyPackage;

ok(defined $test, "Creation of a simple object");
isa_ok($test, 'MyPackage');
isa_ok($test, 'SMS::Handler::Dispatcher');

is($test->handle($pdu), SMS_STOP |  SMS_DEQUEUE, "Proper return value");
ok(!@Argv, "->handle not invoked on incorrect SMS");

$pdu = _build_pdu('.HELLO');
is($test->handle($pdu), SMS_STOP |  SMS_DEQUEUE, "Proper return value");
is($Args[0], '.HELLO', "Proper command line");
is($Args[1], '', "Proper SMS body");

$pdu = _build_pdu('.HELLO .BYE 1 2  body');
is($test->handle($pdu), SMS_STOP |  SMS_DEQUEUE, "Proper return value");
is($Args[0], '.BYE 1 2', "Proper command line");
is($Args[1], 'body', "Proper SMS body");

my $idx = 0;

for my $c (@cases)
{
    $pdu = _build_pdu($c->[0]);
    is($test->handle($pdu), SMS_STOP |  SMS_DEQUEUE, 
       "$idx: Proper return value");
    is($Args[0], $c->[1], "$idx: Proper command line");
    is($Args[1], $c->[2], "$idx: Proper SMS body");
    ++ $idx;
}

