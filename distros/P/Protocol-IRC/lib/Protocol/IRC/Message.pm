#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2016 -- leonerd@leonerd.org.uk

package Protocol::IRC::Message;

use strict;
use warnings;

our $VERSION = '0.12';

use Carp;
our @CARP_NOT = qw( Net::Async::IRC );

=head1 NAME

C<Protocol::IRC::Message> - encapsulates a single IRC message

=head1 SYNOPSIS

 use Protocol::IRC::Message;

 my $hello = Protocol::IRC::Message->new(
    "PRIVMSG",
    undef,
    "World",
    "Hello, world!"
 );

 printf "The command is %s and the final argument is %s\n",
    $hello->command, $hello->arg( -1 );

=head1 DESCRIPTION

An object in this class represents a single IRC message, either received from
or to be sent to the server. These objects are immutable once constructed, but
provide a variety of methods to access the contained information.

This class also understands IRCv3 message tags.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new_from_line

   $message = Protocol::IRC::Message->new_from_line( $line )

Returns a new C<Protocol::IRC::Message> object, constructed by parsing the
given IRC line. Most typically used to create a new object to represent a
message received from the server.

=cut

sub new_from_line
{
   my $class = shift;
   my ( $line ) = @_;

   my %tags;
   if( $line =~ s/^\@([^ ]+) +// ) {
      foreach ( split m/;/, $1 ) {
         if( m/^([^=]+)=(.*)$/ ) {
            $tags{$1} = $2;
         }
         else {
            $tags{$_} = undef;
         }
      }
   }

   my $prefix;
   if( $line =~ s/^:([^ ]+) +// ) {
      $prefix = $1;
   }

   my ( $mid, $final ) = split( m/ +:/, $line, 2 );
   my @args = split( m/ +/, $mid );

   push @args, $final if defined $final;

   my $command = shift @args;

   return $class->new_with_tags( $command, \%tags, $prefix, @args );
}

=head2 new

   $message = Protocol::IRC::Message->new( $command, $prefix, @args )

Returns a new C<Protocol::IRC::Message> object, intialised from the given
components. Most typically used to create a new object to send to the server
using C<stream_to_line>. The message will contain no IRCv3 tags.

=cut

sub new
{
   my $class = shift;
   return $class->new_with_tags( $_[0], {}, $_[1], @_[2..$#_] );
}

=head2 new_from_named_args

   $message = Protocol::IRC::Message->new_from_named_args( $command, %args )

Returns a new C<Protocol::IRC::Message> object, initialised from the given
named argmuents. The argument names must match those required by the given
command.

=cut

sub new_from_named_args
{
   my $class = shift;
   my ( $command, %args ) = @_;

   my $argnames = $class->arg_names( $command );

   my @args;

   foreach my $name ( keys %$argnames ) {
      my $idx = $argnames->{$name};

      # Clients don't get to set prefix nick
      # TODO: servers do
      next if $idx eq "pn";

      defined( my $value = $args{$name} ) or
         croak "$command requires a named argmuent of '$name'";

      if( $idx =~ m/^\d+$/ ) {
         $args[$idx] = $args{$name};
      }
      else {
         die "TODO: not sure what to do with argname idx $idx\n";
      }
   }

   return $class->new( $command, undef, @args );
}

=head2 new_with_tags

   $mesage = Protocol::IRC::Message->new_with_tags( $command, \%tags, $prefix, @args )

Returns a new C<Protocol::IRC::Message> object, as with C<new> but also
containing the given IRCv3 tags.

=cut

sub new_with_tags
{
   my $class = shift;
   my ( $command, $tags, $prefix, @args ) = @_;

   # IRC is case-insensitive for commands, but we'd like them in uppercase
   # to keep things simpler
   $command = uc $command;

   # Less strict checking than RFC 2812 because a lot of servers lately seem
   # to be more flexible than that.

   $command =~ m/^[A-Z]+$/ or $command =~ m/^\d\d\d$/ or
      croak "Command must be just letters or three digits";

   foreach my $key ( keys %$tags ) {
      $key =~ m{^[a-zA-Z0-9./-]+$} or
         croak "Tag key '$key' is invalid";

      my $value = $tags->{$key};
      defined $value and $value =~ m{[ ;]} and
         croak "Tag value '$value' for key '$key' is invalid";
   }

   if( defined $prefix ) {
      $prefix =~ m/[ \t\x0d\x0a]/ and 
         croak "Prefix must not contain whitespace";
   }

   foreach ( @args[0 .. $#args-1] ) { # Not the final
      defined or croak "Argument must be defined";
      m/[ \t\x0d\x0a]/ and
         croak "Argument must not contain whitespace";
   }

   if( @args ) {
      defined $args[-1] or croak "Final argument must be defined";
      $args[-1] =~ m/[\x0d\x0a]/ and croak "Final argument must not contain a linefeed";
   }

   my $self = {
      command => $command,
      prefix  => $prefix,
      args    => \@args,
      tags    => { %$tags },
   };

   return bless $self, $class;
}

=head1 METHODS

=cut

=head2 STRING

   $str = $message->STRING

   $str = "$message"

Returns a string representing the message, suitable for use in a debugging
message or similar. I<Note>: This is not the same as the IRC wire form, to
send to the IRC server; for that see C<stream_to_line>.

=cut

use overload '""' => "STRING";
sub STRING
{
   my $self = shift;
   my $class = ref $self;
   return $class . "[" . 
                    ( defined $self->{prefix} ? "prefix=$self->{prefix}," : "" ) .
                    "cmd=$self->{command}," . 
                    "args=(" . join( ",", @{ $self->{args} } ) . ")]";
}

=head2 command

   $command = $message->command

Returns the command name or numeric stored in the message object.

=cut

sub command
{
   my $self = shift;
   return $self->{command};
}

=head2 command_name

   $name = $message->command_name

For named commands, returns the command name directly. For server numeric
replies, returns the name of the numeric.

=cut

my %NUMERIC_NAMES;

sub command_name
{
   my $self = shift;
   return $NUMERIC_NAMES{ $self->command } || $self->command;
}

=head2 tags

   $tags = $message->tags

Returns a HASH reference containing IRCv3 message tags. This is a reference to
the hash stored directly by the object itself, so the caller should be careful
not to modify it.

=cut

sub tags
{
   my $self = shift;
   return $self->{tags}
}

=head2 prefix

   $prefix = $message->prefix

Returns the line prefix stored in the object, or the empty string if one was
not supplied.

=cut

sub prefix
{
   my $self = shift;
   return defined $self->{prefix} ? $self->{prefix} : "";
}

=head2 prefix_split

   ( $nick, $ident, $host ) = $message->prefix_split

Splits the prefix into its nick, ident and host components. If the prefix
contains only a hostname (such as the server name), the first two components
will be returned as C<undef>.

=cut

sub prefix_split
{
   my $self = shift;

   my $prefix = $self->prefix;

   return ( $1, $2, $3 ) if $prefix =~ m/^(.*?)!(.*?)@(.*)$/;

   # $prefix doesn't split into nick!ident@host so presume host only
   return ( undef, undef, $prefix );
}

=head2 arg

   $arg = $message->arg( $index )

Returns the argument at the given index. Uses normal perl array indexing, so
negative indices work as expected.

=cut

sub arg
{
   my $self = shift;
   my ( $index ) = @_;
   return $self->{args}[$index];
}

=head2 args

   @args = $message->args

Returns a list containing all the message arguments.

=cut

sub args
{
   my $self = shift;
   return @{$self->{args}};
}

=head2 stream_to_line

   $line = $message->stream_to_line

Returns a string suitable for sending the message to the IRC server.

=cut

sub stream_to_line
{
   my $self = shift;

   my $line = "";

   if( keys %{ $self->{tags} } ) {
      my $tags = $self->{tags};
      $line .= "\@" . join( ";", map { defined $tags->{$_} ? "$_=$tags->{$_}" : $_ } keys %$tags ) . " ";
   }

   if( defined $self->{prefix} ) {
      $line .= ":$self->{prefix} ";
   }

   $line .= $self->{command};

   foreach ( @{$self->{args}} ) {
      if( m/ / or m/^:/  ) {
         $line .= " :$_";
      }
      else {
         $line .= " $_";
      }
   }

   return $line;
}

# Argument naming information

# This hash holds HASH refs giving the names of the positional arguments of
# any message. The hash keys store the argument names, and the values store
# an argument index, the string "pn" meaning prefix nick, or "$n~$m" meaning
# an index range. Endpoint can be absent.

my %ARG_NAMES = (
   INVITE  => { inviter_nick => "pn",
                invited_nick => 0,
                target_name  => 1 },
   KICK    => { kicker_nick => "pn",
                target_name => 0,
                kicked_nick => 1,
                text        => 2 },
   MODE    => { target_name => 0,
                modechars   => 1,
                modeargs    => "2.." },
   NICK    => { old_nick => "pn",
                new_nick => 0 },
   NOTICE  => { targets => 0,
                text    => 1 },
   PING    => { text => 0 },
   PONG    => { text => 0 },
   QUIT    => { text => 0 },
   PART    => { target_name => 0,
                text        => 1 },
   PRIVMSG => { targets => 0,
                text    => 1 },
   TOPIC   => { target_name => 0,
                text        => 1 },
);

# Misc. named commands
$ARG_NAMES{$_} = { target_name => 0 } for qw(
   LIST NAMES WHO WHOIS WHOWAS
);

# TODO: 472 ERR_UNKNOWNMODE: <char> :is unknown mode char to me for <channel>
# How to parse this one??

=head2 arg_names

   $names = $message->arg_names

Returns a HASH reference giving details on how to parse named arguments for
the command given in this message.

This will be a hash whose keys give the names of the arguments, and the values
of these keys indicate how that argument is derived from the simple positional
arguments.

Normally this method is only called internally by the C<named_args> method,
but is documented here for the benefit of completeness, and in case extension
modules wish to define parsing of new message types.

Each value should be one of the following:

=over 4

=item * String literal C<pn>

The value is a string, the nickname given in the message prefix

=item * NUMBER..NUMBER

The value is an ARRAY ref, containing a list of all the numbered arguments
between the (inclusive) given limits. Either or both limits may be negative;
they will count backwards from the end.

=item * NUMBER

The value is the argument at that numeric index. May be negative to count
backwards from the end.

=item * NUMBER@

The value is the argument at that numeric index as for C<NUMBER>, except that
the result will be split on spaces and stored in an ARRAY ref.

=back

=head2 arg_names (class method)

   $names = Protocol::IRC::Message->arg_names( $command )

This method may also be invoked as a class method by passing in the command
name or numeric. This allows inspection of what arguments would be required
or returned before a message object itself is constructed.

=cut

sub arg_names
{
   my $command;

   if( ref $_[0] ) {
      my $self = shift;
      $command = $self->{command};
   }
   else {
      my $class = shift; # ignore
      ( $command ) = @_;
      defined $command or croak 'Usage: '.__PACKAGE__.'->arg_names($command)';
   }

   return $ARG_NAMES{$command};
}

=head2 named_args

   $args = $message->named_args

Parses arguments in the message according to the specification given by the
C<arg_names> method. Returns a hash of parsed arguments.

TODO: More complete documentation on the exact arg names/values per message
type.

=cut

sub named_args
{
   my $self = shift;

   my $argnames = $self->arg_names or return;

   my %named_args;
   foreach my $name ( keys %$argnames ) {
      my $argindex = $argnames->{$name};

      my $value;
      if( $argindex eq "pn" ) {
         ( $value, undef, undef ) = $self->prefix_split;
      }
      elsif( $argindex =~ m/^(-?\d+)?\.\.(-?\d+)?$/ ) {
         my ( $start, $end ) = ( $1, $2 );
         my @args = $self->args;

         defined $start or $start = 0;
         defined $end   or $end = $#args;

         $end += @args if $end < 0;

         $value = [ splice( @args, $start, $end-$start+1 ) ];
      }
      elsif( $argindex =~ m/^-?\d+$/ ) {
         $value = $self->arg( $argindex );
      }
      elsif( $argindex =~ m/^(-?\d+)\@$/ ) {
         $value = [ split ' ', $self->arg( $1 ) ];
      }
      else {
         die "Unrecognised argument specification $argindex";
      }

      $named_args{$name} = $value;
   }

   return \%named_args;
}

=head2 gate_disposition

   $disp = $message->gate_disposition

Returns the "gating disposition" of the message. This defines how a reply
message from the server combines with other messages in response of a command
sent by the client. The disposition is either C<undef>, or a string consisting
of a type symbol and a gate name. If defined, the symbol defines what effect
it has on the gate name.

=over 4

=item -GATE

Adds more information to the response for that gate, but doesn't yet complete
it.

=item +GATE

Completes the gate with a successful result.

=item *GATE

Completes the gate with a successful result, but only if the nick in the
message prefix relates to the connection it is received on.

=item !GATE

Completes the gate with a failure result.

=back

=cut

my %GATE_DISPOSITIONS;

sub gate_disposition
{
   my $self = shift;
   return $GATE_DISPOSITIONS{ $self->command };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

local $_;
while( <DATA> ) {
   chomp;
   m/^\s*#/ and next; # ignore comments

   my ( $cmdname, $args, $gating ) = split m/\s*\|\s*/, $_ or next;
   my ( $cmd, $name ) = split m/=/, $cmdname;

   my $index = 0;
   my %args = map {
      if( m/^(.*)=(.*)$/ ) {
         $index = $1;
         ( $2 => $1 )
      }
      else {
         ( $_ => ++$index );
      }
   } split m/,/, $args;

   $NUMERIC_NAMES{$cmd} = $name;
   $ARG_NAMES{$cmd} = \%args;
   $GATE_DISPOSITIONS{$cmd} = $gating if defined $gating;
}
close DATA;

0x55AA;

# And now the actual numeric definitions, given in columns
# number=NAME | argname,argname,argname

# arg may be position=argname

# See also
#   http://www.alien.net.au/irc/irc2numerics.html

__DATA__
JOIN | 0=target_name | *join

001=RPL_WELCOME         | text
002=RPL_YOURHOST        | text
003=RPL_CREATED         | text
004=RPL_MYINFO          | serverhost,serverversion,usermodes,channelmodes
005=RPL_ISUPPORT        | 1..-2=isupport,-1=text

250=RPL_STATSCONN       | text
251=RPL_LUSERCLIENT     | text
252=RPL_LUSEROP         | count,text
253=RPL_LUSERUNKNOWN    | count,text
254=RPL_LUSERCHANNELS   | count,text
255=RPL_LUSERME         | text
265=RPL_LOCALUSERS      | count,max_count,text
266=RPL_GLOBALUSERS     | count,max_count,text

301=RPL_AWAY            | target_name,text
305=RPL_UNAWAY          | text
306=RPL_NOWAWAY         | text

307=RPL_USERIP          | target_name
311=RPL_WHOISUSER       | target_name,ident,host,flags,realname | -whois
312=RPL_WHOISSERVER     | target_name,server,serverinfo         | -whois
313=RPL_WHOISOPERATOR   | target_name,text                      | -whois
315=RPL_ENDOFWHO        | target_name                           | +who
314=RPL_WHOWASUSER      | target_name,ident,host,flags,realname
317=RPL_WHOISIDLE       | target_name,idle_time                 | -whois
318=RPL_ENDOFWHOIS      | target_name                           | +whois
319=RPL_WHOISCHANNELS   | target_name,2@=channels               | -whois
320=RPL_WHOISSPECIAL    | target_name                           | -whois
324=RPL_CHANNELMODEIS   | target_name,modechars,3..=modeargs
328=RPL_CHANNEL_URL     | target_name,text
329=RPL_CHANNELCREATED  | target_name,timestamp
330=RPL_WHOISACCOUNT    | target_name,whois_nick,login_name     | -whois

331=RPL_NOTOPIC         | target_name
332=RPL_TOPIC           | target_name,text
333=RPL_TOPICWHOTIME    | target_name,topic_nick,timestamp

341=RPL_INVITING        | target_name,channel_name
346=RPL_INVITELIST      | target_name,invite_mask
347=RPL_ENDOFINVITELIST | target_name
348=RPL_EXCEPTLIST      | target_name,except_mask
349=RPL_ENDOFEXCEPTLIST | target_name

352=RPL_WHOREPLY        | target_name,user_ident,user_host,user_server,user_nick,user_flags,text | -who
353=RPL_NAMEREPLY       | 2=target_name,3@=names | -names

366=RPL_ENDOFNAMES      | target_name | +names
367=RPL_BANLIST         | target_name,mask,by_nick,timestamp | -bans
368=RPL_ENDOFBANLIST    | target_name | +bans
369=RPL_ENDOFWHOWAS     | target_name

372=RPL_MOTD            | text | -motd
375=RPL_MOTDSTART       | text | -motd
376=RPL_ENDOFMOTD       |      | +motd

378=RPL_WHOISHOST       | target_name,text | -whois

401=ERR_NOSUCHNICK              | target_name,text
402=ERR_NOSUCHSERVER            | server_name,text
403=ERR_NOSUCHCHANNEL           | target_name,text | !join
404=ERR_CANNOTSENDTOCHAN        | target_name,text
405=ERR_TOOMANYCHANNELS         | target_name,text
406=ERR_WASNOSUCHNICK           | target_name,text
408=ERR_NOSUCHSERVICE           | target_name,text

432=ERR_ERRONEUSNICKNAME        | nick,text
433=ERR_NICKNAMEINUSE           | nick,text
436=ERR_NICKCOLLISION           | nick,text

441=ERR_USERNOTINCHANNEL        | user_nick,target_name,text
442=ERR_NOTONCHANNEL            | target_name,text
443=ERR_USERONCHANNEL           | user_nick,target_name,text
444=ERR_NOLOGIN                 | target_name,text

467=ERR_KEYSET                  | target_name,text

471=ERR_CHANNELISFULL           | target_name,text | !join
473=ERR_INVITEONLYCHAN          | target_name,text | !join
474=ERR_BANNEDFROMCHAN          | target_name,text | !join
475=ERR_BADCHANNELKEY           | target_name,text | !join
476=ERR_BADCHANMASK             | target_name,text | !join
477=ERR_NEEDREGGEDNICK          | target_name,text 
478=ERR_BANLISTFULL             | target_name,text

482=ERR_CHANOPRIVSNEEDED        | target_name,text

# WATCH related - see
#   http://archives.darenet.org/irc/misc/irc-docs-master/misc/irc-documentation-jilles/reference/draft-meglio-irc-watch-00.txt
598=RPL_GONEAWAY       | target_name,ident,host,timestamp,text
599=RPL_NOTAWAY        | target_name,ident,host,timestamp,text
600=RPL_LOGON          | target_name,ident,host,timestamp,text
601=RPL_LOGOFF         | target_name,ident,host,timestamp,text
602=RPL_WATCHOFF       | target_name,ident,host,timestamp,text
603=RPL_WATCHSTAT      | text
604=RPL_NOWON          | target_name,ident,host,timestamp,text
605=RPL_NOWOFF         | target_name,ident,host,timestamp,text
606=RPL_WATCHLIST      | 1@=nicks
607=RPL_ENDOFWATCHLIST | text
609=RPL_NOWISAWAY      | target_name,ident,host,timestamp,text

671=RPL_WHOISSECURE | target_name,text | -whois
