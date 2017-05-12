#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2017 -- leonerd@leonerd.org.uk

package Protocol::IRC;

use strict;
use warnings;

our $VERSION = '0.12';

use Carp;
use Scalar::Util qw( blessed );

use Protocol::IRC::Message;

# This should be mixed in MI-style

=head1 NAME

C<Protocol::IRC> - IRC protocol handling

=head1 DESCRIPTION

This mix-in class provides a base layer of IRC message handling logic. It
allows reading of IRC messages from a string buffer and dispatching them to
handler methods on its instance.

L<Protocol::IRC::Client> provides an extension to this logic that may be more
convenient for IRC client implementations. Much of the code provided here is
still useful in client applications, so the reader should be familiar with
both modules.

=head1 MESSAGE HANDLING

Every incoming message causes a sequence of message handling to occur. First,
the message is parsed, and a hash of data about it is created; this is called
the hints hash. The message and this hash are then passed down a sequence of
potential handlers.

Each handler indicates by return value, whether it considers the message to
have been handled. Processing of the message is not interrupted the first time
a handler declares to have handled a message. Instead, the hints hash is marked
to say it has been handled. Later handlers can still inspect the message or its
hints, using this information to decide if they wish to take further action.

A message with a command of C<COMMAND> will try handlers in following places:

=over 4

=item 1.

A method called C<on_message_COMMAND>

 $irc->on_message_COMMAND( $message, \%hints )

=item 2.

A method called C<on_message>

 $irc->on_message( 'COMMAND', $message, \%hints )

=back

For server numeric replies, if the numeric reply has a known name, it will be
attempted first at its known name, before falling back to the numeric if it
was not handled. Unrecognised numerics will be attempted only at their numeric
value.

Because of the wide variety of messages in IRC involving various types of data
the message handling specific cases for certain types of message, including
adding extra hints hash items, or invoking extra message handler stages. These
details are noted here.

Many of these messages create new events; called synthesized messages. These
are messages created by the C<Protocol::IRC> object itself, to better
represent some of the details derived from the primary ones from the server.
These events all take lower-case command names, rather than capitals, and will
have a C<synthesized> key in the hints hash, set to a true value. These are
dispatched and handled identically to regular primary events, detailed above.

If any handler of the synthesized message returns true, then this marks the
primary message handled as well.

If a message is received that has a gating disposition, extra processing is
applied to it before the processing above. The effect on its gate is given as
a string (one of C<more>, C<done>, C<fail>) to handlers in the following
places:

=over 4

=item 1.

A method called C<on_message_gate_EFFECT_GATE>

 $irc->on_message_gate_EFFECT_GATE( $message, \%hints )

=item 2.

A method called C<on_message_gate_EFFECT>

 $irc->on_message_gate_EFFECT( 'GATE', $message, \%hints )

=item 3.

A method called C<on_message_gate>

 $irc->on_message_gate( 'EFFECT', 'GATE', $message, \%hints )

=back

=head2 Message Hints

When messages arrive they are passed to the appropriate message handling
method, which the implementation may define. As well as the message, a hash
of extra information derived from or relating to the message is also given.

The following keys will be present in any message hint hash:

=over 8

=item handled => BOOL

Initially false. Will be set to true the first time a handler returns a true
value.

=item prefix_nick => STRING

=item prefix_user => STRING

=item prefix_host => STRING

Values split from the message prefix; see the C<Protocol::IRC::Message>
C<prefix_split> method.

=item prefix_name => STRING

Usually the prefix nick, or the hostname in case the nick isn't defined
(usually on server messages).

=item prefix_is_me => BOOL

True if the nick mentioned in the prefix refers to this connection.

=back

Added to this set, will be all the values returned by the message's
C<named_args> method. Some of these values may cause yet more values to be
generated.

If the message type defines a C<target_name>:

=over 8

=item * target_type => STRING

Either C<channel> or C<user>, as returned by C<classify_name>.

=item * target_is_me => BOOL

True if the target name is a user and refers to this connection.

=back

Any key whose name ends in C<_nick> or C<_name> will have a corresponding key
added with C<_folded> suffixed on its name, containing the value casefolded
using C<casefold_name>. This is for the convenience of string comparisons,
hash keys, etc..

Any of these keys that are not the C<prefix_name> will additionally have a
corresponding key with C<_is_me> replacing the C<_nick> or C<_name>,
containing the boolean result of calling the C<is_nick_me> method on that
name. This makes it simpler to detect commands or results affecting the user
the connection represents.

=cut

=head1 METHODS

=cut

=head2 on_read

   $irc->on_read( $buffer )

Informs the protocol implementation that more bytes have been read from the
peer. This method will modify the C<$buffer> directly, and remove from it the
prefix of bytes it has consumed. Any bytes remaining should be stored by the
caller for next time.

Any messages found in the buffer will be passed, in sequence, to the
C<incoming_message> method.

=cut

sub on_read
{
   my $self = shift;
   # buffer in $_[0]

   while( $_[0] =~ s/^(.*)\x0d\x0a// ) {
      my $line = $1;
      # Ignore blank lines
      next if !length $line;

      $self->incoming_message( Protocol::IRC::Message->new_from_line( $line ) );
   }
}

=head2 incoming_message

   $irc->incoming_message( $message )

Invoked by the C<on_read> method for every incoming IRC message. This method
implements the actual dispatch into various handler methods as described in
the L</MESSAGE HANDLING> section above.

This method is exposed so that subclasses can override it, primarily to wrap
extra logic before or after the main dispatch (e.g. for logging or other
processing).

=cut

sub incoming_message
{
   my $self = shift;
   my ( $message ) = @_;

   my $command = $message->command_name;

   my ( $prefix_nick, $prefix_user, $prefix_host ) = $message->prefix_split;

   my $hints = {
      handled => 0,

      prefix_nick  => $prefix_nick,
      prefix_user  => $prefix_user,
      prefix_host  => $prefix_host,
      # Most of the time this will be "nick", except for special messages from the server
      prefix_name  => defined $prefix_nick ? $prefix_nick : $prefix_host,
   };

   if( my $named_args = $message->named_args ) {
      $hints->{$_} = $named_args->{$_} for keys %$named_args;
   }

   if( defined $hints->{text} and my $encoder = $self->encoder ) {
      $hints->{text} = $encoder->decode( $hints->{text} );
   }

   if( defined( my $target_name = $hints->{target_name} ) ) {
      my $target_type = $self->classify_name( $target_name );
      $hints->{target_type} = $target_type;
   }

   my $prepare_method = "prepare_hints_$command";
   $self->$prepare_method( $message, $hints ) if $self->can( $prepare_method );

   foreach my $k ( grep { m/_nick$/ or m/_name$/ } keys %$hints ) {
      $hints->{"${k}_folded"} = $self->casefold_name( my $name = $hints->{$k} );
      defined $name or next;
      $k eq "prefix_name" and next;

      ( my $knew = $k ) =~ s/_name$|_nick$/_is_me/;
      $hints->{$knew} = $self->is_nick_me( $name );
   }

   if( my $disp = $message->gate_disposition ) {
      my ( $type, $gate ) = $disp =~ m/^([-+!*])(.*)$/;
      my $effect = ( $type eq "-" ? "more" :
                     $type eq "+" ? "done" :
                     $type eq "!" ? "fail" :
                     $type eq "*" ? ( $hints->{prefix_is_me} ? "done" : undef ) :
                     die "TODO" );

      if( defined $effect ) {
         $self->invoke( "on_message_gate_${effect}_$gate", $message, $hints ) and $hints->{handled} = 1;
         $self->invoke( "on_message_gate_$effect", $gate, $message, $hints ) and $hints->{handled} = 1;
         $self->invoke( "on_message_gate", $effect, $gate, $message, $hints ) and $hints->{handled} = 1;
      }
   }

   $self->invoke( "on_message_$command", $message, $hints ) and $hints->{handled} = 1;
   $self->invoke( "on_message", $command, $message, $hints ) and $hints->{handled} = 1;

   if( !$hints->{handled} and $message->command ne $command ) { # numerics
      my $numeric = $message->command;
      $self->invoke( "on_message_$numeric", $message, $hints ) and $hints->{handled} = 1;
      $self->invoke( "on_message", $numeric, $message, $hints ) and $hints->{handled} = 1;
   }
}

=head2 send_message

This method takes arguments in three different forms, depending on their
number and type.

If the first argument is a reference then it must contain a
C<Protocol::IRC::Message> instance which will be sent directly:

   $irc->send_message( $message )

Otherwise, the first argument must be a plain string that gives the command
name. If the second argument is a hash, it provides named arguments in a form
similar to L<Protocol::IRC::Message/new_from_named_args>, otherwise the
remaining arguments must be the prefix string and other positional arguments,
as plain strings:

   $irc->send_message( $command, { %args } )

   $irc->send_message( $command, $prefix, @args )

=head3 Named Argument Mangling

For symmetry with incoming message processing, this method applies some
adjustment of named arguments for convenience of callers.

=over 4

=item *

Callers may define a named argument of C<target>; it will be renamed to
C<target_name>.

=item *

If a named argument of C<text> is defined and an L</encoder> exists, the
argument value will be encoded using this encoder.

=back

=cut

sub send_message
{
   my $self = shift;

   my $message;

   if( @_ == 1 ) {
      $message = shift;
      blessed $message and $message->isa( "Protocol::IRC::Message" ) or
         croak "Expected an instance of Protocol::IRC::Message";
   }
   else {
      my $command = shift;
      ref $command and
         croak "Expected \$command to be a plain string";

      if( @_ == 1 and ref $_[0] ) {
         my %args = %{ $_[0] };

         $args{target_name} = delete $args{target} if defined $args{target};

         if( defined $args{text} and my $encoder = $self->encoder ) {
            $args{text} = $encoder->encode( $args{text} );
         }

         $message = Protocol::IRC::Message->new_from_named_args( $command, %args );
      }
      else {
         my ( $prefix, @args ) = @_;

         if( my $encoder = $self->encoder ) {
            my $argnames = Protocol::IRC::Message->arg_names( $command );

            if( defined( my $i = $argnames->{text} ) ) {
               $args[$i] = $encoder->encode( $args[$i] ) if defined $args[$i];
            }
         }

         $message = Protocol::IRC::Message->new( $command, $prefix, @args );
      }
   }

   $self->write( $message->stream_to_line . "\x0d\x0a" );
}

=head2 send_ctcp

   $irc->send_ctcp( $prefix, $target, $verb, $argstr )

Shortcut to sending a CTCP message. Sends a PRIVMSG to the given target,
containing the given verb and argument string.

=cut

sub send_ctcp
{
   my $self = shift;
   my ( $prefix, $target, $verb, $argstr ) = @_;

   $self->send_message( "PRIVMSG", undef, $target, "\001$verb $argstr\001" );
}

=head2 send_ctcprely

   $irc->send_ctcprely( $prefix, $target, $verb, $argstr )

Shortcut to sending a CTCP reply. As C<send_ctcp> but using a NOTICE instead.

=cut

sub send_ctcpreply
{
   my $self = shift;
   my ( $prefix, $target, $verb, $argstr ) = @_;

   $self->send_message( "NOTICE", undef, $target, "\001$verb $argstr\001" );
}

=head1 ISUPPORT-DRIVEN UTILITIES

The following methods are controlled by the server information given in the
C<ISUPPORT> settings. They use the C<isupport> required method to query the
information required.

=cut

=head2 casefold_name

   $name_folded = $irc->casefold_name( $name )

Returns the C<$name>, folded in case according to the server's C<CASEMAPPING>
C<ISUPPORT>. Such a folded name will compare using C<eq> according to whether the
server would consider it the same name.

Useful for use in hash keys or similar.

=cut

sub casefold_name
{
   my $self = shift;
   my ( $nick ) = @_;

   return undef unless defined $nick;

   my $mapping = lc( $self->isupport( "CASEMAPPING" ) || "" );

   # Squash the 'capital' [\] into lowercase {|}
   $nick =~ tr/[\\]/{|}/ if $mapping ne "ascii";

   # Most RFC 1459 implementations also squash ^ to ~, even though the RFC
   # didn't mention it
   $nick =~ tr/^/~/ unless $mapping eq "strict-rfc1459";

   return lc $nick;
}

=head2 cmp_prefix_flags

   $cmp = $irc->cmp_prefix_flags( $lhs, $rhs )

Compares two channel occupant prefix flags, and returns a signed integer to
indicate which of them has higher priviledge, according to the server's
ISUPPORT declaration. Suitable for use in a C<sort()> function or similar.

=cut

sub cmp_prefix_flags
{
   my $self = shift;
   my ( $lhs, $rhs ) = @_;

   return undef unless defined $lhs and defined $rhs;

   # As a special case, compare emptystring as being lower than voice
   return 0 if $lhs eq "" and $rhs eq "";
   return 1 if $rhs eq "";
   return -1 if $lhs eq "";

   my $PREFIX_FLAGS = $self->isupport( 'prefix_flags' );

   ( my $lhs_index = index $PREFIX_FLAGS, $lhs ) > -1 or return undef;
   ( my $rhs_index = index $PREFIX_FLAGS, $rhs ) > -1 or return undef;

   # IRC puts these in greatest-first, so we need to swap the ordering here
   return $rhs_index <=> $lhs_index;
}

=head2 cmp_prefix_modes

   $cmp = $irc->cmp_prefix_modes( $lhs, $rhs )

Similar to C<cmp_prefix_flags>, but compares channel occupant C<MODE> command
flags.

=cut

sub cmp_prefix_modes
{
   my $self = shift;
   my ( $lhs, $rhs ) = @_;

   return undef unless defined $lhs and defined $rhs;

   my $PREFIX_MODES = $self->isupport( "prefix_modes" );

   ( my $lhs_index = index $PREFIX_MODES, $lhs ) > -1 or return undef;
   ( my $rhs_index = index $PREFIX_MODES, $rhs ) > -1 or return undef;

   # IRC puts these in greatest-first, so we need to swap the ordering here
   return $rhs_index <=> $lhs_index;
}

=head2 prefix_mode2flag

   $flag = $irc->prefix_mode2flag( $mode )

Converts a channel occupant C<MODE> flag (such as C<o>) into a name prefix
flag (such as C<@>).

=cut

sub prefix_mode2flag
{
   my $self = shift;
   my ( $mode ) = @_;

   return $self->isupport( 'prefix_map_m2f' )->{$mode};
}

=head2 prefix_flag2mode

   $mode = $irc->prefix_flag2mode( $flag )

The inverse of C<prefix_mode2flag>.

=cut

sub prefix_flag2mode
{
   my $self = shift;
   my ( $flag ) = @_;

   return $self->isupport( 'prefix_map_f2m' )->{$flag};
}

=head2 classify_name

   $classification = $irc->classify_name( $name )

Returns C<channel> if the given name matches the pattern of names allowed for
channels according to the server's C<CHANTYPES> C<ISUPPORT>. Returns C<user>
if not.

=cut

sub classify_name
{
   my $self = shift;
   my ( $name ) = @_;

   return "channel" if $name =~ $self->isupport( "channame_re" );
   return "user"; # TODO: Perhaps we can be a bit stricter - only check for valid nick chars?
}

=head2 is_nick_me

   $me = $irc->is_nick_me( $nick )

Returns true if the given nick refers to that in use by the connection.

=cut

sub is_nick_me
{
   my $self = shift;
   my ( $nick ) = @_;

   return $self->casefold_name( $nick ) eq $self->nick_folded;
}

=head1 INTERNAL MESSAGE HANDLING

The following messages are handled internally by C<Protocol::IRC>.

=cut

=head2 PING

C<PING> messages are automatically replied to with C<PONG>.

=cut

sub on_message_PING
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   $self->send_message( "PONG", undef, $message->named_args->{text} );

   return 1;
}

=head2 NOTICE and PRIVMSG

Because C<NOTICE> and C<PRIVMSG> are so similar, they are handled together by
synthesized events called C<text>, C<ctcp> and C<ctcpreply>. Depending on the
contents of the text, and whether it was supplied in a C<PRIVMSG> or a
C<NOTICE>, one of these three events will be created. 

In all cases, the hints hash will contain a C<is_notice> key being true or
false, depending on whether the original messages was a C<NOTICE> or a
C<PRIVMSG>, a C<target_name> key containing the message target name, a
case-folded version of the name in a C<target_name_folded> key, and a
classification of the target type in a C<target_type> key.

For the C<user> target type, it will contain a boolean in C<target_is_me> to
indicate if the target of the message is the user represented by this
connection.

For the C<channel> target type, it will contain a C<restriction> key
containing the channel message restriction, if present.

For normal C<text> messages, it will contain a key C<text> containing the
actual message text.

For either CTCP message type, it will contain keys C<ctcp_verb> and
C<ctcp_args> with the parsed message. The C<ctcp_verb> will contain the first
space-separated token, and C<ctcp_args> will be a string containing the rest
of the line, otherwise unmodified. This type of message is also subject to a
special stage of handler dispatch, involving the CTCP verb string. For
messages with C<VERB> as the verb, the following are tried. C<CTCP> may stand
for either C<ctcp> or C<ctcpreply>.

=over 4

=item 1.

A method called C<on_message_CTCP_VERB>

 $irc->on_message_CTCP_VERB( $message, \%hints )

=item 2.

A method called C<on_message_CTCP>

 $irc->on_message_CTCP( 'VERB', $message, \%hintss )

=item 3.

A method called C<on_message>

 $irc->on_message( 'CTCP VERB', $message, \%hints )

=back

=cut

sub on_message_NOTICE
{
   my $self = shift;
   my ( $message, $hints ) = @_;
   return $self->_on_message_text( $message, $hints, 1 );
}

sub on_message_PRIVMSG
{
   my $self = shift;
   my ( $message, $hints ) = @_;
   return $self->_on_message_text( $message, $hints, 0 );
}

sub _on_message_text
{
   my $self = shift;
   my ( $message, $hints, $is_notice ) = @_;

   my %hints = (
      %$hints,
      synthesized => 1,
      is_notice => $is_notice,
   );

   # TODO: In client->server messages this might be a comma-separated list
   my $target = delete $hints{targets};

   my $prefixflag_re = $self->isupport( 'prefixflag_re' );

   my $restriction = "";
   while( $target =~ m/^$prefixflag_re/ ) {
      $restriction .= substr( $target, 0, 1, "" );
   }

   $hints{target_name} = $target;
   $hints{target_name_folded} = $self->casefold_name( $target );

   my $type = $hints{target_type} = $self->classify_name( $target );

   if( $type eq "channel" ) {
      $hints{restriction} = $restriction;
      $hints{target_is_me} = '';
   }
   elsif( $type eq "user" ) {
      # TODO: user messages probably can't have restrictions. What to do
      # if we got one?
      $hints{target_is_me} = $self->is_nick_me( $target );
   }

   my $text = $hints->{text};

   if( $text =~ m/^\x01(.*)\x01$/ ) {
      ( my $verb, $text ) = split( m/ /, $1, 2 );
      $hints{ctcp_verb} = $verb;
      $hints{ctcp_args} = $text;

      my $ctcptype = $is_notice ? "ctcpreply" : "ctcp";

      $self->invoke( "on_message_${ctcptype}_$verb", $message, \%hints ) and $hints{handled} = 1;
      $self->invoke( "on_message_${ctcptype}", $verb, $message, \%hints ) and $hints{handled} = 1;
      $self->invoke( "on_message", "$ctcptype $verb", $message, \%hints ) and $hints{handled} = 1;
   }
   else {
      $hints{text} = $text;

      $self->invoke( "on_message_text", $message, \%hints ) and $hints{handled} = 1;
      $self->invoke( "on_message", "text", $message, \%hints ) and $hints{handled} = 1;
   }

   return $hints{handled};
}

=head1 REQUIRED METHODS

As this class is an abstract base class, a concrete implementation must
provide the following methods to complete it and make it useable.

=cut

=head2 write

   $irc->write( $string )

Requests the byte string to be sent to the peer

=cut

sub write { croak "Attemped to invoke abstract ->write on " . ref $_[0] }

=head2 encoder

   $encoder = $irc->encoder

Optional. If supplied, returns an L<Encode> object used to encode or decode
the bytes appearing in a C<text> field of a message. If set, all text strings
will be returned, and should be given, as Unicode strings. They will be
encoded or decoded using this object.

=cut

sub encoder { undef }

=head2 invoke

   $result = $irc->invoke( $name, @args )

Optional. If provided, invokes the message handling routine called C<$name>
with the given arguments. A default implementation is provided which simply
attempts to invoke a method of the given name, or return false if no method
of that name exists.

If an implementation does override this method, care should be taken to ensure
that methods are tested for and invoked if present, in addition to any other
work the method wishes to perform, as this is the basis by which derived
message handling works.

=cut

sub invoke
{
   my $self = shift;
   my ( $name, @args ) = @_;
   return unless $self->can( $name );
   return $self->$name( @args );
}

=head2 isupport

   $value = $irc->isupport( $field )

Should return the value of the given C<ISUPPORT> field.

As well as the all-capitals server-supplied fields, the following fields may
be requested. Their names are all lowercase and contain underscores, to
distinguish them from server-supplied fields.

=over 8

=item prefix_modes => STRING

The mode characters from C<PREFIX> (e.g. C<ohv>)

=item prefix_flags => STRING

The flag characters from C<PREFIX> (e.g. C<@%+>)

=item prefixflag_re => Regexp

A precompiled regexp that matches any of the prefix flags

=item prefix_map_m2f => HASH

A map from mode characters to flag characters

=item prefix_map_f2m => HASH

A map from flag characters to mode characters

=item chanmodes_list => ARRAY

A 4-element array containing the split portions of C<CHANMODES>;

 [ $listmodes, $argmodes, $argsetmodes, $boolmodes ]

=item channame_re => Regexp

A precompiled regexp that matches any string beginning with a channel prefix
character in C<CHANTYPES>.

=back

=cut

sub isupport { croak "Attempted to invoke abstract ->isupport on " . ref $_[0] }

=head2 nick

   $nick = $irc->nick

Should return the current nick in use by the connection.

=head2 nick_folded

   $nick_folded = $irc->nick_folded

Optional. If supplied, should return the current nick as case-folded by the
C<casefold_name> method. If not provided, this will be performed by 
case-folding the result from C<nick>.

=cut

sub nick        { croak "Attempted to invoke abstract ->nick on " . ref $_[0] }
sub nick_folded { $_[0]->casefold_name( $_[0]->nick ) }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
