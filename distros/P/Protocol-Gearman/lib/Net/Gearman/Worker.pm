#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Net::Gearman::Worker;

use strict;
use warnings;

our $VERSION = '0.04';

use base qw( Net::Gearman Protocol::Gearman::Worker );

=head1 NAME

C<Net::Gearman::Worker> - concrete Gearman worker over an IP socket

=head1 SYNOPSIS

 use List::Util qw( sum );
 use Net::Gearman::Worker;

 my $worker = Net::Gearman::Worker->new(
    PeerAddr => $SERVER,
 ) or die "Cannot connect - $@\n";

 $worker->can_do( 'sum' );

 while(1) {
    my $job = $worker->grab_job->get;

    my $total = sum split m/,/, $job->arg;

    $job->complete( $total );
 }

=head1 DESCRIPTION

This module combines the abstract L<Protocol::Gearman::Worker> with
L<Net::Gearman> to provide a simple synchronous concrete worker
implementation.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
