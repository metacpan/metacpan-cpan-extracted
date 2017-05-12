package Net::Rendezvous;

$VERSION = 0.5;

sub new {
	my $self = {};
	bless $self, shift;
	$self->_init(shift);
	return $self;
}

sub _init {
	my $self = shift;
	$self->application(shift);
	$self->{'_ns'} = '224.0.0.251';
	$self->{'_port'} = '5353';
#	$self->refresh;
	return;
}
	
sub application {
	my $self = shift;
	if ( @_) {
		my $app = shift;
		my $proto = shift || 'tcp';
		$self->{'_app'} = sprintf '_%s._%s.local', $app, $proto;
	} else {
		return $self->{'_app'};
	}
	return;
}

sub refresh {
	my $self = shift;
	use Net::DNS;
	use Socket;
	use Net::Rendezvous::RR;

	my $query = new Net::DNS::Packet($self->application, 'PTR');

	socket DNS, PF_INET, SOCK_DGRAM, scalar(getprotobyname('udp'));
	bind DNS, sockaddr_in(0,inet_aton('0.0.0.0'));
	send DNS, $query->data, 0, sockaddr_in($self->{'_port'}, inet_aton($self->{'_ns'}));

	my $rin = ''; my $list = [];
	vec($rin, fileno(DNS), 1) = 1;

	while ( select($rout = $rin, undef, undef, 1.0)) {
		my $data, $rr;
		recv(DNS, $data, 1000, 0);
		my $ans = new Net::DNS::Packet( \$data );
		foreach $rr ( $ans->answer ) {
			my $host = new Net::Rendezvous::RR($rr->rdatastr);
			push(@{$list}, $host);
		}
	}
	$self->{'_results'} = $list;
	return $#{$list};
}

sub entries {
	my $self = shift;	
	return @{$self->{'_results'}};
}

sub shift_entry {
	my $self = shift;
	return shift(@{$self->{'_results'}});
}