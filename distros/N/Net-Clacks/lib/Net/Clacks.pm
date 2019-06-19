package Net::Clacks;
#---AUTOPRAGMASTART---
use 5.010_001;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English qw(-no_match_vars);
use Carp;
our $VERSION = 6.0;
use Fatal qw( close );
use Array::Contains;
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

=head1 VERSION 6 UPGRADE NOTES

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

=head1 PROTOCOL

Clacks is a text based protocol through SSL/TLS encrypted TCP connections. Most of the
command are asyncronous and do not generate any return value. These commands are truly
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

