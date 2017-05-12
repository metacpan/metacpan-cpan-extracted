#!/usr/bin/perl

use strict;
use warnings;
use Socket;
use Socket qw(IPPROTO_TCP TCP_NODELAY);
use IO::Handle;
use Data::Dumper qw(Dumper);
$Data::Dumper::Quotekeys = 0;

our $debug =  2;

use Net::LDAP::Gateway;
use Net::LDAP::Gateway::Constant qw(:error);

use Net::LDAP::ASN qw(LDAPRequest LDAPResponse);

sub hexdump {
    no warnings qw(uninitialized);
    my $data = shift;
    while ($data =~ /(.{1,16})/smg) {
	my $line=$1;
	my @c= (( map { sprintf "%02x",$_ } unpack('C*', $line)),
		(("  ") x 32))[0..15];
	$line=~s/(.)/ my $c=$1; unpack("c",$c)>=32 ? $c : '.' /egms;
 	local $\;
	print join(" ", @c, '|', $line), "\n";
    }
}

sub unber {
    # return;
    return unless $debug >= 2;
    my $name = shift;
    my $data = shift;
    printf "unber %s (%d bytes)\n", $name, length $data;
    open my $unber, '|-', 'unber', '-' or warn "unable to unber";
    print $unber $data;
    close $unber;
    print "unber end\n";
}

use constant PORT => 2389;

$| = 1;

socket(my $listener, AF_INET, SOCK_STREAM, getprotobyname('tcp'))
    or die "unable to create listener: $!";

setsockopt($listener, SOL_SOCKET, SO_REUSEADDR, 1);
bind($listener, sockaddr_in(PORT, INADDR_ANY)) or die "unable to bind listener: $!";
listen($listener, 5);

while(1) {
    print "waiting for connections...\n";
    my $remote_addr = accept(my $conn, $listener) or next;
    # if (!fork) {
	my ($port, $ip) = sockaddr_in($remote_addr);
	printf "connection from %s:%d\n", inet_ntoa($ip), $port;
	setsockopt($conn, IPPROTO_TCP, TCP_NODELAY, 1);
	my $n = 0;
	my $buffer = '';
	my $msg_len;
	while (1) {
	    printf "buffer length: %d\n", length $buffer if $debug;
	    my $bytes = sysread($conn, $buffer, 16*1024, length $buffer);
	    printf "%s bytes read\n", (defined $bytes ? $bytes : 'undef') if $debug;
	    if ($bytes) {
		if (!defined $msg_len) {
		    unber buffer => $buffer if $debug;
		    ($msg_len, my @more) = ldap_peek_message($buffer);
		    print "peek message more:\n", Dumper \@more;
		}
		if (defined $msg_len) {
		    printf "msg_len: %d, buffer len: %d\n", $msg_len, length $buffer if $debug;
		    if (length $buffer >= $msg_len) {
			# my $msg = substr($buffer, 0, $msg_len, "");
			undef $msg_len;
			if ($debug) {
			    unber msg => $buffer;
			    hexdump $buffer;
			    my $decoded = $LDAPRequest->decode($buffer);
			    print Dumper($decoded);
			}
			my @req = ldap_shift_message($buffer);
			if ($debug) {
			    print Dumper \@req;
			    my $repack = ldap_pack_message_ref(@req);
			    unber repack => $repack;
			}
			my ($msgid, $op) = @req;
			$n++;
			if ($op == 0) {
			    print "replying to Bind request\n" if $debug;
			    my $response = ldap_pack_bind_response($msgid);
			    if ($debug) {
				printf "response (%d bytes):\n", length $response;
				unber response => $response;
			    }
			    syswrite($conn, $response);
			    print Dumper [ldap_shift_message($response)] if $debug;
			}
			elsif ($op == 3) {
			    # print ".";
			    my $search = $req[2];
			    print "replying to Search request\n" if $debug;
			    for (1..1) {
				my $resp1 = ldap_pack_search_entry_response($msgid,
									    "cn=pepe," . $search->{base_dn},
									    inzone => 'true',
									    hzloc => ['yes', 'yes', 'yes']);
				if ($debug) {
				    printf "response 1 (%d bytes):\n", length $resp1;
				    unber response1 => $resp1;
				}
				syswrite($conn, $resp1);
				print Dumper [ldap_shift_message($resp1)] if $debug;

				my $resp2 = ldap_pack_search_entry_response_ref($msgid,
										{ dn => 'cn=paco,' . $search->{base_dn},
										  inzone => 'false',
										  hzloc => ['may', 'be'] });
				if ($debug) {
				    printf "response 2 (%d bytes):\n", length $resp2;
				    unber response2 => $resp2;
				    hexdump($resp2);
				}
				syswrite($conn, $resp2);
				print Dumper [ldap_shift_message($resp2)] if $debug;
			    }
			    my $response = ldap_pack_search_done_response($msgid);
			    if ($debug) {
				printf "response (%d bytes):\n", length $response;
				unber response => $response;
			    }
			    syswrite($conn, $response);
			    print Dumper [ldap_shift_message($response)] if $debug;
			}
			elsif ($op == 6) {
			    print "replying to Modify request\n" if $debug;
			    my $response = ldap_pack_modify_response($msgid);
			    if ($debug) {
				printf "response (%d bytes):\n", length $response;
				unber response => $response;
			    }
			    syswrite($conn, $response);
			    print Dumper [ldap_shift_message($response)] if $debug;
			}
			elsif ($op == 8) {
			    print "replying to Add request\n" if $debug;
			    my $response = ldap_pack_add_response($msgid);
			    if ($debug) {
				printf "response (%d bytes):\n", length $response;
				unber response => $response;
			    }
			    syswrite($conn, $response);
			    print Dumper [ldap_shift_message($response)] if $debug;
			}

			elsif ($op == 10) {
			    print "replying to Delete request\n" if $debug;
			    my $response = ldap_pack_delete_response($msgid);
			    if ($debug) {
				printf "response (%d bytes):\n", length $response;
				unber response => $response;
			    }
			    syswrite($conn, $response);
			    print Dumper [ldap_shift_message($response)] if $debug;
			}
			elsif ($op == 12) {
			    print "replying to Modify request\n" if $debug;
			    my $response = ldap_pack_modify_dn_response($msgid);
			    if ($debug) {
				printf "response (%d bytes):\n", length $response;
				unber response => $response;
			    }
			    syswrite($conn, $response);
			    print Dumper [ldap_shift_message($response)] if $debug;
			}
			elsif ($op == 14) {
			    print "replying to Compare request\n" if $debug;
			    my $response = ldap_pack_compare_response($msgid, LDAP_COMPARE_TRUE);
			    if ($debug) {
				printf "response (%d bytes):\n", length $response;
				unber response => $response;
			    }
			    syswrite($conn, $response);
			    print Dumper [ldap_shift_message($response)] if $debug;
			}
		    }
		}
	    }
	    else {
		print "connection closed by remote host n: $n\n";
		last;
	    }
	}
    # exit;
    # }
}
