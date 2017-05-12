#
# Copyright 2007-2010 David Snopek <dsnopek@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package POE::Component::Server::Stomp;

use POE::Session;
use POE::Component::Server::TCP;
use POE::Filter::Stomp;
use IO::String;
use Net::Stomp::Frame;
use Carp qw(croak);
use vars qw($VERSION);
use strict;

$VERSION = '0.2.3';

sub new
{
	my $class = shift;

	croak "$class->new() requires an even number of arguments" if (@_ & 1);

	my $args = { @_ };

	# TCP server options
	my $alias   = delete $args->{Alias};
	my $address = delete $args->{Address};
	my $hname   = delete $args->{Hostname};
	my $port    = delete $args->{Port};
	my $domain  = delete $args->{Domain};

	if ( not defined $port )
	{
		# default Stomp port
		$port = 61613;
	}

	# user callbacks.
	my $handle_frame        = delete $args->{HandleFrame};
	my $client_disconnected = delete $args->{ClientDisconnected};
	my $client_error        = delete $args->{ClientError};

	# A closure?  In Perl!?  Hrm...
	my $client_input = sub 
	{
		my ($kernel, $input) = @_[ KERNEL, ARG0 ];

		# Replace ARG0 with the parsed frame.
		splice(@_, ARG0, 1, $input);

		# pass to the user handler
		$handle_frame->(@_);
	};

	# create the TCP server.
	POE::Component::Server::TCP->new(
		Alias    => $alias,
		Address  => $address,
		Hostname => $hname,
		Port     => $port,
		Domain   => $domain,

		ClientInput        => $client_input,
		ClientError        => $client_error,
		ClientDisconnected => $client_disconnected,

		# Use Keven Esteb's awesome Stomp filter module!
		ClientFilter => "POE::Filter::Stomp",

		# pass everything left as arguments to the PoCo::Server::TCP
		# contructor.
		%$args
	);

	# POE::Component::Server::TCP does it!  So, I do it too.
	return undef;
}

1;

__END__

=pod

=head1 NAME

POE::Component::Server::Stomp - A generic Stomp server for POE

=head1 SYNOPSIS

  use POE qw(Component::Server::Stomp);
  use Net::Stomp::Frame;
  use strict;

  POE::Component::Server::Stomp->new(
    HandleFrame        => \&handle_frame,
    ClientDisconnected => \&client_disconnected,
    ClientErrorr       => \&client_error
  );

  POE::Kernel->run();
  exit;

  sub handle_frame
  {
    my ($kernel, $heap, $frame) = @_[ KERNEL, HEAP, ARG0 ];

    print "Recieved frame:\n";
    print $frame->as_string() . "\n";

    # allow Stomp clients to connect by playing along.
    if ( $frame->command eq 'CONNECT' )
    {
      my $response = Net::Stomp::Frame->new({
        command => 'CONNECTED'
      });
      $heap->{client}->put( $response->as_string . "\n" );
    }
  }

  sub client_disconnected
  {
    my ($kernel, $heap) = @_[ KERNEL, HEAP ];

    print "Client disconnected\n";
  }

  sub client_error
  {
    my ($kernel, $name, $number, $message) = @_[ KERNEL, ARG0, ARG1, ARG2 ];

    print "ERROR: $name $number $message\n";
  }

=head1 DESCRIPTION

A thin layer over L<POE::Component::Server::TCP> that parses out L<Net::Stomp::Frame>s.  The
synopsis basically covers everything you are capable to do.

For information on the STOMP protocol:

L<http://stomp.codehaus.org/Protocol>

For a full-fledged message queue that uses this module:

L<POE::Component::MessageQueue>

=head1 SEE ALSO

L<POE::Component::Server::TCP>,
L<POE::Filter::Stomp>,
L<Net::Stomp>

=head1 BUGS

Probably.

=head1 AUTHORS

Copyright 2007-2010 David Snopek.

=cut

