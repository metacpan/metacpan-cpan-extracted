#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2016 -- leonerd@leonerd.org.uk

package IO::Socket::Netlink::Generic;

use strict;
use warnings;
use base qw( IO::Socket::Netlink );

our $VERSION = '0.05';

use Carp;

use Socket::Netlink::Generic qw(
   NETLINK_GENERIC
   CTRL_CMD_GETFAMILY
);

__PACKAGE__->register_protocol( NETLINK_GENERIC );

=head1 NAME

C<IO::Socket::Netlink::Generic> - Object interface to C<NETLINK_GENERIC>
netlink protocol sockets

=head1 SYNOPSIS

 use IO::Socket::Netlink::Generic;

 my $genlsock = IO::Socket::Netlink::Generic->new or die "socket: $!";

 printf "TASKSTATS family ID is %d\n",
    $genlsock->get_family_by_name( "TASKSTATS" )->{id};

=head1 DESCRIPTION

This subclass of L<IO::Socket::Netlink> implements the C<NETLINK_GENERIC>
protocol. It is itself intended to serve as a base class for particular
generic families to extend.

=cut

=head1 CLASS METHODS

=head2 register_family_name

   $class->register_family_name( $name )

Must be called by a subclass implementing a particular protocol family, to
declare its family name. The first time a socket in that class is constructed,
this name will be looked up into an ID number.

=cut

my %pkg2familyname;
my %familyname2pkg;

sub register_family_name
{
   my ( $pkg, $family_name ) = @_;

   $pkg2familyname{$pkg} = $family_name;
   $familyname2pkg{$family_name} = $pkg;
}

sub new
{
   my $class = shift;
   $class->SUPER::new( Protocol => NETLINK_GENERIC, @_ );
}

sub configure
{
   my $self = shift;
   my ( $arg ) = @_;

   my $ret = $self->SUPER::configure( $arg );

   my $class = ref $self;
   if( $class ne __PACKAGE__ ) {
      defined( my $family_name = $pkg2familyname{$class} ) or
         croak "No family name defined for $class";

      my $family_id = $self->get_family_by_name( $family_name )->{id};
      $class->message_class->register_nlmsg_type( $family_id );

      ${*$self}{default_nlmsg_type} = $family_id;
   }

   return $ret;
}

sub new_message
{
   my $self = shift;

   $self->SUPER::new_message(
      ( defined ${*$self}{default_nlmsg_type} ? ( nlmsg_type => ${*$self}{default_nlmsg_type} ) : () ),
      @_,
   );
}

sub new_command
{
   my $self = shift;

   $self->SUPER::new_command(
      ( defined ${*$self}{default_nlmsg_type} ? ( nlmsg_type => ${*$self}{default_nlmsg_type} ) : () ),
      @_,
   );
}

sub message_class
{
   return "IO::Socket::Netlink::Generic::_Message";
}

=head1 METHODS

=cut

=head2 get_family_by_name

   $family = $sock->get_family_by_name( $name )

=cut

sub get_family_by_name
{
   my $self = shift;
   my ( $name ) = @_;

   return $self->_get_family( name => $name );
}

=head2 get_family_by_id

   $family = $sock->get_family_by_id( $id )

=cut

sub get_family_by_id
{
   my $self = shift;
   my ( $id ) = @_;

   return $self->_get_family( id => $id );
}

=pod

Query the kernel for information on the C<NETLINK_GENERIC> family specifed by
name or ID number, and return information about it. Returns a HASH reference
containing the following fields:

=over 8

=item id => NUMBER

=item name => STRING

=item version => NUMBER

=item hdrsize => NUMBER

=item maxattr => NUMBER

=back

=cut

sub _get_family
{
   my $self = shift;
   my %searchattrs = @_;

   $self->send_nlmsg( $self->new_request(
      nlmsg_type  => NETLINK_GENERIC,

      cmd  => CTRL_CMD_GETFAMILY,
      nlattrs => \%searchattrs,
   ) ) or croak "Cannot send - $!";

   $self->recv_nlmsg( my $message, 32768 ) or
      croak "Cannot recv - $!";

   $message->nlmsg_type == NETLINK_GENERIC or
      croak "Expected nlmsg_type == NETLINK_GENERIC";

   return $message->nlattrs;
}

package IO::Socket::Netlink::Generic::_Message;

use base qw( IO::Socket::Netlink::_Message );

use Carp;

use Socket::Netlink::Generic qw(
   :DEFAULT
   pack_genlmsghdr unpack_genlmsghdr
);

=head1 MESSAGE OBJECTS

Sockets in this class provide the following extra field accessors on their
message objects:

=cut

__PACKAGE__->is_subclassed_by_type;

__PACKAGE__->register_nlmsg_type( NETLINK_GENERIC );

=over 8

=item * $message->cmd

ID number of the command to give to the family

=item * $message->version

Version number of the interface

=item * $message->genlmsg

Accessor for the trailing data buffer; intended for subclasses to use

=back

=cut

__PACKAGE__->is_header(
   data => "nlmsg",
   fields => [
      [ cmd     => 'decimal' ],
      [ version => 'decimal' ],
      [ genlmsg => 'bytes' ],
   ],
   pack   => \&pack_genlmsghdr,
   unpack => \&unpack_genlmsghdr,
);

sub nlmsg_string
{
   my $self = shift;
   return sprintf "cmd=%d,version=%d,%s", $self->cmd, $self->version, $self->genlmsg_string;
}

sub genlmsg_string
{
   my $self = shift;
   return sprintf "{%d bytes}", length $self->genlmsg;
}

__PACKAGE__->has_nlattrs(
   "genlmsg",
   id      => [ CTRL_ATTR_FAMILY_ID,   "u16" ],
   name    => [ CTRL_ATTR_FAMILY_NAME, "asciiz" ],
   version => [ CTRL_ATTR_VERSION,     "u32" ],
   hdrsize => [ CTRL_ATTR_HDRSIZE,     "u32" ],
   maxattr => [ CTRL_ATTR_MAXATTR,     "u32" ],
);

=head1 SEE ALSO

=over 4

=item *

L<Socket::Netlink::Generic> - interface to Linux's C<NETLINK_GENERIC> netlink
socket protocol

=item *

L<IO::Socket::Netlink> - Object interface to C<AF_NETLINK> domain sockets

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
