#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2017 -- leonerd@leonerd.org.uk

package Protocol::IRC::Client;

use strict;
use warnings;
use 5.010; # //
use base qw( Protocol::IRC );

our $VERSION = '0.12';

use Carp;

=head1 NAME

C<Protocol::IRC::Client> - IRC protocol handling for a client

=head1 DESCRIPTION

This mix-in class provides a layer of IRC message handling logic suitable for
an IRC client. It builds upon L<Protocol::IRC> to provide extra message
processing useful to IRC clients, such as handling inbound server numerics.

It provides some of the methods required by C<Protocol::IRC>:

=over 4

=item * isupport

=back

=cut

=head1 INHERITED METHODS

The following methods, inherited from L<Protocol::IRC>, are notable here as
being particularly useful for a client.

=head2 send_message

   $irc->send_message( $message )
   $irc->send_message( $command, { %args } )
   $irc->send_message( $command, $prefix, @args )

See L<Protocol::IRC/send_message>

=cut

=head1 METHODS

=cut

=head2 isupport

   $value = $irc->isupport( $key )

Returns an item of information from the server's C<005 ISUPPORT> lines.
Traditionally IRC servers use all-capital names for keys.

=cut

# A few hardcoded defaults from RFC 2812
my %ISUPPORT = (
   channame_re => qr/^[#&]/,
   prefixflag_re => qr/^[\@+]/,
   chanmodes_list => [qw( b k l imnpst )], # TODO: ov
);

sub isupport
{
   my $self = shift;
   my ( $field ) = @_;
   return $self->{Protocol_IRC_isupport}->{$field} // $ISUPPORT{$field};
}

sub on_message_RPL_ISUPPORT
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $isupport = $self->{Protocol_IRC_isupport} ||= {};

   foreach my $entry ( @{ $hints->{isupport} } ) {
      my ( $name, $value ) = $entry =~ m/^([A-Z]+)(?:=(.*))?$/;

      $value = 1 if !defined $value;

      $isupport->{$name} = $value;

      if( $name eq "PREFIX" ) {
         my $prefix = $value;

         my ( $prefix_modes, $prefix_flags ) = $prefix =~ m/^\(([a-z]+)\)(.+)$/i
            or warn( "Unable to parse PREFIX=$value" ), next;

         $isupport->{prefix_modes} = $prefix_modes;
         $isupport->{prefix_flags} = $prefix_flags;

         $isupport->{prefixflag_re} = qr/[$prefix_flags]/;

         my %prefix_map;
         $prefix_map{substr $prefix_modes, $_, 1} = substr $prefix_flags, $_, 1 for ( 0 .. length($prefix_modes) - 1 );

         $isupport->{prefix_map_m2f} = \%prefix_map;
         $isupport->{prefix_map_f2m} = { reverse %prefix_map };
      }
      elsif( $name eq "CHANMODES" ) {
         $isupport->{chanmodes_list} = [ split( m/,/, $value ) ];
      }
      elsif( $name eq "CASEMAPPING" ) {
         # TODO
         # $self->{nick_folded} = $self->casefold_name( $self->{nick} );
      }
      elsif( $name eq "CHANTYPES" ) {
         $isupport->{channame_re} = qr/^[$value]/;
      }
   }

   return 0;
}

=head2 server_info

   $info = $irc->server_info( $key )

Returns an item of information from the server's C<004> line. C<$key> should
one of

=over 8

=item * host

=item * version

=item * usermodes

=item * channelmodes

=back

=cut

sub server_info
{
   my $self = shift;
   my ( $key ) = @_;

   return $self->{Protocol_IRC_server_info}{$key};
}

sub on_message_RPL_MYINFO
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   @{$self->{Protocol_IRC_server_info}}{qw( host version usermodes channelmodes )} =
      @{$hints}{qw( serverhost serverversion usermodes channelmodes )};

   return 0;
}

=head1 GATING MESSAGES

If messages with a gating disposition are received, extra processing is
applied. Messages whose gating effect is C<more> are simply collected up by
pushing the hints hash to an array. Added to this hash is the command name
itself, so that in the case of multiple message types (for example C<WHOIS>
replies) the individual messages can still be identified.

When the effect of C<done> or C<fail> is eventually received, this collected
array is passed as C<$data> to a handler in one of the following places:

=over 4

=item 1.

A method called C<on_gate_EFFECT_GATE>

 $client->on_gate_EFFECT_GATE( $message, $hints, $data )

=item 2.

A method called C<on_gate_EFFECT>

 $client->on_gate_EFFECT( 'GATE', $message, $hints, $data )

=item 3.

A method called C<on_gate>

 $client->on_gate( 'EFFECT, 'GATE', $message, $hints, $data )

=item 4.

If the gate effect is C<done>, two more places are tried; looking like regular
event handling on a command whose name is the (lowercase) gate name

 $client->on_message_GATE( $message, $hints )

 $client->on_message( 'GATE', $message, $hints )

=back

For the following types of gate, the C<$data> is further processed in the
following way to provide extra hints fields.

=cut

sub on_message_gate
{
   my $self = shift;
   my ( $effect, $gate, $message, $hints ) = @_;
   my $target = $hints->{target_name_folded} // "*";

   if( $effect eq "more" ) {
      push @{ $self->{Protocol_IRC_gate}{$gate}{$target} }, {
         %$hints,
         command => $message->command_name,
      };
      return 1;
   }

   my $data = delete $self->{Protocol_IRC_gate}{$gate}{$target};

   my @morehints;
   if( $effect eq "done" and my $code = $self->can( "prepare_gatehints_$gate" ) ) {
      @morehints = $self->$code( $data );
   }

   my %hints = (
      %$hints,
      synthesized => 1,
      @morehints,
   );

   my $futures;
   if( $futures = $self->{Protocol_IRC_gate_futures}{$gate}{$target} and @$futures ) {
      my $f = shift @$futures;
      if( $effect eq "done" ) {
         $f->done( $message, \%hints, $data );
      }
      else {
         $f->fail( $hints->{text}, irc_gate => $message, \%hints );
      }
   }

   $self->invoke( "on_gate_${effect}_$gate", $message, \%hints, $data ) and $hints{handled} = 1;
   $self->invoke( "on_gate_$effect", $gate, $message, \%hints, $data ) and $hints{handled} = 1;
   $self->invoke( "on_gate", $effect, $gate, $message, \%hints, $data ) and $hints{handled} = 1;

   if( $effect eq "done" ) {
      $self->invoke( "on_message_$gate", $message, \%hints ) and $hints{handled} = 1;
      $self->invoke( "on_message", $gate, $message, \%hints ) and $hints{handled} = 1;
   }

   return $hints{handled};
}

=head2 who

The hints hash will contain an extra key, C<who>, which will be an ARRAY ref
containing the lines of the WHO reply. Each line will be a HASH reference
containing:

=over 8

=item user_ident

=item user_host

=item user_server

=item user_nick

=item user_nick_folded

=item user_flags

=back

=cut

sub prepare_gatehints_who
{
   my $self = shift;
   my ( $data ) = @_;

   my @who = map {
      my $b = $_;
      +{ map { $_ => $b->{$_} } qw( user_ident user_host user_server user_nick user_nick_folded user_flags ) }
   } @$data;

   return who => \@who;
}

=head2 names

The hints hash will contain an extra key, C<names>, which will be an ARRAY ref
containing the usernames in the channel. Each will be a HASH reference
containing:

=over 8

=item nick

=item flag

=back

=cut

sub prepare_gatehints_names
{
   my $self = shift;
   my ( $data ) = @_;

   my @names = map { @{ $_->{names} } } @$data;

   my $prefixflag_re = $self->isupport( 'prefixflag_re' );
   my $re = qr/^($prefixflag_re)?(.*)$/;

   my %names;

   foreach my $name ( @names ) {
      my ( $flag, $nick ) = $name =~ $re or next;

      $flag ||= ''; # make sure it's defined

      $names{ $self->casefold_name( $nick ) } = { nick => $nick, flag => $flag };
   }

   return names => \%names;
}

=head2 bans

The hints hash will contain an extra key, C<bans>, which will be an ARRAY ref
containing the ban lines. Each line will be a HASH reference containing:

=over 8

=item mask

User mask of the ban

=item by_nick

=item by_nick_folded

Nickname of the user who set the ban

=item timestamp

UNIX timestamp the ban was created

=back

=cut

sub prepare_gatehints_bans
{
   my $self = shift;
   my ( $data ) = @_;

   my @bans = map {
      my $b = $_;
      +{ map { $_ => $b->{$_} } qw( mask by_nick by_nick_folded timestamp ) }
   } @$data;

   return bans => \@bans;
}

=head2 motd

The hints hash will contain an extra key, C<motd>, which will be an ARRAY ref
containing the lines of the MOTD.

=cut

sub prepare_gatehints_motd
{
   my $self = shift;
   my ( $data ) = @_;

   return motd => [ map { $_->{text} } @$data ];
}

=head2 whois

The hints hash will contain an extra key, C<whois>, which will be an ARRAY ref
of entries that mostly relate to the received C<RPL_WHOIS*> numerics.

Each C<RPL_WHOIS*> reply will be stripped of the standard hints hash keys,
leaving whatever remains. Added to this will be a key called C<whois>, whose
value will be the command name, minus the leading C<RPL_WHOIS>, and converted
to lowercase.

=cut

use constant STANDARD_HINTS => qw(
   prefix_nick prefix_nick_folded
   prefix_name prefix_name_folded
   prefix_user
   prefix_host
   target_name target_name_folded
   target_is_me
   target_type
   handled
);

sub prepare_gatehints_whois
{
   my $self = shift;
   my ( $data ) = @_;

   my @whois;
   my $channels;

   foreach my $h ( @$data ) {
      # Just delete all the standard hints from each one
      delete @{$h}{STANDARD_HINTS()};
      ( $h->{whois} = lc delete $h->{command} ) =~ s/^rpl_whois//;

      # Combine all the 'channels' results into one list
      if( $h->{whois} eq "channels" ) {
         if( $channels ) {
            push @{$channels->{channels}}, @{$h->{channels}};
            next;
         }
         $channels = $h;
      }

      push @whois, $h;
   }

   return whois => \@whois;
}

=head2 join

No additional keys.

=cut

# TODO: maybe JOIN gate should wait for initial events?

=head2 next_gate_future

   $f = $client->next_gate_future( $gate, $target )

As an alternative to using the event handlers above, a client can instead
obtain a L<Future> that will succeed or fail the next time a result on a given
gate is received for a given target. This is often more convenient to use in a
client, as it represents the result of running a command.

If the gate completes successfully, then so will the future, yielding the same
values as would be passed to the C<on_gate_done_GATE> event; namely that

   ( $message, $hints, $data ) = $f->get

If the gate fails, then so will the future, containing the text message from
the error numeric as its failure message, C<irc_gate> as its category, and the
full message and hints for it as the details.

=cut

sub next_gate_future
{
   my $self = shift;
   my ( $gate, $target ) = @_;

   $target = $self->casefold_name( $target // "*" );

   my $futures = $self->{Protocol_IRC_gate_futures}{$gate}{$target} //= [];

   my $f = $self->new_future;

   push @$futures, $f;
   $f->on_cancel( sub {
      my ( $f ) = @_;
      @$futures = grep { $_ != $f } @$futures
   });

   return $f;
}

=head1 INTERNAL MESSAGE HANDLING

The following messages are handled internally by C<Protocol::IRC::Client>.

=cut

=head2 CAP

This message takes a sub-verb as its second argument, and a list of capability
names as its third. On receipt of a C<CAP> message, the verb is extracted and
set as the C<verb> hint, and the list capabilities set as the keys of a hash
given as the C<caps> hint. These are then passed to an event called

 $irc->on_message_cap_VERB( $message, \%hints )

or

 $irc->on_message_cap( 'VERB', $message, \%hints )

=cut

sub on_message_CAP
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $verb = $message->arg(1);

   my %hints = (
      %$hints,
      verb => $verb,
      caps => { map { $_ => 1 } split m/ /, $message->arg(2) },
   );

   $self->invoke( "on_message_cap_$verb", $message, \%hints ) and $hints{handled} = 1;
   $self->invoke( "on_message_cap", $verb, $message, \%hints ) and $hints{handled} = 1;

   return $hints{handled};
}

=head2 MODE (on channels) and 324 (RPL_CHANNELMODEIS)

These messages involve channel modes. The raw list of channel modes is parsed
into an array containing one entry per affected piece of data. Each entry will
contain at least a C<type> key, indicating what sort of mode or mode change
it is:

=over 8

=item list

The mode relates to a list; bans, invites, etc..

=item value

The mode sets a value about the channel

=item bool

The mode is a simple boolean flag about the channel

=item occupant

The mode relates to a user in the channel

=back

Every mode type then provides a C<mode> key, containing the mode character
itself, and a C<sense> key which is an empty string, C<+>, or C<->.

For C<list> and C<value> types, the C<value> key gives the actual list entry
or value being set.

For C<occupant> types, a C<flag> key gives the mode converted into an occupant
flag (by the C<prefix_mode2flag> method), C<nick> and C<nick_folded> store the
user name affected.

C<boolean> types do not create any extra keys.

=cut

sub prepare_hints_channelmode
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my ( $listmodes, $argmodes, $argsetmodes, $boolmodes ) = @{ $self->isupport( 'chanmodes_list' ) };

   my $modechars = $hints->{modechars};
   my @modeargs = @{ $hints->{modeargs} };

   my @modes; # [] -> { type => $, sense => $, mode => $, arg => $ }

   my $sense = 0;
   foreach my $modechar ( split( m//, $modechars ) ) {
      $sense =  1, next if $modechar eq "+";
      $sense = -1, next if $modechar eq "-";

      my $hasarg;

      my $mode = {
         mode  => $modechar,
         sense => $sense,
      };

      if( index( $listmodes, $modechar ) > -1 ) {
         $mode->{type} = 'list';
         $mode->{value} = shift @modeargs if ( $sense != 0 );
      }
      elsif( index( $argmodes, $modechar ) > -1 ) {
         $mode->{type} = 'value';
         $mode->{value} = shift @modeargs if ( $sense != 0 );
      }
      elsif( index( $argsetmodes, $modechar ) > -1 ) {
         $mode->{type} = 'value';
         $mode->{value} = shift @modeargs if ( $sense > 0 );
      }
      elsif( index( $boolmodes, $modechar ) > -1 ) {
         $mode->{type} = 'bool';
      }
      elsif( my $flag = $self->prefix_mode2flag( $modechar ) ) {
         $mode->{type} = 'occupant';
         $mode->{flag} = $flag;
         $mode->{nick} = shift @modeargs if ( $sense != 0 );
         $mode->{nick_folded} = $self->casefold_name( $mode->{nick} );
      }
      else {
         # TODO: Err... not recognised ... what do I do?
      }

      # TODO: Consider a per-mode event here...

      push @modes, $mode;
   }

   $hints->{modes} = \@modes;
}

sub prepare_hints_MODE
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   if( $hints->{target_type} eq "channel" ) {
      $self->prepare_hints_channelmode( $message, $hints );
   }
}

sub prepare_hints_RPL_CHANNELMODEIS
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   $self->prepare_hints_channelmode( $message, $hints );
}

=head1 COMMAND-SENDING METHODS

The following methods actually send IRC commands. Each is named after the
underlying IRC command it sends, using capital letters for methods that simply
send that command.

=cut

=head2 do_PRIVMSG

=head2 do_NOTICE

Sends a C<PRIVMSG> or C<NOTICE> command.

For convenience, a single C<target> argument may be provided which will be
renamed to C<targets>. If C<targets> is an ARRAY reference, it will be turned
into a comma-separated string.

=cut

sub _do_pmlike
{
   my $self = shift;
   my $command = shift;

   my %args = @_;

   my $targets =
      ( ref $args{targets} eq "ARRAY" ) ? join( ",", @{ $args{targets} } ) :
      ( defined $args{target} )         ? delete $args{target} :
                                          $args{targets};

   $self->send_message( $command => { @_, targets => $targets } );
}

sub do_PRIVMSG { shift->_do_pmlike( PRIVMSG => @_ ) }
sub do_NOTICE  { shift->_do_pmlike( NOTICE  => @_ ) }

=head1 REQUIRED METHODS

As this class is an abstract base class, a concrete implementation must
provide the following methods to complete it and make it useable.

=cut

=head2 new_future

   $f = $client->new_future

Returns a new L<Future> instance or subclass thereof.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
