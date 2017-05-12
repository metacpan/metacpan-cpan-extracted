package Net::Rendezvous::RR;

use Socket;
$VERSION = 0.5;

sub new {
	$self = {};
	bless $self, shift;
	$self->_init(shift) if @_;
	return $self;
}

sub _init {
	my $self = shift;
	$self->{'_ns'} = '224.0.0.251';
	$self->{'_port'} = '5353';
	$self->{'_ip_type'} = 'A';
	$self->fetch(shift);
	return;
}

sub fetch {
	my $self = shift;
	$self->fqdn(shift) if @_;
	use Net::DNS;
	my $res = new Net::DNS::Resolver( nameservers => [$self->{'_ns'}], port => $self->{'_port'});

	my @temp = split(/\./,$self->fqdn);
	$self->name($temp[0]);
	$self->type($temp[1], $temp[2]);

	my $srv = $res->query($self->fqdn, 'SRV');
	my @srvd = split(/ /, ($srv->answer)[0]->rdatastr);
	$self->priority($srvd[0]);
	$self->weight($srvd[1]);
	$self->port($srvd[2]);
	$srvd[3] =~ s/\.$//;
	$self->hostname($srvd[3]); 
	foreach ( $srv->additional ) {
		$self->{'_' . uc($_->type)} = $_->rdatastr;
	}
	my $txt = $res->query( $self->fqdn, 'TXT');
	my $text = ($txt->answer)[0]->rdatastr;
	$text =~ s/^\"//; $text =~ s/\"$//; 
	foreach ( split(/\" \"/,$text) ) {
		next if $_ eq '';
		my($key,$val) = split(/=/,$_);
		$self->attribute($key, $val);
	}
	$self->text($text);
	return;
}

sub attribute {
	my $self = {};
	my $key = shift;
	if ( @_ ) {
		$self->{'_attr'}{$key} = shift;
	} else {
		return $self->{'_attr'}{$key};
	}
	return;
}

sub type {
	my $self = shift;
    if ( @_ ) {
		my $type = sprintf '%s/%s', shift, shift;
		$type =~ s/_//g;
		$self->{'_type'} = $type;
	}
	return $self->{'_type'};
}

sub address {
	my $self = shift;
	my $key = '_' . $self->{'_ip_type'};
	if ( @_ ) {
		$self->{$key} = shift;
	}
	return $self->{$key};
}
	
sub sockaddr {
	my $self = shift;
	return sockaddr_in($self->port, inet_aton($self->address));
}

sub AUTOLOAD {
	my $self = shift;
	my $key = $AUTOLOAD;
	$key =~ s/^.*:://;
	$key = '_' . $key;
	if ( @_ ) {
		$self->{$key} = shift;
	}
	return $self->{$key};
}