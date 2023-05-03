# SNMPAgent.pm
#
# Object for handling SNMP requests as per draft-ietf-radius-servmib-04.txt
#
# Author: Mike McCauley (mikem@open.com.au)
# Copyright (C) 1997 Open System Consultants
# $Id: SNMPAgent.pm,v 1.2 1999-02-21 22:26:49 leinen Exp $

use SNMP_Session "0.68";
use SNMP_util;
use Socket;

$port = SNMP_Session::standard_udp_port;
$session = SNMP_Session->open('0.0.0.0', '', 
			      $port, undef, $port);


while (1)
{
    &handle_socket_read();
}

#####################################################################
# This function is called whenever there is a packet waiting to
# be read from the SNMP port
sub handle_socket_read
{
    my ($fileno) = @_;

    my ($request, $iaddr, $port) = $session->receive_request();
    if (defined $request)
    {
	my ($type, $requestid, $bindings, $community) 
	    = $session->decode_request($request);
	
	print "SNMPAgent: received request $type, $requestid, $community\n";

	my ($error, $errorstatus, $errorindex);
	$errorstatus = $errorindex = 0;

	# Check the community
	if ($community ne 'public')
	{
	    print "SNMPAgent: wrong community: $community. Ignored\n";
	    return;
	}
	my $index = 0;

	my @results;
	binding: while (!$errorstatus && $bindings ne '') 
	{
	    my $binding;
	    ($binding, $bindings) = BER::decode_sequence($bindings);
	    while (!$errorstatus && $binding ne '')
	    {
		($b, $binding) = BER::decode_sequence($binding);
		$index++;
		if ($type == SNMP_Session::get_request)
		{
		    # SAMPLE code only:
		    my ($oid) = BER::decode_oid($b);  # Binary oid
		    my $poid = BER::pretty_oid($oid);
		    print "get request for $poid\n";
		    my $value = BER::encode_int(12345);
		    push(@results, BER::encode_sequence($oid, $value));
		}
		elsif ($type == SNMP_Session::getnext_request)
		{
		    # SAMPLE code only:
		    my ($oid) = BER::decode_oid($b);  # Binary oid
		    my $poid = BER::pretty_oid($oid);
		    print "getnext request for $poid\n";

		    # fake up the next oid by just incrementing
		    @fromoid = split(/\./, $poid);
		    $fromoid[-1]++;
		    print "changed to @fromoid\n";
		    $oid = BER::encode_oid(@fromoid);
		    my $value = BER::encode_int(12345);
		    push(@results, BER::encode_sequence($oid, $value));
		}
		elsif ($type == SNMP_Session::set_request)
		{
		    # SAMPLE code only:
		    my ($oid, $value) = BER::decode_by_template($b, "%O%@");
		    my $poid = BER::pretty_oid($oid);
		    ($value) = BER::decode_int($value);
		    print "set request for $poid to $value\n";
		    $value = BER::encode_int($value);
		    push(@results, BER::encode_sequence($oid, $value));

		}
		else
		{
		    warn "SNMPAgent: error decoding request: " . $BER::errmsg;
		    return;
		}
		if ($errorstatus)
		{
		    $errorindex = $index;
		    last binding;
		}
	    }
	}

	# OK we've got everything they asked for, so return it
	$request = BER::encode_tagged_sequence(SNMP_Session::get_response,
					     BER::encode_int($requestid),
					     BER::encode_int($errorstatus), 
					     BER::encode_int($errorindex),
					     BER::encode_sequence(@results))
	    || warn "SNMPAgent: error encoding reply: " . $BER::errmsg;

	$session->{remote_addr} = Socket::pack_sockaddr_in($port, $iaddr);
	$session->{community} = $community;
	$request = $session->wrap_request($request);
	# tell the session where to send the reply to
	$session->send_query($request)
	    || warn "SNMPAgent: error sending reply: $!";
    }
    else
    {
	warn "SNMPAgent: receive_request failed: $!";
    }
}

1;
