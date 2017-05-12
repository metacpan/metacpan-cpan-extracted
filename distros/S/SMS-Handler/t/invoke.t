# This -*- perl -*- code tests the Invoke magic

# $Id: invoke.t,v 1.2 2003/01/14 20:32:35 lem Exp $

use SMS::Handler;
use Net::SMPP 1.04;
use SMS::Handler::Invoke;

BEGIN {
    our @PDU_keys = ( qw(
			 source_addr_ton
			 source_addr_npi
			 source_addr
			 dest_addr_ton
			 dest_addr_npi
			 destination_addr
			 short_message)
		      );
};

use Test::More tests => 3 + @PDU_keys;

sub _build_pdu {
    my $pdu = new Net::SMPP::PDU;
    $pdu->$_(31415) for @PDU_keys;
    return $pdu;
}

my $pdu = _build_pdu;

my $h = new SMS::Handler::Invoke sub 
{ 
    my $pdu = shift;
    ok(1, "Method invoked");
    $pdu->$_(555) for @PDU_keys;
    return $$;
};

ok(defined $h, "Creation of a simple object");

my $ret = $h->handle($pdu);
is($ret, $$, "Proper return value from the method");
is($pdu->$_, 555, "Changed value for $_") for @PDU_keys;
