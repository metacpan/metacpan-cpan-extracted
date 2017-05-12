package Net::Jabber::Loudmouth;

use strict;
use warnings;
use Glib;
require DynaLoader;

our @ISA = qw(DynaLoader);
our $VERSION = 0.07;

our $DefaultPort = 5222;
our $DefaultPortSSL = 5223;

sub default_port { return $DefaultPort; }
sub default_port_ssl { return $DefaultPortSSL; }

sub dl_load_flags { 0x01 };

bootstrap Net::Jabber::Loudmouth $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Net::Jabber::Loudmouth - Perl interface for the loudmouth jabber library

=head1 SYNOPSIS

  use Net::Jabber::Loudmouth;

  my $connection = Net::Jabber::Loudmouth::Connection->new("server");
  $connection->open_and_block();
  $connection->authenticate_and_block("username", "password", "resource");

  my $m = Net::Jabber::Loudmouth::Message->new("recipient", 'message');
  $m->get_node->add_child("body", "message");

  $connection->send($m);

=head1 DESCRIPTION

Net::Jabber::Loudmouth is a perl interface for libloudmouth, Lightweight C
Jabber library. It allows you to do the same stuff with Net::Jabber, but with a
nicer interface and much faster, because most of the code is written in C.

=head1 FUNCTIONS

B<Net::Jabber::Loudmouth> only contains two functions. Other functionality can
be found in B<Net::Jabber::Loudmouth::*>.

=head2 default_port

  Net::Jabber::Loudmouth->default_port()

Returns the default port which will be used for every connection.

=head2 default_port_ssl

  Net::Jabber::Loudmouth->default_port_ssl()

Returns the default ssl port. Use

  $connection->set_port(Net::Jabber::Loudmouth->default_port_ssl())

to tell a connection to use the ssl port. See
L<Net::Jabber::Loudmouth::Connection>.

=head1 SEE ALSO

Net::Jabber::Loudmouth::Connection, Net::Jabber::Loudmouth::Message,
Net::Jabber::Loudmouth::MessageHandler, Net::Jabber::Loudmouth::MessageNode,
Net::Jabber::Loudmouth::SSL, Net::Jabber::Loudmouth::Proxy

=head1 AUTHOR

Florian Ragwitz, E<lt>rafl@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Florian Ragwitz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
