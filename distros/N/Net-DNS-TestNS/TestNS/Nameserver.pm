package Net::DNS::TestNS::Nameserver;



use strict;

use Data::Dumper;
use Net::DNS::TestNS::Packet;
use Net::DNS::Nameserver;

use vars qw(
	    @ISA 
	    $VERSION
	    );


$VERSION=(qw$LastChangedRevision: 323 $)[1];



@ISA     = qw(Net::DNS::Nameserver);


sub make_reply {
    my ($self, $query, $peerhost) = @_;
    print "Using the customized make_reply\n" if $self->{"Verbose"};	
    my $reply;
    my $transporthash;
    

    if (not $query) {
	print "ERROR: invalid packet\n" if $self->{"Verbose"};
	$reply = Net::DNS::Packet->new("", "ANY", "ANY");
	$reply->header->rcode("FORMERR");
	return $reply;
    }
    
    
    my $qr = ($query->question)[0];
    my $qname  = $qr ? $qr->qname  : "";
    my $qclass = $qr ? $qr->qclass : "ANY";
    my $qtype  = $qr ? $qr->qtype  : "ANY";
    
    $reply = Net::DNS::TestNS::Packet->new($qname, $qtype, $qclass);
    

    
    if ($query->header->opcode eq "QUERY") {
	if ($query->header->qdcount == 1) {
	    print "query ", $query->header->id,
	    ": ($qname, $qclass, $qtype)..." if $self->{"Verbose"};
	    
	    my ($rcode, $ans, $auth, $add);
	    
	    ($rcode, $ans, $auth, $add, $transporthash) =
		&{$self->{"ReplyHandler"}}($qname, $qclass, $qtype, $peerhost, $query);
	    
	    print "$rcode\n" if $self->{"Verbose"};
	    
	    $reply->header->rcode($rcode);


	    if ($transporthash->{'raw'}){
		print "Raw data in Net::DNS::TestNS::Nameserver\n"if $self->{"Verbose"}; 
		$reply->{"rawhack"}=1; # Used by the Net::DNS::TestNS::Pakcet::data bethod
		my$packetdata=$reply->header->data().$transporthash->{'raw'};
		$reply->{"data"}=$packetdata;
	    }else{	    
		$reply->push("answer", @$ans)  if $ans;
		$reply->push("authority",  @$auth) if $auth;
		$reply->push("additional", @$add)  if $add;
	    }
	} else {
	    print "ERROR: qdcount ", $query->header->qdcount,
	    "unsupported\n" if $self->{"Verbose"};
	    $reply->header->rcode("FORMERR");
	}
    } else {
	print "ERROR: opcode ", $query->header->opcode, " unsupported\n"
	    if $self->{"Verbose"};
	$reply->header->rcode("FORMERR");
    }
    
    #default values
    $reply->header->qr(1);
    $reply->header->cd($query->header->cd);
    $reply->header->rd($query->header->rd);	
    $reply->header->id($query->header->id);

    if (!defined ($transporthash)) {
	$reply->header->ra(1);
	$reply->header->ad(0);
    } else {
	$reply->headermask($transporthash);

    }


    $reply->headermask($transporthash);
    
    $reply->header->print if $self->{"Verbose"} && defined $transporthash;

    return $reply;
}
