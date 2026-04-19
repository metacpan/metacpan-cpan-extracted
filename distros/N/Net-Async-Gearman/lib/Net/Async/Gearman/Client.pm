#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014,2026 -- leonerd@leonerd.org.uk

package Net::Async::Gearman::Client 0.02;

use v5.20;
use warnings;

use base qw( Net::Async::Gearman Protocol::Gearman::Client );

=head1 NAME

C<Net::Async::Gearman::Client> - concrete Gearman client over an L<IO::Async::Stream>

=head1 SYNOPSIS

=for highlighter language=perl

   use IO::Async::Loop;
   use Net::Async::Gearman::Client;

   my $loop = IO::Async::Loop->new;

   my $client = Net::Async::Gearman::Client->new;
   $loop->add( $client );

   await $client->connect(
      host => $SERVER,
   );

   my $total = await $client->submit_job(
      func => "sum",
      arg  => "10,20,30",
   );

   say $total;

=head1 DESCRIPTION

This module combines the abstract L<Protocol::Gearman::Client> with
L<Net::Async::Gearman> to provide an asynchronous concrete Gearman client
implementation.

It provides no new methods of its own; all of the Gearman functionality comes
from C<Protocol::Gearman::Client>. See that module's documentation for more
information.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
