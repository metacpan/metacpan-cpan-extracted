package Net::DNS::TestNS::Packet;
use strict;
use vars qw(@ISA $VERSION);

use Net::DNS::Packet;
use Net::DNS::Header;

use Data::Dumper;

@ISA     = qw(Net::DNS::Packet);
$VERSION=(qw$LastChangedRevision: 323 $)[1];

my $debug=0;

#
#  We use the "headermask" to replace header information after the 
#  regular Net::DNS::Packet->data() method has compiled the packet
#

sub data {
    my $self=shift;
    my $data;
    if ($self->{"rawhack"}){
	$data=$self->{"data"} 
    }else{
	$data=Net::DNS::Packet::data($self);
    }
    if (defined $self->headermask()){
	print "Applying headermask\n" if $debug;

	my $headermask=$self->headermask();
	foreach my $headerfield qw(aa ra ad cd qr rd tc 
				   qdcount ancount nscount arcount){
	   next unless defined $headermask->{$headerfield} ;
	    $self->header->$headerfield($headermask->{$headerfield});
	}
	$self->header->id($headermask->{'id'}) if  $headermask->{'id'};
	# Replace the original header.
	my $headerlength=length $self->{"header"}->data;
	return $self->header->data . substr ($data,$headerlength);
    }

    return $data;

}


# headermask accessor method.
# header mask is used to store the potentially hacked header settings.
# only after

sub headermask {
    
    my $self=shift;
    my $new_val=shift;
    
    if (defined $new_val) {
	$self->{'headermask'} = $new_val;
    }
    
    return $self->{'headermask'};
};

1;
