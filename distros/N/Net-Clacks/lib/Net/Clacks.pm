package Net::Clacks;
#---AUTOPRAGMASTART---
use 5.020;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English;
use Carp;
our $VERSION = 24;
use autodie qw( close );
use Array::Contains;
use utf8;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use feature 'signatures';
no warnings qw(experimental::signatures);
#---AUTOPRAGMAEND---

use Net::Clacks::Client;
use Net::Clacks::Server;
use Net::Clacks::ClacksCache;

1;

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

Clacks has also a DEBUG feature that forwards all messages to a requesting client.

The Net::Clacks system implements a fast client/server based interprocess messaging. For
handling a high number of clients, you can run multiple servers in a master/slave configuration.
A slave can also run itself as master for it's own slaves, so a tree-like setup is possible. This
is implemented by using Interclacks mode via OVERHEAD mode setting.

=head1 MODULES

The server is implemented in L<Net::Clacks::Server>.

The client library in L<Net::Clacks::Client>.

A more Cache::Memcached compatible client library (caching only, no real time communication) is implemented
in the L<Net::Clacks::ClacksCache> module.

Please also take a look at the examples, this implements a simple chat client.


=head1 IMPORTANT UPGRADE NOTES

Please make sure to read L<Net::Clacks::UpgradeGuide> before upgrading to a new Net::Clacks version.

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 Source code repository

The official source code repository is located at:
L<https://cavac.at/public/mercurial/Net-Clacks/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2022 Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

