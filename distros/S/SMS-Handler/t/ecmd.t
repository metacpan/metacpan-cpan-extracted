# This -*- perl -*- code tests the processing of some SMS commands

# $Id: ecmd.t,v 1.8 2003/01/14 20:32:34 lem Exp $

BEGIN {

				# These messages should be understood

				# These tests cannot be made without
				# a POP server to authenticate the
				# given user.

    our @al_good = (
#		    [ qq{.ALIAS foo bar}, 'foo', 'bar' ],
#		    [ qq{.ALIAS Diddle doodle}, 'diddle', 'doodle' ],
		    );

    our @al_dele = (
#		    [ qq{.ALIAS Foo}, 'foo' ],
#		    [ qq{.ALIAS Diddle}, 'diddle' ],
		    );

    our @ac_good = ([ qq{.ACCOUNT foo bar\nThis crap should be ignored}, 
		      'foo', 'bar' ],
		    [ qq{.ACCOUNT foo bar  This crap should be ignored}, 
		      'foo', 'bar' ],
		    [ qq{.ACCOUNT baz diddle}, 'baz', 'diddle' ],
		    [ qq{.ACCOUNT yabba dabba\n}, 'yabba', 'dabba' ],
		    [ qq{.AC foo bar  This crap should be ignored}, 
		      'foo', 'bar' ],
		    [ qq{.ACC baz diddle}, 'baz', 'diddle' ],
		    [ qq{.ACCO yabba dabba\n}, 'yabba', 'dabba' ],
		    );

				# These are to be ignored

    our @bad = (qq{.ACCOUNT},
		qq{.ACCOUNT fiddle},
		qq{.ACC},
		qq{.AC fiddle},
		);
};

use Test::More tests => 1 + 2*@al_dele + 2*@al_good + 18*@ac_good + 3 * @bad;
use SMS::Handler::Email;
use Net::SMPP 1.04;
use SMS::Handler;
use Storable qw(fd_retrieve);
use Queue::Dir;

END {
    rmdir "test$$";
};

mkdir "test$$";

my $q = new Queue::Dir
    (
     -paths => [ "test$$" ],
     -promiscuous => 1,
     );

sub _build_pdu ($)
{
    return bless 
    {
	dest_addr_ton		=> 6,
	dest_addr_npi		=> 6,
	destination_addr	=> 6,
	source_addr_ton		=> 5,
	source_addr_npi		=> 5,
	source_addr		=> 5,
	short_message		=> shift,
    }, 'Net::SMPP::PDU';
}

my %State = ();

my $h = new SMS::Handler::Email 
    (
     queue => $q,
     state => \%State,
     secret => 'All your base are belong to us',
     addr => '6.6.6',
     pop => 'pop.foo.com',
     smtp => 'smtp.foo.com',
     );

isa_ok($h, 'SMS::Handler::Email');

my $pdu;
my $cpdu;
my $res;
my $fh;

for my $m (@al_good)
{
    $pdu = _build_pdu qq{$m->[0]};

    $res = $h->handle($pdu);
    
    is($res, SMS_STOP | SMS_DEQUEUE, $m->[0] . ' understood');
    is($State{'5.5.5'}->{alias}->{$m->[1]}, $m->[2], 
       'alias entry added to %State');
}

for my $m (@al_dele)
{
    $pdu = _build_pdu qq{$m->[0]};

    $res = $h->handle($pdu);
    
    is($res, SMS_STOP | SMS_DEQUEUE, $m->[0] . ' understood');
    ok(!defined($State{'5.5.5'}->{alias}->{$m->[1]}), 'alias entry deleted');
}

for my $m (@ac_good)
{

    $pdu = _build_pdu qq{$m->[0]};

    $res = $h->handle($pdu);
    
    is($res, SMS_STOP | SMS_DEQUEUE, $m->[0] . ' understood');
    is($State{'5.5.5'}->{login}, $m->[1], 'Login entry added to %State');
    is($h->_crypt($State{'5.5.5'}->{passwd}), $m->[2], 'Proper pwd stored');

				# Fetch and verify the command
				# we just produced

    $fh = $q->visit || $q->visit;
    isa_ok($fh, "IO::File");

    $cpdu = fd_retrieve($fh);
    isa_ok($cpdu, 'Net::SMPP::PDU');

    is($cpdu->short_message, $m->[1] . " ok", 'Proper command result');
    $fh->close;
    $q->done;

    delete $State{'5.5.5'};

    $pdu = _build_pdu qq{(5551212)$m->[0]};

    $res = $h->handle($pdu);

    is($res, SMS_STOP | SMS_DEQUEUE, $m->[0] . ' understood');
    is($State{'5.5.5'}->{login}, $m->[1], 'Login entry added to %State');
    is($h->_crypt($State{'5.5.5'}->{passwd}), $m->[2], 'Proper pwd stored');

    $fh = $q->visit || $q->visit;
    isa_ok($fh, "IO::File");

    $cpdu = fd_retrieve($fh);
    isa_ok($cpdu, 'Net::SMPP::PDU');

    is($cpdu->short_message, $m->[1] . " ok", 'Proper command result');
    $fh->close;
    $q->done;

    $pdu = _build_pdu qq{(5551212) $m->[0]};

    $res = $h->handle($pdu);

    is($res, SMS_STOP | SMS_DEQUEUE, $m->[0] . ' understood');
    is($State{'5.5.5'}->{login}, $m->[1], 'Login entry added to %State');
    is($h->_crypt($State{'5.5.5'}->{passwd}), $m->[2], 'Proper pwd stored');

    $fh = $q->visit || $q->visit;
    isa_ok($fh, "IO::File");

    $cpdu = fd_retrieve($fh);
    isa_ok($cpdu, 'Net::SMPP::PDU');

    is($cpdu->short_message, $m->[1] . " ok", 'Proper command result');
    $fh->close;
    $q->done;

}

for my $m (@bad)
{
    $pdu = _build_pdu qq{$m};
    $res = $h->handle($pdu);
    is($res, SMS_STOP | SMS_DEQUEUE, "$m not understood");

    my $fh = $q->visit || $q->visit;

    $cpdu = fd_retrieve($fh);
    isa_ok($cpdu, 'Net::SMPP::PDU');
    ok($cpdu->short_message =~ /error/i, "error message");
#    warn "# ", $cpdu->short_message, "\n";
    $q->done;
}
