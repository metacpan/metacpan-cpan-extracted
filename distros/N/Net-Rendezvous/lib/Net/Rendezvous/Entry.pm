package Net::Rendezvous::Entry;

=head1 NAME

Net::Rendezvous::Entry - Support module for mDNS service discovery (Apple's Rendezvous)

=head1 SYNOPSIS

use Net::Rendezvous;
	
my $res = new Net::Rendezvous(<service>[, <protocol>]);
	
foreach $entry ( $res->entries ) {
	print $entry->name, "\n";
}
	
=head1 DESCRIPTION

Net::Rendezvous::Entry is a module used to manage entries returned by a mDNS service discovery (Apple's Rendezvous).
See L<Net::Rendezvous> for more information.

=head1 METHODS

=head2 new([<fqdn>])

Creates a new Net::Rendezvous::Entry object. The optional argument defines the fully qualifed domain name (FQDN) of the entry.
Normal usage of the L<Net::Rendezvous> module will not require the construction of Net::Rendezvous::Entry objects, as they are
automatically created during the discovery process.

=head2 fetch

Reloads the information for the entry via mDNS.

=head2 fqdn

Returns the fully qualifed domain name (FQDN) of entry.  An example FQDN is server._afpovertcp._tcp.local

=head2 name

Returns the name of the entry.  In the case of the previous example, the name would be 'server'.  This name may not be the hostname of the server.
For example, names for presence/tcp will be the name of the user and http/tcp will be title of the web resource.

=head2 hostname

Returns the short hostname of the server.  For some services this may be different that the name.  

=head2 address

Returns the IP address of the entry. 

=head2 port

Returns the TCP or UDP port of the entry.

=head2 sockaddr

Returns the binary socket address for the resource and can be used directly to bind() sockets.

=head2 attribute(<attribute>)

Returns the specified attribute from the TXT record of the entry.  TXT records are used to specify additional information, e.g. path for http.

=head1 EXAMPLES

=head2 Print out a list of local websites

	print "<HTML><TITLE>Local Websites</TITLE>";
	
	use Net::Rendezvous;

	my $res = new Net::Rendezvous('http');

	foreach $entry ( $res->entries) {
		printf "<A HREF='http://%s/%s'>%s</A><BR>", $entry->address, 
			$entry->attribute('path'), $entry->name; 
	}
	
	print "</HTML>";
	
=head2 Find a service and connect to it

	use Net::Rendezvous;
	
	my $res = new Net::Rendezvous('custom');
	
	my $entry = $res->shift_entry;
	
	socket SOCK, PF_INET, SOCK_STREAM, scalar(getprotobyname('tcp'));
	
	connect SOCK, $entry->sockaddr;
	
	print SOCK "Send a message to the service";
	
	while ($line = <SOCK>) { print $line; }
	
	close SOCK;	
	
=head1 SEE ALSO

L<Net::Rendezvous>

=head1 COPYRIGHT

This library is free software and can be distributed or modified under the same terms as Perl itself.

=head1 AUTHORS

The Net::Rendezvous::Entry module was created by George Chlipala <george@walnutcs.com>

=cut

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
	my $self = shift;
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