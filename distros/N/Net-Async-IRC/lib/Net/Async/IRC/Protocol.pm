#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2015 -- leonerd@leonerd.org.uk

package Net::Async::IRC::Protocol;

use strict;
use warnings;

our $VERSION = '0.11';

use base qw( IO::Async::Stream Protocol::IRC );

use Carp;

use Protocol::IRC::Message;

use Encode qw( find_encoding );
use Time::HiRes qw( time );

use IO::Async::Timer::Countdown;

=head1 NAME

C<Net::Async::IRC::Protocol> - send and receive IRC messages

=head1 DESCRIPTION

This subclass of L<IO::Async::Stream> implements an established IRC
connection that has already completed its inital login sequence and is ready
to send and receive IRC messages. It handles base message sending and
receiving, and implements ping timers. This class provides most of the
functionality required for sending and receiving IRC commands and responses
by mixing in from L<Protocol::IRC>.

Objects of this type would not normally be constructed directly. For IRC
clients, see L<Net::Async::IRC> which is a subclass of it. All the events,
parameters, and methods documented below are relevant there.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or C<CODE>
references in parameters:

=head2 $handled = on_message

=head2 $handled = on_message_MESSAGE

Invoked on receipt of a valid IRC message. See C<MESSAGE HANDLING> below.

=head2 on_irc_error $err

Invoked on receipt of an invalid IRC message if parsing fails. C<$err> is the
error message text. If left unhandled, any parse error will result in the
connection being immediataely closed, followed by the exception being
re-thrown.

=head2 on_ping_timeout

Invoked if the peer fails to respond to a C<PING> message within the given
timeout.

=head2 on_pong_reply $lag

Invoked when the peer successfully sends a C<PONG> reply response to a C<PING>
message. C<$lag> is the response time in (fractional) seconds.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item on_message => CODE

=item on_message_MESSAGE => CODE

=item on_irc_error => CODE

=item on_ping_timeout => CODE

=item on_pong_reply => CODE

C<CODE> references for event handlers.

=item pingtime => NUM

Amount of quiet time, in seconds, after a message is received from the peer,
until a C<PING> will be sent to check it is still alive.

=item pongtime => NUM

Timeout, in seconds, after sending a C<PING> message, to wait for a C<PONG>
response.

=item encoding => STRING

If supplied, sets an encoding to use to encode outgoing messages and decode
incoming messages.

=back

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $irc = Net::Async::IRC::Protocol->new( %args )

Returns a new instance of a C<Net::Async::IRC::Protocol> object. This object
represents a IRC connection to a peer.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $on_closed = delete $args{on_closed};

   return $class->SUPER::new(
      %args,

      on_closed => sub {
         my $self = shift;

         my $loop = $self->get_loop;

         $self->{pingtimer}->stop;
         $self->{pongtimer}->stop;

         $on_closed->( $self ) if $on_closed;

         undef $self->{connect_f};
         undef $self->{login_f};
      },
   );
}

sub _init
{
   my $self = shift;
   $self->SUPER::_init( @_ );

   my $pingtime = 60;
   my $pongtime = 10;

   $self->{pingtimer} = IO::Async::Timer::Countdown->new(
      delay => $pingtime,

      on_expire => sub {
         my $now = time();

         $self->send_message( "PING", undef, "$now" );

         $self->{ping_send_time} = $now;

         $self->{pongtimer}->start;
      },
   );
   $self->add_child( $self->{pingtimer} );

   $self->{pongtimer} = IO::Async::Timer::Countdown->new(
      delay => $pongtime,

      on_expire => sub {
         $self->{on_ping_timeout}->( $self ) if $self->{on_ping_timeout};
      },
   );
   $self->add_child( $self->{pongtimer} );
}

# for Protocol::IRC
sub encoder
{
   my $self = shift;
   return $self->{encoder};
}

sub configure
{
   my $self = shift;
   my %args = @_;

   $self->{$_} = delete $args{$_} for grep m/^on_message/, keys %args;

   for (qw( on_ping_timeout on_pong_reply on_irc_error )) {
      $self->{$_} = delete $args{$_} if exists $args{$_};
   }

   if( exists $args{pingtime} ) {
      $self->{pingtimer}->configure( delay => delete $args{pingtime} );
   }

   if( exists $args{pongtime} ) {
      $self->{pongtimer}->configure( delay => delete $args{pongtime} );
   }

   if( exists $args{encoding} ) {
      my $encoding = delete $args{encoding};
      my $obj = find_encoding( $encoding );
      defined $obj or croak "Cannot handle an encoding of '$encoding'";
      $self->{encoder} = $obj;
   }

   $self->SUPER::configure( %args );
}

sub incoming_message
{
   my $self = shift;
   my ( $message ) = @_;

   my @shortargs = ( $message->arg( 0 ) );
   push @shortargs, $message->arg( 1 ) if $message->command =~ m/^\d+$/;
   push @shortargs, "..." if $message->args > 1;

   $self->debug_printf( "COMMAND ${\ $message->command } @shortargs" );

   return $self->SUPER::incoming_message( @_ );
}

=head1 METHODS

=cut

=head2 is_connected

   $connect = $irc->is_connected

Returns true if a connection to the peer is established. Note that even
after a successful connection, the connection may not yet logged in to. See
also the C<is_loggedin> method.

=cut

sub is_connected
{
   my $self = shift;
   return 0 unless my $connect_f = $self->{connect_f};
   return $connect_f->is_ready && !$connect_f->failure;
}

=head2 is_loggedin

   $loggedin = $irc->is_loggedin

Returns true if the full login sequence has been performed on the connection
and it is ready to use.

=cut

sub is_loggedin
{
   my $self = shift;
   return 0 unless my $login_f = $self->{login_f};
   return $login_f->is_ready && !$login_f->failure;
}

sub on_read
{
   my $self = shift;
   my ( $buffref, $eof ) = @_;

   my $pingtimer = $self->{pingtimer};

   $pingtimer->is_running ? $pingtimer->reset : $pingtimer->start;

   eval {
      $self->Protocol::IRC::on_read( $$buffref );
      1;
   } and return 0;

   my $e = "$@"; chomp $e;

   $self->maybe_invoke_event( on_irc_error => $e )
      and return 0;

   $self->close_now;
   die "$e\n";
}

=head2 nick

   $nick = $irc->nick

Returns the current nick in use by the connection.

=cut

sub _set_nick
{
   my $self = shift;
   ( $self->{nick} ) = @_;
   $self->{nick_folded} = $self->casefold_name( $self->{nick} );
}

sub nick
{
   my $self = shift;
   return $self->{nick};
}

=head2 nick_folded

   $nick_folded = $irc->nick_folded

Returns the current nick in use by the connection, folded by C<casefold_name>
for convenience.

=cut

sub nick_folded
{
   my $self = shift;
   return $self->{nick_folded};
}

=head1 MESSAGE HANDLING

Every incoming message causes a sequence of message handling to occur. First,
the message is parsed, and a hash of data about it is created; this is called
the hints hash. The message and this hash are then passed down a sequence of
potential handlers.

Each handler indicates by return value, whether it considers the message to
have been handled. Processing of the message is not interrupted the first time
a handler declares to have handled a message. Instead, the hints hash is
marked to say it has been handled. Later handlers can still inspect the
message or its hints, using this information to decide if they wish to take
further action.

A message with a command of C<COMMAND> will try handlers in following places:

=over 4

=item 1.

A CODE ref in a parameter called C<on_message_COMMAND>

 $on_message_COMMAND->( $irc, $message, \%hints )

=item 2.

A method called C<on_message_COMMAND>

 $irc->on_message_COMMAND( $message, \%hints )

=item 3.

A CODE ref in a parameter called C<on_message>

 $on_message->( $irc, 'COMMAND', $message, \%hints )

=item 4.

A method called C<on_message>

 $irc->on_message( 'COMMAND', $message, \%hints )

=back

As this message handling ability is provided by C<Protocol::IRC>, more details
about how it works and how to use it can be found at
L<Protocol::IRC/MESSAGE HANDLING>.

Additionally, some types of messages receive further processing by
C<Protocol::IRC> and in turn cause new types of events to be invoked. These
are further documented by L<Protocol::IRC/INTERNAL MESSAGE HANDLING>.

=cut

sub invoke
{
   my $self = shift;
   my $retref = $self->maybe_invoke_event( @_ ) or return undef;
   return $retref->[0];
}

sub on_message_PONG
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   return 1 unless $self->{pongtimer}->is_running;

   my $lag = time - $self->{ping_send_time};

   $self->{current_lag} = $lag;
   $self->{on_pong_reply}->( $self, $lag ) if $self->{on_pong_reply};

   $self->{pongtimer}->stop;

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
