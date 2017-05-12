#!/usr/bin/perl

use strict;
use warnings;

use Net::LDAP::ASN qw(LDAPRequest LDAPResponse);
use Net::LDAP::Gateway;
use Data::Dumper;

my $debug =  2;

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

my @request = ( [ bindRequest =>
		  { version => 3,
		    name => 'cn=foo, o=internet',
		    authentication =>
		    { simple => 'password' },
		  }
		],
		[ bindRequest =>
		  { version => 3,
		    name => 'cn=foo, o=internet',
		    authentication =>
		    { sasl =>
		      { mechanism => 'foo',
			credentials => 'credentials data'
		      }
		    }
		  }
		]
	      );

my @response = ( [ protocolOp =>
		   { bindResponse =>
		     { resultCode => 7,
		       matchedDN => "foo",
		       errorMessage => "Bar",
		       serverSaslCreds => "vito",
		       referral =>
		       [ 'done',
			 'max'
		       ]
		     }
		   },
		 ]
	       );

for my $msg (@request) {
    my $pack = $LDAPRequest->encode(@$msg, messageID => 13);
    printf "error: %s\n", $LDAPRequest->error unless defined $pack;
    unber request => $pack;
    hexdump $pack;
    print Dumper [ldap_shift_message $pack];
}

for my $msg (@response) {
    my $pack = $LDAPResponse->encode(@$msg, messageID => 13);
    printf "error: %s\n", $LDAPResponse->error unless defined $pack;
    unber response => $pack;
    hexdump $pack;
    print Dumper [ldap_shift_message $pack];
}
