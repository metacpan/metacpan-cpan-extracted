package Net::Forward;
use 5.014002;
use strict;
use warnings;
require Exporter;
use IO::Socket;
use AutoLoader qw(AUTOLOAD);
our @ISA = qw(Exporter IO::Socket);
our @EXPORT = qw();
our $VERSION = '0.1';
sub new{
	my ($class,$self) = @_;
	return bless $self, $class;
}
sub activate{
	my $self = shift;
	$self->{Proto} = 'tcp' unless defined $self->{Proto};
	_listen($self->{LocalHost},$self->{LocalPort},$self->{RemoteHost},$self->{RemotePort},$self->{Proto});
}
sub _listen{
	my ($local_host,$local_port,$remote_host,$remote_port,$proto) = @_;
	my $server = new IO::Socket::INET (LocalHost => $local_host,
					 LocalPort => $local_port,
					 Proto => $proto,
					 Listen => 1,
					 Reuse => 1) || die qq,Cannot listen on "$local_host:$local_port"\n,;
	while (my $client = $server->accept()) {
		$client->autoflush(1);
		if(fork()){
			$client->close();
		}else{
			$server->close();
			_pipe($server,$client,IO::Socket::INET->new(PeerAddr => $remote_host, PeerPort => $remote_port, Proto => $proto, Type => SOCK_STREAM) || die qq,Cannot connect to "$remote_host:$remote_port"\n,);
			exit();
		}
}
}
sub _pipe{
	my($server,$client,$remote) = @_;
	$remote->autoflush();
	while($client || $remote) {
		my $rin = "";
		vec($rin, fileno($client), 1) = 1 if $client;
		vec($rin, fileno($remote), 1) = 1 if $remote;
		my($rout, $eout);
		select($rout = $rin, undef, $eout = $rin, 120);
		if (!$rout  &&  !$eout) { return; }
		my $cbuffer = "";
		my $tbuffer = "";
		if ($client && (vec($eout, fileno($client), 1) || vec($rout, fileno($client), 1))) {
		my $result = sysread($client, $tbuffer, 1024);
		if (!defined($result) || !$result) { return; }
}
		if ($remote  &&  (vec($eout, fileno($remote), 1)  || vec($rout, fileno($remote), 1))) {
			my $result = sysread($remote, $cbuffer, 1024);
			if (!defined($result) || !$result) { return; }
}

	while (my $len = length($tbuffer)) {
		my $res = syswrite($remote, $tbuffer, $len);
		if ($res > 0) { $tbuffer = substr($tbuffer, $res); } else { return; }
}
	while (my $len = length($cbuffer)) {
		my $res = syswrite($client, $cbuffer, $len);
		if ($res > 0) { $cbuffer = substr($cbuffer, $res); } else { return; }
}
}	
}
1;
__END__
=head1 NAME

Net::Forward - Forwarding(Redirecting) TCP|UDP packets to another host:port

=head1 SYNOPSIS

  use Net::Forward;
  my $nf = new Net::Forward({'LocalHost'=>'127.0.0.1','LocalPort'=>'3000','RemoteHost'=>'www.cpan.org','RemotePort'=>'80','Proto' =>'tcp'});
  $nf->activate();	#blocking

=head1 DESCRIPTION

The module simulates IPTABLES packet forwarding ( iptables -t nat -A PREROUTING -s LocalPort -p Proto --dport LocalPort -j DNAT --to-destination RemoteHost:Remoteport) functionality without the need of root access (when localport is greater than 1000) .

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/IP_forwarding>,L<http://www.debuntu.org/how-to-redirecting-network-traffic-to-a-new-ip-using-iptables/>

=head1 AUTHOR

Sadegh Ahmadzadegan (sadegh <at> cpan.org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Sadegh Ahmadzadegan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
