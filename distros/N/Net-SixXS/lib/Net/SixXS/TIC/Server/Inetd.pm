#!/usr/bin/perl

package Net::SixXS::TIC::Server::Inetd;

use v5.010;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.1");

use Moose;

use Net::SixXS;

extends 'Net::SixXS::TIC::Server';

sub run($)
{
	my ($self) = @_;
	my $c = {};

	$self->greet_client($c);
	while (<>) {
		s/[\r\n]*$//;
		$self->run_command($c, [split /\s+/]);
		return if $c->{shutdown};
	}
}

sub client_write_line($ $ $)
{
	my ($self, $client, $line) = @_;

	say $line;
}

no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

C<Net::SixXS::TIC::Server::Inetd> - an inetd-run TIC server

=head1 SYNOPSIS

  use Net::SixXS::Data::Tunnel;
  use Net::SixXS::Server::Inetd;

  my %tunnels = (
      T00001 => Net::SixXS::Data::Tunnel->from_json(\%data1),
      T00002 => Net::SixXS::Data::Tunnel->from_json(\%data2),
  );
  my $s = Net::SixXS::Server::Inetd->new(username => 'user',
      password => 'secret', tunnels => \%tunnels);
  $s->run;

=head1 DESCRIPTION

The C<Net::SixXS::TIC::Server::Inetd> class implements a TIC server
providing the data about one or more IPv6-over-IPv4 tunnels running
the "Anything-In-Anything" (AYIYA) protocol as used by SixXS.  It provides
the communication with the clients - receiving command lines and sending
back the responses - needed by the L<Net::SixXS::TIC::Server> class, and
depends on the latter for the actual implementation of the TIC negotiation.

=head1 ATTRIBUTES

The C<Net::SixXS::TIC::Server::Inetd> class does not define any
attributes in addition to the ones provided by L<Net::SixXS::TIC::Server>.

=head1 METHODS

The C<Net::SixXS::TIC::Server::Inetd> class defines the following
methods in addition to the ones provided by L<Net::SixXS::TIC::Server>:

=over 4

=item B<run ()>

Communicate with a TIC client by reading its commands from the standard
input stream and writing the server responses to the standard output
stream in a way compatible with the L<inetd> superserver.

=item B<client_write_line (client, line)>

Implement the C<client_write_line()> method required by
L<Net::SixXS::TIC::Server> by writing the line to the standard output stream.

=back

=head1 SEE ALSO

L<Net::SixXS>, L<Net::SixXS::Data::Tunnel>,
L<Net::SixXS::TIC::Server>, L<Net::SixXS::TIC::Server::AnyEvent>

=head1 LICENSE

Copyright (C) 2015  Peter Pentchev E<lt>roam@ringlet.netE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut
