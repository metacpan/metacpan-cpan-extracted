package Net::Radiator::Monitor;

use strict;
use warnings;

use IO::Socket::INET;
use IO::Select;
use Carp qw(croak);

our $VERSION = '0.021';
our %METHODS = (
		server_stats	=> {	cmd => 'STATS',
					args=> '.',
					ml  => 1
				},
		client_stats	=> {
					cmd => 'STATS',
					args=> '".Client." . $_[0]',
					evl => 1,
					ml  => 1
				},
		list_clients	=> {	cmd => 'LIST',
					args=> 'Client',
					ml  => 1
				},
		list_realms	=> {	cmd => 'LIST',
					args=> 'Realm',
					ml  => 1
				},
		list_handlers	=> {
					cmd => 'LIST',
					args=> 'Handler',
					ml  => 1
				}
	);

sub new {
	my ($class,%args)= @_;
	my $self	= {};
	bless $self, $class;
	$self->{user}	= $args{user};
	$self->{passwd}	= $args{passwd};
	$self->{server}	= (defined $args{server} ? $args{server} : croak 'Constructor failed: no server supplied');
	$self->{port}   = $args{port} ||= 9048;
	$self->{timeout}= $args{timeout} ||= 5;
	$self->{sock}= IO::Socket::INET->new(	PeerAddr	=> $self->{server},
						PeerPort	=> $self->{port},
						Proto		=> 'tcp',
						Timeout		=> $self->{timeout}
				) or croak "Can't establish connection to server $args{server} on port $args{port}: $!\n";

	$self->{sel}= IO::Select->new($self->{sock});
	
	my @login = $self->_cmd(cmd => 'LOGIN', args => " $self->{user} $self->{passwd}");
	return ( $login[0] eq 'LOGGEDIN' 
		? $self
		: do { 	print "Failed to log in: $login[0]\n"; return 0 } )
}

{
	no strict 'refs';

	foreach my $m (keys %METHODS) {
		*{ __PACKAGE__ . "::$m" } = sub {
			my $self = shift;
			my %res;
			my ($c1,$c2) = ($m =~ /^list/ ? (0,2) : (0,1));
			
			foreach my $line ($self->_cmd(cmd => $METHODS{$m}{cmd}, args => ($METHODS{$m}{evl} ? eval $METHODS{$m}{args} : $METHODS{$m}{args}), ml => $METHODS{$m}{ml})) {
				my ($var,$val)	= (split /:/, $line)[$c1,$c2];
				$res{$var} = $val || 0;
			}
			
			return %res
		}
	}
}

sub quit{ $_[0]->{sock}->send('QUIT') and $_[0]->{sock}->close }

sub id 	{ return $_[0]->_cmd(cmd => 'ID', args => '') }

sub _trace {
	my ($self,$level) = @_;
	return $_[0]->_cmd(cmd => 'ID', args => '')
}

sub _cmd {
	my ($self,%args) = @_;
	my $buf;
	$self->{sock}->send("$args{cmd} $args{args}\n");

	if ($self->{sel}->can_read($self->{timeout})) {
		$self->{sock}->recv($buf, 10240);
		chomp $buf;
		my @r = split '\001', $buf;
		shift @r if ( $args{ml} and ( scalar @r > 1 ) );
		return @r;
	}

	return
}

=head1 NAME

Net::Radiator::Monitor - Perl interface to Radiator Monitor command language

=head1 SYNOPSIS

This module provides a Perl interface to Radiator Monitor command language.

  use strict;
  use warnings;

  use Net::Radiator::Monitor;
  use Carp qw(croak);

  my $monitor = Net::Radiator::Monitor->new(
						user	=> $user,
						passwd	=> $passwd,
						server	=> $server,
						port	=> 9084,
						timeout => 5
					) or croak "Unable to create monitor: $!\n";

  print $monitor->id;

  $monitor->quit;  

=head1 METHODS

=head2 new

  my $monitor = Net::Radiator::Monitor->new(
					user	=> $user,
					passwd	=> $passwd,
					server	=> $server,
					);
  

Constructor - creates a new Net::Radiator::Monitor object using the specified parameters.  This method
takes three mandatory and two optional parameters.

=over 4 

=item user

The username to use to connect to the monitor interface.  This username must have the required
access to connect to the monitor.

=item passwd

The password for the username use to connect to the monitor interface.

=item server

The server to connect to - this should be either a resolvable hostname or an IP address.

=item port

The port on which to connect to the monitor interface - this parameter is optional and if
not specified will default to the Radiator default port of 9084.

=item timeout

The connection timeout value and recieve timeout value for the connection to the Radiator 
server - this parameter is optional and if not specified will default to five seconds.

=back

=head2 quit

  $monitor->quit;

Closes the monitor connection.

=head2 id

  my $id = $monitor->id;

Returns the Radiator server ID string.  the string has the following format:

  ID <local_timestamp> Radiator <version> on <servername>

Where:

=over 4

=item <local_timestamp>

Is the current local time on the server given in seconds since epoch.

=item <version>

Is the Radiator server version.

=item <servername>

Is the configured server name.

=back

=head2 server_stats

  my %server_stats = $monitor->server_stats;

  foreach my $stats (sort keys %server_stats) {
    print "$stats : $server_stats{$stats}\n"
  }

Returns a hash containing name,value pairs of collected server statistics.  
Server statistics are culminative values of access and accounting across all 
configured objects.

The measured statistics (and the keys of the hash) are:

  Access challenges
  Access rejects
  Access requests
  Accounting requests
  Accounting responses
  Average response time
  Bad authenticators in accounting requests
  Bad authenticators in authentication requests
  Dropped access requests
  Dropped accounting requests
  Duplicate access requests
  Duplicate accounting requests
  Malformed access requests
  Malformed accounting requests
  Total Bad authenticators in requests
  Total dropped requests
  Total duplicate requests
  Total proxied requests
  Total proxied requests with no reply
  Total requests

=head2 client_stats ($client_id)

  my %client_stats = $monitor->client_stats($client_id);
  
Returns a hash containing name,value pairs of collected statistics for client
specified by the value of the client id.  The available statistics are the same 
as those listed for the B<server_stats> method.

The B<list_clients> method can be sed to retrieve valid client IDs.

=head2 list_clients

  while (($id, $name) = each $monitor->list-clients) {
    print "Client : $name - ID : $id\n"
  }

Returns a hash containing all configured clients where the key is the numerical identifier 
for the realm and the value is the client name or IP address (dependent on configuration).

=head2 list_realms

Returns a hash containing all configured realms where the key is the numerical identifier 
for the realm and the value is the realm name.

=head2 list_handlers

Returns a hash containing all configured handlers where the key is the numerical identifier 
for the handler and the value is the handler name.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-radiator-monitor at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Radiator-Monitor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Radiator::Monitor


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Radiator-Monitor>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Radiator-Monitor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Radiator-Monitor>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Radiator-Monitor/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
