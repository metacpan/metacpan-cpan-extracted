package POE::Component::Server::IRC::Help;
$POE::Component::Server::IRC::Help::VERSION = '1.66';
use strict;
use warnings;

sub new {
    my $package = shift;
    return bless [], $package;
}

sub topic {
    my $self = shift;
    my $topic = shift || return;
    my $lines = [];

    $topic = lc $topic;
    my $method = '_' . $topic;
    return unless eval { $self->can($method) };
    push @$lines, $_ for split m!\n!, $self->$method;
    return @$lines if wantarray;
    return $lines;
}

sub _accept {
  return << 'EOT'
ACCEPT [parameter]

ACCEPT allows you to control who can send you a NOTICE or PRIVMSG
while you have user mode +g enabled.

For +g: /QUOTE ACCEPT <n!u@h>   -- Add a permitted mask
        /QUOTE ACCEPT -<n!u@h>  -- Remove a permitted mask
        /QUOTE ACCEPT *         -- List the present permitted masks
        /QUOTE ACCEPT           -- List the present permitted masks
EOT
}

sub _admin {
  return << 'EOT'
ADMIN [servername/nickname]

With no arguments, ADMIN shows the information that was set by the
administrator of the server. This information can take any form that
will fit in three lines of text but is usually a list of contacts
for the persons that run the server.

With a second argument, the administrative information for the
specified server is displayed.

See also: stats
EOT
}

sub _away {
  return << 'EOT'
AWAY :[MSG]

Without an argument, it will set you back.  With an argument,
it will set you as AWAY with the specified message.
EOT
}

sub _close {
  return << 'EOT'
CLOSE

Close any connections from clients or servers who have
not fully registered yet.

- Requires Oper Priv: close
EOT
}

sub _cmode {
  return << 'EOT'
MODE <channel> <+|-><modes> [parameters]

=-=-=-=-=-=-=-=-=-=-=
    CHANNELMODES
=-=-=-=-=-=-=-=-=-=-=

    MODE    - DESCRIPTION
------------------------------------------------------------------------

NO PARAMETERS:
--------------

     +c     - 'No control codes'.  Prevent users from sending messages containing
              control codes to the channel

     +n     - 'No external messages'.  This will prevent any user who
              isn't in the channel from sending messages to the channel.

     +t     - 'Ops Topic'.  This will prevent any user who isn't opped,
              or half-opped (+o/+h) from setting a channel topic.

     +s     - 'Secret'.  This will prevent the channel from being shown
              in a /whois, and in the channel list.

     +p     - 'Paranoia'. Controls whether halfops may invite users
              into a channel or whether they may kick other members of a
              channel.

     +m     - 'Moderated'.  This will prevent any user who isn't opped,
              half-opped or voiced (+o/+h/+v) from talking in the channel.

     +i     - 'Invite only'.  This will prevent anyone from joining your
              channel who hasn't received an /invite or whose host isn't in
              the +I list.

     +r     - 'Registered'. Channel has been registered with ChanServ.
              Can be set only by servers and services.

     +u     - 'Hide bmasks'. Hides +b/+e/+I mode changes and lists to everyone
              except channel ops, and half-ops (+o/+h).

     +C     - 'No CTCPs'. Prevent users from sending CTCPs to the channel.

     +L     - 'Large ban list'. Channel can make use of the extended ban list
              limit. Can be set only by irc-operators, servers and services.

     +M     - 'Modreg'. Unregistered/unidentified clients cannot send text to
              the channel

     +N     - 'No nick changes'. This will prevent any user who isn't opped or
              half-opped (+o/+h) from changing their nick while in the channel.

     +O     - 'IRCOps only'. This will prevent anyone who hasn't obtained
              irc-operator status from joining your channel. Can be set only
              by irc-operators, servers and services.

     +R     - 'Registered only'. Only registered clients may join a channel
              with that mode set

     +S     - 'SSL only'. This will prevent anyone who isn't securely connected
              via SSL/TLS from joining your channel.

     +T     - 'No Notices'. This will prevent any user who isn't opped,
              half-opped or voiced (+o/+h/+v) from sending channel notices.


WITH PARAMETERS:
----------------

     +k     - 'Key'.  This will require users joining to know the key,
              they must then use /join #channel KEY

              PARAMS: /mode #channel +k key

     +l     - 'Limit'. This will prevent more than LIMIT number of people
              in the channel at any time.

              PARAMS: /mode #channel +l limit

     +v     - 'Voice'.  This will allow a user to talk in a moderated (+m)
              channel.  Shown by the +nick flag.

              PARAMS: /mode #channel +vvvv nick1 nick2 nick3 nick4

     +h     - 'Half-op'.  This will allow a user to set all of the above
              modes, (and some more below..), whilst stopping the user
              from doing harm to the channel.  Users who are +h CANNOT
              kick opped (+o) users, or set modes +h/-h/+o/-o.

              They can perform all other modes, and can kick regular users.

              PARAMS: /mode #channel +hhhh nick1 nick2 nick3 nick4

     +o     - 'Op'.  This gives the user full control over the channel.
              An opped user may op other users, set any mode, and
              remove ops from whoever they want.

              PARAMS: /mode #channel +oooo nick1 nick2 nick3 nick4

     +b     - 'Ban'.  This will prevent a user from entering the channel,
              based on a nick!ident@host match.

              PARAMS: /mode #channel +bbbb n!u@h1b n!u@h2b n!u@h3b n!u@h4

     +e     - 'Exempt'.  This will allow a user to join a channel even if
              they are banned (+b), based on a nick!ident@host match.

              PARAMS: /mode #channel +eeee n!u@h1b n!u@h2b n!u@h3b n!u@h4

     +I     - 'Invite Exempt'.  This will allow a user to join an
              invite-only (+i) channel, based on a nick!user@host match.

              PARAMS: /mode #channel +IIII n!u@h1b n!u@h2b n!u@h3b n!u@h4
EOT
}

sub _connect {
  return << 'EOT'
CONNECT <server_A> [port] [server_B]

When [server_B] is used, CONNECT asks [server_B] to
connect to <server_A>.

The [port] must be specified with [server_B], this is
usually 6667.  To use the default port in the connect
block, you can use 0 as the port.

When [server_B] is not used, CONNECT tries to connect
your server to <server_A>.

When [port] is used, the connection will be attempted
to [port].
When [port] is not used, 6667 is used as a default,
unless the port is specified in the conf file.

- Requires Oper Priv: connect
- Requires Oper Priv: connect:remote for servers not connected to you
EOT
}

sub _die {
  return << 'EOT'
DIE <server.name>

Terminates the IRC server.

- Requires Oper Priv: die
EOT
}

sub _dline {
  return << 'EOT'
DLINE <time> <nick|ip> :[reason]

<time> if present, gives number of minutes for DLINE

Adds a DLINE which will deny any connections from the
IP address of the banned client. The banned client will
receive a message saying he/she is banned with reason [reason]

In order to use <nick> rather than <ip>, <nick> must
be on your server.

- Requires Oper Priv: dline
EOT
}

sub _etrace {
  return << 'EOT'
ETRACE [nickname mask]

The ETRACE command will display a list of locally connected users
in the following format:

User/Oper class nickname username host ip gecos

You can optionally give a parameter with nickname mask to limit
the output. Wildcards are allowed.
EOT
}

sub _hash {
  return << 'EOT'
HASH

Shows the hash statistics.
EOT
}

sub _help {
  return << 'EOT'
HELP [topic]

HELP displays the contents of the help
file for topic requested.  If no topic is
requested, it will perform the equivalent
to HELP index.
EOT
}

sub _index {
  return << 'EOT'
Available HELP topics:

ACCEPT          ADMIN           AWAY            CLOSE
CMODE           CONNECT         DIE             DLINE
ETRACE          HASH            HELP            INFO
INVITE          ISON            JOIN            KICK
KILL            KLINE           KNOCK           LINKS
LIST            LOCOPS          LUSERS          MAP
MODULE          MOTD            NAMES           NICK
NOTICE          OPER            PART
PASS            PING            PONG            POST
PRIVMSG         QUIT            REHASH          RESTART
RESV            SET             SQUIT           STATS
TIME            TOPIC           TRACE           UMODE
UNDLINE         UNKLINE         UNRESV          UNXLINE
USER            USERHOST        VERSION         WALLOPS
WHO             WHOIS           WHOWAS          XLINE
EOT
}

sub _info {
  return << 'EOT'
INFO [servername/nickname]

INFO displays the copyright, list of authors and contributors
to ircd, and the server configuration (as defined in setup.h,
defaults.h, and ircd.conf).
EOT
}

sub _invite {
  return << 'EOT'
INVITE [ <nickname> <channel> ]

INVITE sends a notice to the user that you have
asked him/her to come to the specified channel.
If used without parameters, it displays a list
of channels you're invited to.
EOT
}

sub _ison {
  return << 'EOT'
ISON <nick_A> [nick_B] :[nick_C] [nick_D]

ISON will return a list of users who are present
on the network from the list that was passed in.

This command is rarely used directly.
EOT
}

sub _join {
  return << 'EOT'
JOIN <#channel1[,#channel2,#channel3...]> [<key>{,<key>}]

The JOIN command allows you to enter a public chat area known as
a channel. You can join more than one channel at a time,
separating their names with commas (',').

If the channel has a key set, the second argument must be
given to enter. This allows channels to be password protected.

See also: part, list
EOT
}

sub _kick {
  return << 'EOT'
KICK <channel> <nick> :[reason]

The KICK command will remove the specified user
from the specified channel, using the optional
reason. If reason is not specified, nickname
of the user issuing the KICK will be used as reason.

You must be a channel operator or half-op to use this command.
EOT
}

sub _kill {
  return << 'EOT'
KILL <nick> :[reason]

Disconnects user <nick> from the IRC server he/she
is connected to with reason [reason].

- Requires Oper Priv: kill
- Requires Oper Priv: kill:remote for users not on your IRC server
EOT
}

sub _kline {
  return << 'EOT'
KLINE [time] <nick|user@host> :[reason]

[time] if present, gives number of minutes for KLINE

Adds a KLINE which will ban the specified user from
using that server. The banned client will receive a
message saying he/she is banned with reason [reason]

KLINE user@ip.ip.ip.ip :[reason]
will kline the user at the unresolved ip.
ip.ip.ip.ip can be in CIDR form i.e. 192.168.0.0/24
or 192.168.0.* (which is converted to CIDR form internally)

For a temporary KLINE, length of kline is given in
minutes as the first parameter [time] i.e.
KLINE 10 <nick|user@host> :cool off for 10 minutes

KLINE <user@host> ON irc.server :[reason]
will kline the user on irc.server if irc.server accepts
remote klines.

- Requires Oper Priv: kline
EOT
}

sub _knock {
  return << 'EOT'
KNOCK <channel>

KNOCK requests access to a channel that
for some reason is not open.

KNOCK cannot be used if you are banned, the
channel is +p, or it is open.
EOT
}

sub _links {
  return << 'EOT'
LINKS [mask] [servername/nickname]

LINKS shows a list of all servers linked to the host server.

With a mask parameter, LINKS will just show servers matching
that parameter. With the remote server parameter, LINKS will
request the LINKS data from the remote server, matching the
mask given.

The information provided by the LINKS command can be helpful
for determining the overall shape of the network in addition to
its size.

NOTE: the links command employs an intensive process to generate
its output, so sparing use is recommended.

See also: connect map squit
EOT
}

sub _list {
  return << 'EOT'
LIST [options]

Without any arguments, LIST will give an entire list of all
channels which are not set as secret (+s). The list will be in
the form:

  <#channel> <amount of users> :[modes] [topic]

If you want to use a specific filter, you can pass one or more
options separated by commas (','). Recognized options are:
  *mask*   List channels matching *mask*
  !*mask*  List channels NOT matching *mask*
  >num     Show only channels which contain more than <num> users
  <num     Show only channels which contain less than <num> users
  C>num    Display channels created within last <num> minutes
  C<num    Display channels created earlier than <num> minutes ago
  T>num    Limit matches to those channels whose topics are older
           than <num> minutes
  T<num    Limit matches to those channels whose topics have been
           changed within last <num> minutes
  T:mask   Limit matches to those channels whose topics match the
           given mask

To stop a running LIST request, use /LIST command again.

See also: join
EOT
}

sub _locops {
  return << 'EOT'
LOCOPS :<message>

Sends a LOCOPS message of <message> to all
opers on local server who are umode +l

- Requires Oper Priv: locops
EOT
}

sub _lusers {
  return << 'EOT'
LUSERS [mask] [servername/nickname]

LUSERS will display client count statistics
for the specified mask, or all users if a
mask was not specified.  If a remote server
is specified, it will request the information
from that server.
EOT
}

sub _map {
  return << 'EOT'
MAP

Shows the network map.
EOT
}

sub _module {
  return << 'EOT'
MODULE <option> [module name]

<option> can be one of the following:
  LIST    - List the modules that are currently loaded into the
            ircd, along with their address and version.
            When a match string is provided, LIST only prints
            modules with names matching the match string.

  LOAD    - Loads a module into the ircd.
            The optional path can be an absolute path
            from / or from the IRCD_PREFIX
            (ie modules/autoload/m_users.la)

  UNLOAD  - Unload a module from the ircd.
            Use just the module name, the path is not needed.
            When a module is unloaded, all commands associated
            with it are unloaded as well.

  RELOAD  - Reloads all modules.
            All modules are unloaded, then those in modules/autoload
            are loaded. If "*" has been specified as module name,
            all modules will be reloaded.

- Requires Oper Priv: module
EOT
}

sub _motd {
  return << 'EOT'
MOTD [servername/nickname]

MOTD will display the message of the day for the
server name specified, or the local server if there
was no parameter.
EOT
}

sub _names {
  return << 'EOT'
NAMES <channel>

Displays nicks on a specific channel, also respecting the +i flag of
each client. If the channel specified is a channel that the issuing
client is currently in, all nicks are listed in similar fashion to
when the user first joins a channel.

See also: join
EOT
}

sub _nick {
  return << 'EOT'
NICK <nickname>

When first connected to the IRC server, NICK is required to
set the client's nickname.

NICK will also change the client's nickname once a connection
has been established.
EOT
}

sub _notice {
  return << 'EOT'
NOTICE <nick|channel> :message

NOTICE will send a notice message to the
user or channel specified.

NOTICE supports the following prefixes for sending
messages to specific clients in a channel:

@ - channel operators only
% - channel operators and half-ops
+ - operators, half-ops, and voiced users

Two other targets are permitted:

$$servermask - Send a message to a server or set of
               servers
$#hostmask   - Send a message to users matching the
               hostmask specified.

These two are operator only.

The nick can be extended to fit into the following
syntax:

username[%hostname]@servername

This syntax (without the hostname) is used to securely
send a message to a service or a bot.
EOT
}

sub _oper {
  return << 'EOT'
OPER <name> <password>

The OPER command requires two arguments to be given. The first
argument is the name of the operator as specified in the
configuration file. The second argument is the password for
the operator matching the name and host.
EOT
}

sub _part {
  return << 'EOT'
PART <#channel1[,#channel2,#channel3...]> :[part message]

PART requires at least a channel argument to be given. It will
exit the client from the specified channel.
You can part more than one channel at a time,
separating their names with commas (',').

An optional part message may be given to be displayed to the
channel.

See also: join
EOT
}

sub _pass {
  return << 'EOT'
PASS <password>

PASS is used during registration to access
a password protected auth {} block.

PASS is also used during server registration.
EOT
}

sub _ping {
  return << 'EOT'
PING <source> :<target>

PING will request a PONG from the target.  If a
user or operator issues this command, the source
will always be turned into the nick that issued
the PING.
EOT
}

sub _pong {
  return << 'EOT'
PONG <pinged-client> :<source-client>

PONG is the response to a PING command.  The
source client is the user or server that issued
the command, and the pinged client is the
user or server that received the PING.
EOT
}

sub _post {
  return << 'EOT'
POST

The POST command is used to help protect against
insecure HTTP proxies.  Any proxy that sends a POST
command during registration will be exited.
EOT
}

sub _privmsg {
  return << 'EOT'
PRIVMSG <nick1|channel1[,nick2|channel2...]> :message

PRIVMSG will send a standard message to the
user or channel specified.

PRIVMSG supports the following prefixes for sending
messages to specific clients in a channel:

@ - channel operators only
% - channel operators and half-ops
+ - operators, half-ops, and voiced users

Two other targets are permitted:

$$servermask - Send a message to a server or set of
               servers
$#hostmask   - Send a message to users matching the
               hostmask specified.

These two are operator only.

The nick can be extended to fit into the following
syntax:

username[%hostname]@servername

This syntax (without the hostname) is used to securely
send a message to a service or a bot.
EOT
}

sub _quit {
  return << 'EOT'
QUIT :[quit message]

QUIT sends a message to the IRC server letting it know you would
like to disconnect.  The quit message will be displayed to the
users in the channels you were in when you are disconnected.
EOT
}

sub _rehash {
  return << 'EOT'
REHASH <option>

<option> can be one of the following:
  CONF - Re-read the server configuration file(s)
  DNS  - Re-read the /etc/resolv.conf file
  MOTD - Re-read MOTD file(s)

To REHASH on remote servers:
  REHASH <server> <option>

- Requires Oper Priv: rehash
- Requires Oper Priv: rehash:remote for REHASH on remote servers
EOT
}

sub _restart {
  return << 'EOT'
RESTART <server.name>

Restarts the IRC server.

- Requires Oper Priv: restart
EOT
}

sub _resv {
  return << 'EOT'
RESV <channel|nick> :<reason>

-- RESV a channel or nick
Will create a resv for the given channel/nick, stopping
local users from joining the channel, or using the
nick.  Will not affect remote clients.

If the oper is an admin, they may create a wildcard
resv, for example: clones*

- Requires Oper Priv: resv
EOT
}

sub _set {
  return << 'EOT'
SET <option> <value>

<option> can be one of the following:
  AUTOCONN    - Sets auto-connect on or off for a particular
                server
  AUTOCONNALL - Sets auto-connect on or off for all servers
  FLOODCOUNT  - The number of messages allowed before
                throttling a user due to flooding.
                Note that this variable is used for both
                channels and clients.
  FLOODTIME   - The time, in seconds, of FLOODCOUNT.
  JFLOODCOUNT - Sets the number of joins in JFLOODTIME to
                count as flooding. Use 0 to disable.
  JFLOODTIME  - The amount of time in seconds in JFLOODCOUNT to consider
                as join flooding. Use 0 to disable.
  MAX         - Sets the number of max connections
                to <value>. (This number cannot exceed
                HARD_FDLIMIT in defaults.h)
  SPAMNUM     - Sets how many join/parts to channels
                constitutes a possible spambot.
  SPAMTIME    - Below this time on a channel
                counts as a join/part as above.

- Requires Oper Priv: set
EOT
}

sub _squit {
  return << 'EOT'
SQUIT <server> :[reason]

Splits <server> away from your side of the net with [reason].

- Requires Oper Priv: squit
- Requires Oper Priv: squit:remote for servers not connected to you
EOT
}

sub _stats {
  return << 'EOT'
STATS <letter> [server|nick]

Queries server [server] (or your own server if no
server parameter is given) for info corresponding to
<letter>.

       (X = Admin only.)
LETTER (* = Oper only.)
------ (^ = Can be configured to be oper only.)
X A - Shows the DNS servers in use
* c - Shows configured connect {} blocks
* d - Shows temporary D lines
* D - Shows permanent D lines
* e - Shows exemptions to D lines
X E - Shows active timers/events
X f - Shows file descriptors
* H - Shows configured hub/leaf entries
^ i - Shows configured auth {} blocks
^ K - Shows permanent K lines (or matched permanent klines)
^ k - Shows temporary K lines (or matched temporary klines)
* L - Shows IP and generic info about [nick]
* l - Shows hostname and generic info about [nick]
  m - Shows commands and their usage
^ o - Shows configured operator {} blocks
^ P - Shows configured listen {} blocks
  p - Shows opers connected and their idle times
* q - Shows resv'd nicks and channels
* s - Shows configured service {} blocks
* T - Shows configured motd {} blocks
* t - Shows generic server stats
* U - Shows configured shared {} and cluster {} blocks
^ u - Shows server uptime
* v - Shows connected servers and their idle times
* x - Shows gecos bans
* y - Shows configured class {} blocks
* z - Shows memory stats
* ? - Shows connected servers and sendq info about them
EOT
}

sub _time {
  return << 'EOT'
TIME [servername/nickname]

The TIME command will return the server's local date and time.

If an argument is supplied, the time for the server specified
will be returned.
EOT
}

sub _topic {
  return << 'EOT'
TOPIC <#channel> :[new topic]

With only a channel argument, TOPIC shows the current topic of
the specified channel.

With a second argument, it changes the topic on that channel to
<new topic>.  If the channel is +t, only chanops may change the
topic.

See also: cmode
EOT
}

sub _trace {
  return << 'EOT'
TRACE [server | nick]

With no argument, TRACE gives a list of all clients connected
to the local server, both users and operators.

With one argument which is a server, TRACE displays the path
to the specified server, and all clients on that server.

With one argument which is a client, TRACE displays the
path to that client, and that client's information.
EOT
}

sub _umode {
  return << 'EOT'
MODE <nick> <+|-><modes>

User modes: (* designates that the umode is oper only)

     USER MODE    DESCRIPTION
-----------------------------------------------------------------
       * o     - Designates this client is an IRC Operator.
                 Use the OPER command to attain this.
         i     - Designates this client 'invisible'.
         w     - Can see server wallops.
         W     - User is connected using a webirc gateway.
       * l     - Can see oper locops (local wallops).
       * c     - Can see client connections and exits.
       * u     - Can see unauthorized client connections.
       * j     - Can see 'rejected' client notices.
       * k     - Can see server kill messages.
       * f     - Can see 'auth {} block is full' notices.
       * F     - Can see remote client connection/quit notices.
       * y     - Can see stats/links/admin requests to name a few.
       * d     - Can see server debug messages.
       * n     - Can see client nick changes.
         p     - Hides channel list in WHOIS.
         q     - Hides idle and signon time in WHOIS.
         r     - User has been registered and identified for its nick.
                 Can be set only by servers and services.
         R     - Only registered clients may message you.
         s     - Can see generic server messages and oper kills.
         S     - Client is connected via SSL/TLS.
       * e     - Can see new server introduction and split messages.
       * b     - Can see possible bot/join flood warnings.
       * a     - Is marked as a server admin in stats o/p.
         D     - "Deaf": don't receive channel messages.
         G     - "Soft Caller ID": block private messages from people not on
                 any common channels with you (unless they are accepted).
         g     - "Caller ID" mode: only allow accepted clients to message you.
       * H     - IRC operator status is hidden to other users.
EOT
}

sub _undline {
  return << 'EOT'
UNDLINE <IP address>

Will attempt to undline the given <IP address>
If the dline is conf based, the dline will not be removed.

UNDLINE <IP address> ON irc.server

Will undline the given <IP address> on irc.server if irc.server accepts
remote undlines. If the dline is conf based, the dline will
not be removed.

- Requires Oper Priv: undline
EOT
}

sub _unkline {
  return << 'EOT'
UNKLINE <user@host>

Will attempt to unkline the given <user@host>
If the kline is conf based, the kline will not be removed.

UNKLINE <user@host> ON irc.server

Will unkline the user on irc.server if irc.server accepts
remote unklines. If the kline is conf based, the kline will
not be removed.

- Requires Oper Priv: unkline
EOT
}

sub _unresv {
  return << 'EOT'
UNRESV <channel|nick>

-- Remove a RESV on a channel or nick
Will attempt to remove the resv for the given
channel/nick. If the resv is conf based, the resv
will not be removed.

UNRESV <channel|nick> ON irc.server
will unresv the <channel|nick> on irc.server if irc.server
accepts remote unresvs. If the resv is conf based, the resv
will not be removed.

- Requires Oper Priv: unresv
EOT
}

sub _unxline {
  return << 'EOT'
UNXLINE <gecos>

Removes an XLINE

UNXLINE <gecos> ON irc.server
will unxline the gecos on irc.server if irc.server accepts
remote unxlines. If the xline is conf based, the xline
will not be removed.

- Requires Oper Priv: unxline
EOT
}

sub _user {
  return << 'EOT'
USER <username> <unused> <unused> :<real name/gecos>

USER is used during registration to set your gecos
and to set your username if the server cannot get
a valid ident response.  The second and third fields
are not used, but there must be something in them.
The reason is backwards compatibility
EOT
}

sub _userhost {
  return << 'EOT'
USERHOST <nick>

USERHOST displays the username, hostname,
operator status, and presence of valid ident of
the specified nickname.

If you use USERHOST on yourself, the hostname
is replaced with the IP you are connecting from.
This is needed to provide DCC support for spoofed
hostnames.
EOT
}

sub _version {
  return << 'EOT'
VERSION [servername/nickname]

VERSION will display the server version of the specified
server, or the local server if there was no parameter.
EOT
}

sub _wallops {
  return << 'EOT'
WALLOPS :<message>

Sends a WALLOPS message of <message> to all opers
who are umode +z.

Server sent WALLOPS go to all opers who are umode +w.

- Requires Oper Priv: wallops
EOT
}

sub _who {
  return << 'EOT'
WHO <#channel|user>

The WHO command displays information about a user,
such as their GECOS information, their user@host,
whether they are an IRC operator or not, etc.
A sample WHO result from a command issued like
"WHO pokey" may look something like this:

#lamers pokey H pokey@ppp.newbies.net :0 Jim Jones

The first field indicates the last channel the user
has joined. The second is the user's nickname.
The third field describes the status information about
the user. The possible combinations for this field
are listed below:

H - The user is not away.
G - The user is set away.
r - The user is using a registered nickname.
* - The user is an IRC operator.
@ - The user is a channel op in the channel listed in the first field.
+ - The user is voiced in the channel listed.
% - The user is a half-op in the channel listed.

The next field contains the username@host of the user.
The final field displays the number of server hops and
the user's GECOS information.

This command may be executed on a channel, such as
"WHO #lamers"  The output will consist of WHO
listings for each user on the channel.

This command may also be used in conjunction with wildcards
such as * and ?.

See also: whois, userhost
EOT
}

sub _whois {
  return << 'EOT'
WHOIS [remoteserver|nick] nick

WHOIS will display detailed user information for
the specified nick.  If the first parameter is
specified, WHOIS will display information from
the specified server, or the server that the
user is on.  This is how to remotely see
idle time and away status.
EOT
}

sub _whowas {
  return << 'EOT'
WHOWAS <nick> [count] [nick|server]

WHOWAS will show you brief information from the last time
the specified nick was connected or changed nickname.
Depending on the number of times they have connected,
there may be more than one listing for the specified nick.
You can limit how many of those listings will be shown
with the count parameter.

Specifying nick or server as an additional parameter forwards
the query to that server.

The WHOWAS data will expire after time.
EOT
}

sub _xline {
  return << 'EOT'
XLINE [time] <gecos> :[reason]

[time] if present, gives number of minutes for XLINE

Adds a XLINE which will ban the specified gecos from
that server. The banned client will receive a message
saying he/she is banned with reason [reason]

XLINE [time] <gecos> ON irc.server :[reason]
will xline the gecos on irc.server if irc.server accepts
remote xlines.

- Requires Oper Priv: xline
EOT
}

'Help! I need somebody!';

=encoding utf8

=head1 NAME

POE::Component::Server::IRC::Help - Help text for POE::Component::Server::IRC

=head1 DESCRIPTION

POE::Component::Server::IRC::Help is a helper module for
L<POE::Component::Server::IRC> which contains all the help files for
the C<HELP> command.

=head1 CONSTRUCTOR

=head2 new

Creates a C<new> object.

=head1 METHODS

=head2 topic

Takes a help topic. Returns C<undef> if there was an error or the topic
does not exist. Returns in list context the lines of topic text or in
scalar context an C<ARRAYREF> of lines of topic text.

=head1 AUTHOR

Chris 'BinGOs' Williams

=head1 LICENSE

Copyright C<(c)> Chris Williams

This module may be used, modified, and distributed under the same terms as
Perl itself. Please see the license that came with your Perl distribution
for details.

=head1 SEE ALSO

L<POE::Component::Server::IRC|POE::Component::Server::IRC>

=cut
