#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2011 -- leonerd@leonerd.org.uk

package IO::Socket::Netlink::Taskstats;

use strict;
use warnings;
use base qw( IO::Socket::Netlink::Generic );

our $VERSION = '0.03';

use Carp;

use Socket::Netlink qw( :DEFAULT );
use Socket::Netlink::Taskstats;

__PACKAGE__->register_family_name( "TASKSTATS" );

=head1 NAME

C<IO::Socket::Netlink::Taskstats> - Object interface to C<Taskstats> generic
netlink protocol sockets

=head1 SYNOPSIS

 use IO::Socket::Netlink::Taskstats;

 my $sock = IO::Socket::Netlink::Taskstats->new;

 my $stats = $sock->get_process_info_by_pid( $$ );

 printf "So far, %s has consumed %d usec in userland and %d in kernel\n",
    $stats->{ac_comm},
    $stats->{ac_utime},
    $stats->{ac_stime};

=head1 DESCRIPTION

This subclass of L<IO::Socket::Netlink::Generic> implements the C<Taskstats>
generic netlink protocol. This protocol allows detailed statistics gathering
of resource usage on a per-process basis, and notification of resources used
by processes at the time they exit.

This module is currently a work-in-progress, and this documentation is fairly
minimal. The reader is expected to be familiar with C<Taskstats>, only a
fairly minimal description of the Perl-level wrapping is given here.

=cut

=head1 METHODS

=cut

sub message_class
{
   return "IO::Socket::Netlink::Taskstats::_Message";
}

sub command_class
{
   return "IO::Socket::Netlink::Taskstats::_Command";
}

sub _get_process_info
{
   my $self = shift;
   my %searchattrs = @_;

   $self->send_nlmsg( $self->new_command(
      cmd => CMD_GET,
      nlattrs => \%searchattrs,
   ) ) or croak "Cannot send - $!";

   $self->recv_nlmsg( my $message, 32768 ) or
      croak "Cannot recv - $!";

   return $message->nlattrs;
}

=head2 $info = $sock->get_process_info_by_pid( $pid )

Returns an information structure containing the statistics about the process
with the given PID.

=cut

sub get_process_info_by_pid
{
   my $self = shift;
   my ( $pid ) = @_;
   return $self->_get_process_info( pid => $pid )->{aggr_pid}{stats};
}

=head2 $sock->register_cpumask( $mask )

=head2 $sock->deregister_cpumask( $mask )

Register or deregister this socket to receive process exit notifications, for
processes exiting on CPUs given by the C<$mask>.

=cut

sub register_cpumask
{
   my $self = shift;
   my ( $mask ) = @_;

   $self->send_nlmsg( $self->new_command(
      cmd => CMD_GET,
      nlattrs => { 
         register_cpumask => $mask,
      },
   ) );

   $self->recv_nlmsg( my $message, 32768 ) or
      croak "Cannot recv - $!";
   ( $! = $message->nlerr_error ) and croak "Received NLMSG_ERROR - $!";
}

sub deregister_cpumask
{
   my $self = shift;
   my ( $mask ) = @_;

   $self->send_nlmsg( $self->new_command(
      cmd => CMD_GET,
      nlattrs => { 
         deregister_cpumask => $mask,
      },
   ) );

   $self->recv_nlmsg( my $message, 32768 ) or
      croak "Cannot recv - $!";
   ( $! = $message->nlerr_error ) and croak "Received NLMSG_ERROR - $!";
}

=head1 MESSAGE OBJECTS

=cut

package IO::Socket::Netlink::Taskstats::_Message;

use base qw( IO::Socket::Netlink::Generic::_Message );

use Socket::Netlink::Taskstats qw( :DEFAULT );

=pod

Provides the following netlink attributes

=over 4

=item * pid => INT

=item * tgid => INT

=item * stats => HASH

=item * aggr_pid => HASH

=item * aggr_tgid => HASH

=back

=cut

__PACKAGE__->has_nlattrs(
   "genlmsg",
   pid       => [ TYPE_PID,       "u32" ],
   tgid      => [ TYPE_TGID,      "u32" ],
   stats     => [ TYPE_STATS,     "stats" ],
   aggr_pid  => [ TYPE_AGGR_PID,  "nested" ],
   aggr_tgid => [ TYPE_AGGR_TGID, "nested" ],
);

sub   pack_nlattr_stats {   pack_taskstats $_[1] }
sub unpack_nlattr_stats { unpack_taskstats $_[1] }

package IO::Socket::Netlink::Taskstats::_Command;

use base qw( IO::Socket::Netlink::Generic::_Message );

use Socket::Netlink::Taskstats qw( :DEFAULT );

__PACKAGE__->has_nlattrs(
   "genlmsg",
   pid                => [ CMD_ATTR_PID,                "u32" ],
   tgid               => [ CMD_ATTR_TGID,               "u32" ],
   register_cpumask   => [ CMD_ATTR_REGISTER_CPUMASK,   "raw" ],
   deregister_cpumask => [ CMD_ATTR_DEREGISTER_CPUMASK, "raw" ],
);

=head1 SEE ALSO

=over 4

=item *

L<Socket::Netlink::Taskstats> - interface to Linux's C<Taskstats> generic
netlink socket protocol

=item *

L<IO::Socket::Netlink> - Object interface to C<AF_NETLINK> domain sockets

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
