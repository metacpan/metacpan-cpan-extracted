package Net::Clacks;
#---AUTOPRAGMASTART---
use 5.020;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English;
use Carp;
our $VERSION = 10;
use autodie qw( close );
use Array::Contains;
use utf8;
#---AUTOPRAGMAEND---
use Net::Clacks::Client;
use Net::Clacks::Server;
use Net::Clacks::ClacksCache;
1;
__END__


=head1 NAME

Net::Clacks - Fast client/server interprocess messaging and memcached replacement

=head1 SYNOPSIS

The Net::Clacks system implements a fast client/server based interprocess messaging. For
handling a high number of clients, you can run multiple servers in a master/slave configuration.
A slave can also run itself as master for it's own slaves, so a tree-like setup is possible.

=head1 DESCRIPTION

The Net::Clacks system implements a fast client/server based interprocess messaging. For
handling a high number of clients, you can run multiple servers in a master/slave configuration.
A slave can also run itself as master for it's own slaves, so a tree-like setup is possible.

Clacks has two ways to handle data. One is (near) real time messaging, the other is storing in
memory (as a replacement for memcached).

Clacks has also a DEBUG feature, that forwards all messages to a requesting client.

The Net::Clacks system implements a fast client/server based interprocess messaging. For
handling a high number of clients, you can run multiple servers in a master/slave configuration.
A slave can also run itself as master for it's own slaves, so a tree-like setup is possible. This
is implemented by using Interclacks mode via OVERHEAD mode setting.

=head1 IMPORTANT UPGRADE NOTES

=head2 VERSION 6

Version 6 (and higher) of L<Net::Clacks::Server> imlements a smarter interclacks sync. Make
sure to upgrade all nodes on your local clacks network at the same time! While the protocol itself
is mostly backward compatible, interclacks sync will fail otherwise.

Version 6 also includes a smarter shutdown sequence for L<Net::Clacks::Client> and the ability to 
persistantly store the clackscache data in a file in L<Net::Clacks::Server>. The file format has also
changed somewhat from previous beta versions of this feature due to the implementation of smarter 
sync. If you have used persistance before, you might (or might not) have to reset/remove the persistance
file.

This change to "smarter" syncing has increased stability of some of my systems using "Net::Clacks", but
has been in use for only a limited time. You should test with your own software before upgrading.

=head2 VERSION 7

Version 7 (and higher) of L<Net::Clacks::Server> and L<Net::Clacks::Client> implement a lot of
bugfixes and improvements. This includes authentication timeouts, somewhat smarter automatic reconnects
and stuff like that.

While the protocol in theory is backwards compatible to version 6, it is strongly recommended that you
upgrade ALL nodes (clients and servers) in your network at the same time. I have done only limited testing
with backward compatibility and i would not recommending a mix&match approach on critical systems.

=head2 VERSION 8

On Systems that support Unix domain sockets and have IO::Socket::UNIX installed,
L<Net::Clacks::Server> and L<Net::Clacks::Client> can now use Unix domain sockets
for local communication. See the examples for. This might or might not drastically
lower CPU usage, depending on your hardware, software, weather on moon phase.

Version 8 also includes a number of bugfixes and improvements. This includes a better
way of detecting closed/broken connection which should prevent servers and clients
from holding on to closed connection until it times out. This should also lower CPU
usage under certain circumstances. This is far from perfect, though and may lead to
some false positives (e.g. accidental closure of perfectly fine connections) thanks
to the combination of SSL and non-blocking sockets.

Version 8 is fully backwards compatible with Version 7 on the network layer (no protocol change),
but as always it is recommended to update all servers and clients at the same time if possible.

One important client API change (sort of) is the generation of messages with type "reconnected"
after a connection has been re-established. After receiving this message, a client application
must resend any LISTEN calls it wants to make. While in previous versions, this was accomplished
by checking for type "disconnect" messages, this was unreliable at best. The "reconnected" message
is generated internally B<after> a new connection has been established, except on the first ever
connection. Technically, at that point in time L<Net::Clacks::Client> has spooled the Auth request
to the server, but may not have recieved the answer yet, but i'll assume here that you have configured
your client correctly.

=head2 VERSION 9

Version 9 added the socketchmod option to chmod() the socket file so other users can connect to the socket, too.

=head2 VERSION 10

WARNING: BREAKING CHANGES! It is required to update all servers and clients at the same time.

Version 10 disables SSL on Unix Domain Sockets for better local performance. This version also adds the
ability to run interclacks through Unix Domain Sockets, in case you want to run a master/slave setup locally. This
should not really affect security, though. If an attacker has enough permissions to spy on a Unix Domain Socket,
they will most likely also have the ability to gain access to the configuration files and SSL keys of the Clacks server
running on the same host..

This version also has a slightly improved timeout handling when a slave reconnects to the master at the cost
of a bit more traffic during the initial setup phase.

In the protocol, error messages have been implemented via the "E" flag in the "OVERHEAD" command. L<Net::Clacks::Client>
forwards this to the client software via a clacks message of type "error_message".

In theory, the only *breaking* incompatible change is contained in handling Unix Domain Sockets. You could (try to) upgrade
to Version 10 client-by-client if you don't use Unix Domain Sockets, but this is neither tested nor recommended.

=head1 PROTOCOL

Clacks is a text based protocol through SSL/TLS encrypted TCP connections. Most of the
commands are asyncronous and do not generate any return value. These commands are truly
fire-and-forget with minimal delay for the client.

A few functions/commands generate one or more lines of data return, so the client has to wait
for them. The L<Net::Clacks::Client> module knows what to do in each case, so there is little
to none special handling required in the application. The same goes for L<Net::Clacks::ClacksCache>.


=head1 MODULES

The server is implemented in L<Net::Clacks::Server>.

The client library in L<Net::Clacks::Client>.

A more Cache::Memcached compatible client library (caching only, no real time communication) is implemented
in the L<Net::Clacks::ClacksCache> module.

Please also take a look at the examples, this implements a simple chat client.

=head1 IMPORTANT NOTE

Please refer to the included protocol.txt file for information
about the CLACKS protocol.

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 Source code repository

The official source code repository is located at:
L<https://cavac.at/public/mercurial/Net-Clacks/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2019 Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

