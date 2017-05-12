############################################################################
# Net::Inspect::L5::NoData
# handler for connections which don't transfer any bytes
############################################################################
use warnings;
use strict;
package Net::Inspect::L5::NoData;
use base 'Net::Inspect::Connection';
use Net::Inspect::Debug;

sub guess_protocol {
    my ($self,$guess,$dir,$data,$eof,$meta) = @_;
    if ($data ne '') {
	# data transferred, not null
	$guess->detach($self);
	return;
    } elsif ( $eof != 2 ) {
	# not full eof
	return;
    } else {
	debug("no bytes transfered before connection closed");
	return ($self->new,0);
    }
}

sub in { die "never called" }
sub fatal { die "never called" }



1;

__END__

=head1 NAME

Net::Inspect::L5::NoData - handles empty connections

=head1 SYNOPSIS

 my $guess = Net::Inspect::L5::GuessProtocol->new;
 my $null = Net::Inspect::L5::NoData->new;
 $guess->attach($null);


=head1 DESCRIPTION

This class is usually used together with Net::Inspect::L5::GuessProtocol to
detect and ignore empty connections. It provides a C<guess_protocol> method
which returns a new object if the connection is closed and no data were
transferred.
