
# ----------------------------------------------------------------------------
# http connection with global flowid (connection number) and local 
# request-id
# ----------------------------------------------------------------------------

use strict;
use warnings;

package privHTTPConn;
use base 'Net::Inspect::L7::HTTP';
use fields qw(flowid reqnum);
use Net::Inspect::Debug;

my $flowid;
sub new_connection {
    my ($self,$meta) = @_;
    my $obj = $self->SUPER::new_connection($meta);
    $obj->{flowid} = ++( $flowid ||= 0 );
    $obj->{reqnum} = 0;
    return $obj;
}

sub new_request {
    my ($self,@arg) = @_;
    return $self->SUPER::new_request(@arg,$self,$self->{flowid},
	++$self->{reqnum});
}

sub fatal {
    my ($self,$reason) = @_;
    trace( sprintf("%05d %s",$self->{flowid},$reason));
}

1;
