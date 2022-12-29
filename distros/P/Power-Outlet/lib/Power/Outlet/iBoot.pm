package Power::Outlet::iBoot;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP};
use IO::Socket;
use Time::HiRes qw{sleep};

our $VERSION = '0.47';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Power::Outlet::iBoot - Control and query a Dataprobe iBoot power outlet

=head1 SYNOPSIS

  my $outlet=Power::Outlet::iBoot->new(
                                       host => "mylamp",
                                       port => 80,        #sane default from manufacture spec
                                       auth => "PASS",    #sane default from manufacture spec
                                      );
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION
 
Power::Outlet::iBoot is a package for controlling and querying a Dataprobe iBoot network attached power outlet.

iBoot Protocol: The iBoot uses the TCP (Transport Communication Protocol) to communicate with the client system. To communicate with iBoot, establish a TCP connection using the Port as assigned in iBoot Setup.  Once connected use the Send() function to send the commands to the iBoot and the Recv() function to receive the response. After sending a response iBoot will close the connection.  The following outlines the commands and their responses.

Source: http://dataprobe.com/files/power/iboot_tcp.pdf

=head1 USAGE

  use Power::Outlet::iBoot;
  use DateTime;
  my $lamp=Power::Outlet::iBoot->new(host=>"lamp");
  my $hour=DateTime->now->hour;
  my $night=$hour > 20 ? 1 : $hour < 06 ? 1 : 0;
  if ($night) {
    print $lamp->on, "\n";
  } else {
    print $lamp->off, "\n";
  }

=head1 CONSTRUCTOR

=head2 new

  my $outlet=Power::Outlet->new(type=>"iBoot", "host=>"mylamp");
  my $outlet=Power::Outlet::iBoot->new(host=>"mylamp");


=head1 PROPERTIES

=head2 host

Sets and returns the hostname or IP address.

Manufacturer Default: 192.168.1.254

=cut

sub _host_default {"192.168.1.254"};

=head2 port

Sets and returns the TCP port

Manufacturer Default: 80

=cut

sub _port_default {"80"};

=head2 pass

Sets and returns the case sensitive password

Manufacturer Default: PASS

=cut

sub pass {
  my $self=shift;
  $self->{"pass"}=shift if @_;
  $self->{"pass"}="PASS" unless defined $self->{"pass"}; #MFG Default
  return $self->{"pass"};
}

=head2 name

=cut

=head1 METHODS

=head2 query

Sends a TCP/IP message to the iBoot device to query the current state

=cut

sub _send {
  my $self=shift;
  my $cmd=shift or die;
  my $msg=sprintf("\e%s\e%s\r", $self->pass, $cmd);
  #from docs "After sending a response iBoot will close the connection"
  my $sock=IO::Socket::INET->new(PeerAddr => $self->host,
                                 PeerPort => $self->port,
                                 Proto    => 'tcp');
  die(sprintf(qq{Error: $PACKAGE could not connect to host "%s" on port "%s".\n},
        $self->host, $self->port)) unless defined $sock;
  $sock->send($msg);
  sleep 0.1; #the manufacturer example uses a full second
  my $stat="";
  $sock->recv($stat, 5);
  die(sprintf(qq{Error: $PACKAGE TCP/IP receive error with host "%s" on port "%s".\n},
      $self->host, $self->port)) unless defined $stat;
  die(sprintf(qq{Error: $PACKAGE receive error with host "%s" on port "%s". Verify password.\n},
      $self->host, $self->port)) unless $stat;
  $sock->close;
  return $stat;
}

sub query {shift->_send("q")};

=head2 on

Sends a TCP/IP message to the iBoot device to Turn Power ON

=cut

sub on {shift->_send("n")};

=head2 off

Sends a TCP/IP message to the iBoot device to Turn Power OFF

=cut

sub off {shift->_send("f")};

=head2 switch

Queries the device for the current status and then requests the opposite.  

=cut

#see Power::Outlet::Common->switch

=head2 cycle

Sends a TCP/IP message to the iBoot device to Cycle Power (ON-OFF-ON or OFF-ON-OFF). Cycle time is determined by Setup.

Manufacturer Default Cycle Period: 10 seconds

=cut

sub cycle {shift->_send("c")};

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

=cut

1;
