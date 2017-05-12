#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Net::Gearman::Client;

use strict;
use warnings;

our $VERSION = '0.04';

use base qw( Net::Gearman Protocol::Gearman::Client );

=head1 NAME

C<Net::Gearman::Client> - concrete Gearman client over an IP socket

=head1 SYNOPSIS

 use Net::Gearman::Client;

 my $client = Net::Gearman::Client->new(
    PeerAddr => $SERVER,
 ) or die "Cannot connect - $@\n";

 my $total = $client->submit_job(
    func => "sum",
    arg  => "10,20,30",
 )->get;

 say $total;

=head1 DESCRIPTION

This module combines the abstract L<Protocol::Gearman::Client> with
L<Net::Gearman> to provide a simple synchronous concrete client
implementation.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
