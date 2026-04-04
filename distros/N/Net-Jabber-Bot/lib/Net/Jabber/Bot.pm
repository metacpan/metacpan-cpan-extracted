package Net::Jabber::Bot;

use 5.010;
use Moo;
use Types::Standard qw(Int HashRef Str Maybe ArrayRef Bool CodeRef InstanceOf Num);
use Type::Tiny;

use version;
use Net::Jabber;
use Time::HiRes;
use Sys::Hostname;
use Log::Log4perl qw(:easy);
use Mozilla::CA;

my $PosInt     = Type::Tiny->new( name => 'PosInt',     parent => Int, constraint => sub { $_ > 0 } );
my $PosNum     = Type::Tiny->new( name => 'PosNum',     parent => Num, constraint => sub { $_ > 0 } );
my $NonNegNum  = Type::Tiny->new( name => 'NonNegNum',  parent => Num, constraint => sub { $_ >= 0 } );
my $HundredInt = Type::Tiny->new( name => 'HundredInt', parent => Num, constraint => sub { $_ > 100 } );

my $CoercedBool = Bool->plus_coercions( Str, sub { ( $_ =~ m/(^on$)|(^true$)/i ) + 0 } );

has jabber_client => (
    isa     => Maybe [ InstanceOf ['Net::Jabber::Client'] ],
    is      => 'rw',
    default => sub { Net::Jabber::Client->new }
);

has 'client_session_id' => ( isa => Str,         is   => 'rw' );
has 'connect_time'      => ( isa => $PosInt,     is   => 'rw', default => 9_999_999_999 );
has 'forum_join_grace'  => ( isa => $NonNegNum,  is   => 'rw', default => 10 );
has 'server_host'       => ( isa => Str,         is   => 'rw', lazy    => 1, default => sub { shift->server } );
has 'server'            => ( isa => Str,         is   => 'rw' );
has 'port'              => ( isa => $PosInt,     is   => 'rw', default => 5222 );
has 'gtalk'             => ( isa => Bool,        is   => 'rw', default => '0' );
has 'tls'               => ( isa => Bool,        is   => 'rw', default => '0' );
has 'ssl_ca_path'       => ( isa => Str,         is   => 'rw', default => Mozilla::CA::SSL_ca_file() );
has 'ssl_verify'        => ( isa => Bool,        is   => 'rw', default => '1' );
has 'connection_type'   => ( isa => Str,         is   => 'rw', default => 'tcpip' );
has 'conference_server' => ( isa => Str,         is   => 'rw' );
has 'username'          => ( isa => Str,         is   => 'rw' );
has 'password'          => ( isa => Str,         is   => 'rw' );
has 'alias'             => ( isa => Str,         lazy => 1, is => 'rw', default => 'net_jabber_bot' );

# Resource defaults to alias_hostname_pid
has 'resource'            => ( isa => Str, lazy => 1, is => 'rw', default => sub { shift->alias . "_" . hostname . "_" . $$ } );
has 'message_function'    => ( isa => Maybe [CodeRef], is => 'rw', default => sub { undef } );
has 'background_function' => ( isa => Maybe [CodeRef], is => 'rw', default => sub { undef } );
has 'loop_sleep_time'     => ( isa => $PosNum, is => 'rw', default => 5 );
has 'process_timeout'     => ( isa => $PosNum, is => 'rw', default => 5 );
has 'from_full'           => (
    isa     => Str,
    lazy    => 1,
    is      => 'rw',
    default => sub {
        my $self = shift;
        ($self->username || '') . '@' . ($self->server || '') . '/' . ($self->resource || '');
    }
);

has 'safety_mode'             => ( isa => $CoercedBool, is => 'rw', default => 1, coerce => 1 );
has 'ignore_server_messages'  => ( isa => $CoercedBool, is => 'rw', default => 1, coerce => 1 );
has 'ignore_self_messages'    => ( isa => $CoercedBool, is => 'rw', default => 1, coerce => 1 );
has 'auto_subscribe'          => ( isa => $CoercedBool, is => 'rw', default => 1, coerce => 1 );
has 'forums_and_responses'    => ( isa => HashRef [ ArrayRef [Str] ], is => 'rw' );              # List of forums we're in and the strings we monitor for.
has 'forum_join_time'         => ( isa => HashRef [Int], is => 'rw', default => sub { {} } );    # List of when we joined each forum
has 'out_messages_per_second' => ( isa => $PosNum, is => 'rw', default => sub { 5 } );
has 'message_delay'           => ( isa => $PosNum, is => 'rw', default => sub { 1 / 5 } );

has 'max_message_size'      => ( isa => $HundredInt, is => 'rw', default => 1000000 );
has 'max_messages_per_hour' => ( isa => $PosInt,     is => 'rw', default => 1000000 );

# Initialize this hour's message count.
has 'messages_sent_today' => (
    isa     => HashRef,
    is      => 'ro',
    default => sub {
        { (localtime)[7] => { (localtime)[2] => 0 } }
    }
);

has '_running' => ( isa => Bool, is => 'rw', default => 0 );


=for markdown [![testsuite](https://github.com/cpan-authors/perl-net-jabber-bot/actions/workflows/testsuite.yml/badge.svg)](https://github.com/cpan-authors/perl-net-jabber-bot/actions/workflows/testsuite.yml)

=head1 NAME

Net::Jabber::Bot - Automated Bot creation with safeties

=head1 VERSION

Version 3.01

=cut

our $VERSION = '3.01';

=head1 SYNOPSIS

Program design:
This is a Moo based Class.

The idea behind the module is that someone creating a bot should not really have to know a whole lot about how the Jabber protocol works in order to use it. It also allows us to abstract away all the things that can get a bot maker into trouble. Essentially the object helps protect the coders from their own mistakes.

All someone should have to know and define in the program away from the object is:

=over

=item 1. Config - Where to connect, how often to do things, timers, etc

=item 2. A subroutine to be called by the bot object when a new message comes in.

=item 3. A subroutine to be called by the bot object every so often that lets the user do background activities (check logs, monitor web pages, etc.),

=back

The object at present has the following enforced safeties as long as you do not override safety mode:

=over

=item 1. Limits messages per second, configurable at start up, (Max is 5 per second) by requiring a sleep timer in the message sending subroutine each time one is sent.

=item 2. Endless loops of responding to self prevented by now allowing the bot message processing subroutine to know about messages from self

=item 3. Forum join grace period to prevent bot from reacting to historical messages

=item 4. Configurable aliases the bot will respond to per forum

=item 5. Limits maximum message size, preventing messages that are too large from being sent (largest configurable message size limit is 1000).

=item 6. Automatic chunking of messages to split up large messages in message sending subroutine

=item 7. Limit on messages per hour. (max configurable limit of 125) Messages are visible via log4perl, but not ever be sent once the message limit is reached for that hour.

=back

=head1 FUNCTIONS

=over 4

=item B<new>

Minimal:

    my $bot = Net::Jabber::Bot->new(
        server               => 'host.domain.com', # Name of server when sending messages internally.
        conference_server    => 'conference.host.domain.com',
        port                 => 522,
        username             => 'username',
        password             => 'pasword',
        safety_mode          => 1,
        message_function     => \&new_bot_message,
        background_function  => \&background_checks,
        forums_and_responses => \%forum_list
    );

All options:

    my $bot = Net::Jabber::Bot->new(
        server                  => 'host.domain.com', # Name of server when sending messages internally.
        conference_server       => 'conference.host.domain.com',
        server_host             => 'talk.domain.com', # used to specify what jabber server to connect to on connect?
        tls                     => 0,                    # set to 1 for google
        ssl_ca_path             => '',  # path to your CA cert bundle
        ssl_verify              => 0,   # for testing and for self-signed certificates
        connection_type         => 'tcpip',
        port                    => 522,
        username                => 'username',
        password                => 'pasword',
        alias                   => 'cpan_bot',
        message_function        => \&new_bot_message,
        background_function     => \&background_checks,
        loop_sleep_time         => 15,
        process_timeout         => 5,
        forums_and_responses    => \%forum_list,
        ignore_server_messages  => 1,
        ignore_self_messages    => 1,
        out_messages_per_second => 4,
        max_message_size        => 1000,
        max_messages_per_hour   => 100
    );


Set up the object and connect to the server. Hash values are passed to new as a hash.

The following initialization variables can be passed. Only marked variables are required (TODO)

=over 5

=item B<safety_mode>

    safety_mode = (1,0)

Determines if the bot safety features are turned on and enforced. This mode is on by default. Many of the safety features are here to assure you do not crash your favorite jabber server with floods, etc. DO NOT turn it off unless you're sure you know what you're doing (not just Sledge Hammer certain)

=item B<server>

Jabber server name

=item B<server_host>

Defaults to the same value set for 'server' above.
This is where the bot initially connects. For google for instance, you should set this to 'gmail.com'

=item B<conference_server>

Conference server (usually conference.$server_name)

=item B<port>

Defaults to 5222

=item B<gtalk>

Boolean value. defaults to 0. Set to 1 for Google Talk connections. This automatically enables TLS and sets server_host to 'gmail.com' (unless you provide your own server_host).

=item B<tls>

Boolean value. defaults to 0. for google, it is know that this value must be 1 to work.

=item B<ssl_ca_path>

The path to your CA cert bundle. This is passed on to XML::Stream eventually.

=item B<ssl_verify>

Enable or disable server certificate validity check when connecting to server. This is passed on to XML::Stream eventually.

=item B<connection_type>

defaults to 'tcpip' also takes 'http'

=item B<username>

The user you authenticate with to access the server. Not full name, just the stuff to the left of the @...

=item B<password>

password to get into the server

=item B<alias>

This will be your nickname in chat rooms. The XMPP resource (used for login and presence) defaults to C<alias_hostname_pid> to ensure uniqueness across multiple bot instances.

=item B<forums_and_responses>

A hash ref which lists the forum names to join as the keys and the values are an array reference to a list of strings they are supposed to be responsive to.
The array is order sensitive and an empty string means it is going to respond to all messages in this forum. Make sure you list this last.

The found 'response string' is assumed to be at the beginning of the message. The message_funtion function will be called with the modified string.

    alias = jbot:, attention:

example1:

    message: 'jbot: help'

    passed to callback: 'help'

=item B<message_function>

The subroutine the bot will call when a new message is received by the bot. Only called if the bot's logic decides it's something you need to know about.

=item B<background_function>

The subroutine the bot will call when every so often (loop_sleep_time) to allow you to do background activities outside jabber stuff (check logs, web pages, etc.)

=item B<loop_sleep_time>

Frequency background function is called.

=item B<process_timeout>

Time Process() will wait if no new activity is received from the server

=item B<ignore_server_messages>

Boolean value as to whether we should ignore messages sent to us from the jabber server (addresses can be a little cryptic and hard to process)

=item B<ignore_self_messages>

Boolean value as to whether we should ignore messages sent by us.

BE CAREFUL if you turn this on!!! Turning this on risks potentially endless loops. If you're going to do this, please be sure safety is turned on at least initially.

=item B<auto_subscribe>

Boolean value controlling whether the bot automatically accepts presence subscription requests from any JID. Defaults to 1 (enabled) for backward compatibility. Set to 0 to ignore subscription requests, which prevents unknown users from tracking the bot's online status.

=item B<out_messages_per_second>

Limits the number of messages per second. Number must be E<gt> 0

default: 5

safety: 5

=item B<max_message_size>

Specify maximimum size a message can be before it's split and sent in pieces.

default: 1,000,000

safety: 1,000

=item B<max_messages_per_hour>

Limits the number of messages per hour before we refuse to send them

default: 125

safety: 166

=back

=cut

# Handle initialization of objects of this class...
sub BUILD {
    my ( $self, $params ) = @_;

    # Deal with legacy bug
    if ( $params->{background_activity} || $params->{message_callback} ) {
        my $warn_message = "\n\n" . "*" x 70 . "\n" . "WARNING!!! You're using old parameters for your bot initialization\n" . "'message_callback' should be changed to 'message_function'\n" . "'background_activity' should be changed to 'background_function'\n" . "I'm correcting this, but you should fix your code\n" . "*" x 70 . "\n" . "\n\n";
        warn($warn_message);
        WARN($warn_message);

        $self->background_function( $params->{background_activity} )
          if ( !$self->background_function && $params->{background_activity} );
        $self->message_function( $params->{message_callback} )
          if ( !$self->message_function && $params->{message_callback} );
        # sleep removed — the warning above is sufficient to alert developers
    }

    # GTalk convenience: auto-configure TLS and server_host for Google Talk
    if ( $self->gtalk ) {
        $self->tls(1);
        $self->server_host('gmail.com') if ( !$params->{server_host} );
    }

    # Message delay is inverse of out_messages_per_second
    $self->message_delay( 1 / $self->out_messages_per_second );

    # Enforce all our safety restrictions here.
    if ( $self->safety_mode ) {

        # more than 5 messages per second risks server flooding.
        $self->message_delay( 1 / 5 ) if ( $self->message_delay < 1 / 5 );

        # Messages should be small to not overwhelm rooms/people/server
        $self->max_message_size(1000) if ( $self->max_message_size > 1000 );

        # More than 4,000 messages a day is a little excessive.
        $self->max_messages_per_hour(125) if ( $self->max_messages_per_hour > 166 );

        # Should not be responding to self messages to prevent loops.
        $self->ignore_self_messages(1);
    }

    #Initialize the connection.
    $self->_init_jabber;
}

# Return a code reference that will pass self in addition to arguements passed to callback code ref.
sub _callback_maker {
    my $self     = shift;
    my $Function = shift;

    #    return sub {return $code_ref->($self, @_);};
    return sub { return $Function->( $self, @_ ); };
}

# Creates client object and manages connection. Called on new but also called by re-connect
sub _init_jabber {
    my $self = shift;

    # Create a new client if we don't have one (e.g., after disconnect/reconnect)
    $self->jabber_client( Net::Jabber::Client->new ) if !defined $self->jabber_client;

    my $connection = $self->jabber_client;

    DEBUG("Set the call backs.");
    $connection->PresenceDB();    # Init presence DB.
    $connection->RosterDB();      # Init Roster DB.
    $connection->SetCallBacks(
        'message' => $self->_callback_maker( \&_process_jabber_message ), 'presence' => $self->_callback_maker( \&_jabber_presence_message )
        , 'iq' => $self->_callback_maker( \&_jabber_in_iq_message )
    );

    DEBUG( "Connect. hostname => " . $self->server . ", port => " . $self->port );
    my %client_connect_hash = (
        hostname       => $self->server,
        port           => $self->port,
        tls            => $self->tls,
        ssl_ca_path    => $self->ssl_ca_path,
        ssl_verify     => $self->ssl_verify,
        connectiontype => $self->connection_type,
        componentname  => $self->server_host,
    );

    my $status = $connection->Connect(%client_connect_hash);

    if ( !defined $status ) {
        ERROR("ERROR:  Jabber server is down or connection was not allowed: $!");
        die("Jabber server is down or connection was not allowed: $!");
    }

    DEBUG( "Logging in... as user " . $self->username . " / " . $self->resource );
    DEBUG( "PW: ********" );

    # Moved into connect hash via 'componentname'
    #    my $sid = $connection->{SESSION}->{id};
    #    $connection->{STREAM}->{SIDS}->{$sid}->{hostname} = $self->server_host;

    my @auth_result = $connection->AuthSend(
        username => $self->username,
        password => $self->password,
        resource => $self->resource,
    );

    if ( !defined $auth_result[0] || $auth_result[0] ne "ok" ) {
        ERROR( "Authorization failed: for " . $self->username . " / " . $self->resource );
        foreach my $result (@auth_result) {
            ERROR("$result");
        }
        die( "Failed to re-connect: " . join( "\n", @auth_result ) );
    }

    $connection->RosterRequest();

    $self->client_session_id( $connection->{SESSION}->{id} );

    DEBUG("Sending presence to tell world that we are logged in");
    $connection->PresenceSend();
    $self->Process(5);

    DEBUG("Getting Roster to tell server to send presence info");
    $connection->RosterGet();
    $self->Process(5);

    foreach my $forum ( keys %{ $self->forums_and_responses } ) {
        $self->JoinForum($forum);
    }

    INFO( "Connected to server '" . $self->server . "' successfully" );
    $self->connect_time(time);    # Track when we came online.
    return 1;
}

=item B<JoinForum>

Joins a jabber forum and sleeps safety time. Also prevents the object
from responding to messages for a grace period in efforts to get it to
not respond to historical messages. This has failed sometimes.

NOTE: No error detection for join failure is present at the moment. (TODO)

=cut

sub JoinForum {
    my $self       = shift;
    my $forum_name = shift;

    if ( !$self->IsConnected ) {
        WARN("Cannot join forum '$forum_name': not connected");
        return;
    }

    DEBUG( "Joining $forum_name on " . $self->conference_server . " as " . $self->alias );

    $self->jabber_client->MUCJoin(
        room   => $forum_name,
        server => $self->conference_server,
        nick   => $self->alias,
    );

    $self->forum_join_time->{$forum_name} = time;
    DEBUG( "Sleeping " . $self->message_delay . " seconds" );
    Time::HiRes::sleep $self->message_delay;
}

=item B<Process>

Mostly calls it's client connection's "Process" call.
Also assures a timeout is enforced if not fed to the subroutine
You really should not have to call this very often.
You should mostly be calling Start() and just let the Bot kernel handle all this.

=cut

sub Process {    # Call connection process.
    my $self            = shift;
    my $timeout_seconds = shift;

    return if !$self->IsConnected;

    #If not passed explicitly
    $timeout_seconds = $self->process_timeout if ( !defined $timeout_seconds );

    my $process_return = $self->jabber_client->Process($timeout_seconds);
    return $process_return;
}

=item B<Start>

Primary subroutine save new called by the program. Runs a loop of:

=over

=item 1. Process

=item 2. If Process failed, Reconnect to server over larger and larger timeout

=item 3. run background process fed from new, telling it who I am and how many loops we have been through.

=item 4. Enforce a sleep to prevent server floods.

=back

The loop runs until Stop() is called. Returns the loop iteration count.

=cut

sub Start {
    my $self = shift;

    my $time_between_background_routines = $self->loop_sleep_time;
    my $process_timeout                  = $self->process_timeout;
    my $background_subroutine            = $self->background_function;
    my $message_delay                    = $self->message_delay;

    my $last_background = time - $time_between_background_routines - 1;    # Call background process every so often...
    my $counter         = 0;                                               # Keep track of how many times we've looped.

    $self->_running(1);

    while ( $self->_running ) {
                                                                           # Process and re-connect if you have to.
        my $process_result;
        eval { $process_result = $self->Process($process_timeout) };

        if ($@ || !defined $process_result) {                              #Assume the connection is down...
            my $error = $@ || "Process returned undef (connection lost)";
            ERROR("Server error: $error");
            my $message = "Disconnected from " . $self->server . ":" . $self->port . " as " . $self->username;

            ERROR("$message Reconnecting...");
            sleep 5;                                                       # TODO: Make re-connect time flexible somehow
            $self->ReconnectToServer();
        }

        # Call background function
        if ( defined $background_subroutine && $last_background + $time_between_background_routines < time ) {
            &$background_subroutine( $self, ++$counter );
            $last_background = time;
        }
        Time::HiRes::sleep $message_delay;
    }

    return $counter;
}

=item B<Stop>

    $bot->Stop();

Signals the Start() loop to exit after the current iteration completes.
Typically called from within the background_function or message_function callback.

=cut

sub Stop {
    my $self = shift;

    INFO("Stop requested, will exit Start() loop after current iteration");
    $self->_running(0);
    return 1;
}

=item B<ReconnectToServer>

You should not ever need to use this. the Start() kernel usually figures this out and calls it.

Internal process:

    1. Disconnects
    3. Re-initializes

=cut

sub ReconnectToServer {
    my $self = shift;

    my $background_subroutine = $self->background_function;

    $self->Disconnect();

    my $sleep_time = 5;
    while ( !$self->IsConnected() ) {    # jabber_client variable defines if we're connected.
        INFO("Sleeping $sleep_time before attempting re-connect");
        sleep $sleep_time;
        $sleep_time *= 2 if ( $sleep_time < 300 );
        eval { $self->_init_jabber() };
        if ($@) {
            WARN("Reconnection attempt failed: $@");
            # Clean up partial client state so IsConnected() stays false
            # and next _init_jabber() creates a fresh client
            $self->jabber_client(undef);
            next;
        }
        if ( defined $background_subroutine ) {
            INFO("Running background routine.");
            &$background_subroutine( $self, 0 );    # call background proc so we can check for errors while down.
        }
    }
}

=item B<Disconnect>

Disconnects from server if client object is defined. Assures the client object is deleted.

=cut

sub Disconnect {
    my $self = shift;

    $self->connect_time( '9' x 10 );    # Way in the future

    INFO("Disconnecting from server");
    return if ( !defined $self->jabber_client );    # do not proceed, no object.

    $self->jabber_client->Disconnect();
    my $old_client = $self->jabber_client;
    $self->jabber_client(undef);

    DEBUG("Disconnected.");
    return 1;
}

=item B<IsConnected>

Reports connect state (true/false) based on the status of client_start_time.

=cut

sub IsConnected {
    my $self = shift;

    return defined $self->jabber_client;
}

# TODO: ***NEED VERY GOOD DOCUMENTATION HERE*****

=item B<_process_jabber_message> - DO NOT CALL

Handles incoming messages.

=cut

sub _process_jabber_message {
    my $self = shift;
    DEBUG("_process_jabber_message called");

    my $session_id = shift;
    my $message    = shift;

    my $type      = $message->GetType();
    my $fromJID   = $message->GetFrom("jid");
    my $from_full = $message->GetFrom();

    my $from     = $fromJID->GetUserID();
    my $resource = $fromJID->GetResource();
    my $subject  = $message->GetSubject();
    my $body     = $message->GetBody();

    my $reply_to = $from_full;
    $reply_to =~ s/\/.*$// if ( $type eq 'groupchat' );

    # TODO:
    # Don't know exactly why but when a message comes from gtalk-web-interface, it works well, but if the message comes from Gtalk client, bot dies
    #   my $message_date_text;  eval { $message_date_text = $message->GetTimeStamp(); } ; # Eval is a really bad idea. we need to understand why this is failing.

    #    my $message_date_text = $message->GetTimeStamp(); # Since we're not using the data, we'll turn this off since it crashes gtalk clients aparently?
    #    my $message_date = UnixDate($message_date_text, "%s") - 1*60*60; # Convert to EST from CST;

    # Ignore any messages within 'forum_join_grace' seconds of start or join of that forum
    my $grace_period = $self->forum_join_grace;
    my $time_now     = time;
    if ( $self->connect_time > $time_now - $grace_period
        || ( defined $self->forum_join_time->{$from} && $self->forum_join_time->{$from} > $time_now - $grace_period ) ) {
        my $cond1 = $self->connect_time . " > $time_now - $grace_period";
        my $cond2 = ($self->forum_join_time->{$from} || 'undef') . " > $time_now - $grace_period";
        DEBUG("Ignoring messages cause I'm in startup for forum $from\n$cond1\n$cond2");
        return;    # Ignore messages the first few seconds.
    }

    # Ignore Group messages with no resource on them. (Server Messages?)
    if ( $self->ignore_server_messages ) {
        if ( $from_full !~ m/^([^\@]+)\@([^\/]+)\/(.+)$/ ) {
            DEBUG("Server message? ($from_full) - $message");
            return if ( $from_full !~ m/^([^\@]+)\@([^\/]+)\// );
            ERROR("Couldn't recognize from_full ($from_full). Ignoring message: $body");
            return;
        }
    }

    # Are these my own messages?
    if ( $self->ignore_self_messages ) {

        # In MUC (groupchat), the from JID resource is the room nickname (alias),
        # not the XMPP resource. Check both to handle direct and group messages.
        if ( defined $resource
            && ( $resource eq $self->resource
                || ( $type eq 'groupchat' && $resource eq $self->alias ) ) )
        {
            DEBUG("Ignoring message from self...\n");
            return;
        }
    }

    # Determine if this message was addressed to me. (groupchat only)
    my $bot_address_from;
    my @aliases_to_respond_to = $self->get_responses($from);

    if ( $#aliases_to_respond_to >= 0 and $type eq 'groupchat' ) {
        my $request;
        foreach my $address_type (@aliases_to_respond_to) {
            my $qm_address_type = quotemeta($address_type);
            next if ( $body !~ m/^\s*$qm_address_type\s*(\S.*)$/ms );
            $request          = $1;
            $bot_address_from = $address_type;
            last;    # do not need to loop any more.
        }
        if ( !defined $request ) {
            DEBUG("Message not relevant to bot");
            return;
        }
        $body = $request;
    }

    # Call the message callback if it's defined.
    if ( defined $self->message_function ) {
        $self->message_function->(
            bot_object       => $self,
            from_full        => $from_full,
            body             => $body,
            type             => $type,
            reply_to         => $reply_to,
            bot_address_from => $bot_address_from,
            message          => $message
        );
        return;
    }
    else {
        WARN("No handler for messages!");
        INFO("New Message: $type from $from ($resource). sub=$subject -- $body");
    }
}

=item B<get_responses>

    $bot->get_responses($forum_name);

Returns the array of messages we are monitoring for in supplied forum or replies with undef.

=cut

sub get_responses {
    my $self = shift;

    my $forum = shift;

    if ( !defined $forum ) {
        WARN("No forum supplied for get_responses()");
        return;
    }

    my @aliases_to_respond_to;
    if ( defined $self->forums_and_responses->{$forum} ) {
        @aliases_to_respond_to = @{ $self->forums_and_responses->{$forum} };
    }

    return @aliases_to_respond_to;
}

=item B<_jabber_in_iq_message> - DO NOT CALL

Called when the client receives new messages during Process of this type.

=cut

sub _jabber_in_iq_message {
    my $self = shift;

    my $session_id = shift;
    my $iq         = shift;

    DEBUG( "IQ Message:" . $iq->GetXML() );
    my $from = $iq->GetFrom();

    #    my $type = $iq->GetType();DEBUG("Type=$type");
    my $query = $iq->GetQuery();    #DEBUG("query=" . Dumper($query));

    if ( !$query ) {
        DEBUG("iq->GetQuery() returned undef.");
        return;
    }

    my $xmlns = $query->GetXMLNS();
    DEBUG("xmlns=$xmlns");

    # Respond to version requests with information about myself.
    if ( $xmlns eq "jabber:iq:version" ) {

        # convert 5.010000 to 5.10.0
        my $perl_version = $];
        $perl_version =~ s/(\d{3})(?=\d)/$1./g;
        $perl_version =~ s/\.0+(\d)/.$1/g;

        $self->jabber_client->VersionSend(
            to   => $from,
            name => __PACKAGE__,
            ver  => $VERSION,
            os   => "Perl v$perl_version"
        );
    }
}

=item B<_jabber_presence_message> - DO NOT CALL

Called when the client receives new presence messages during Process.
Mostly we are just pushing the data down into the client DB for later processing.

=cut

sub _jabber_presence_message {
    my $self = shift;

    my $session_id = shift;
    my $presence   = shift;

    my $type = $presence->GetType();
    if ( $type eq 'subscribe' ) {
        my $from = $presence->GetFrom();
        if ( $self->auto_subscribe ) {
            $self->jabber_client->Subscription(
                type => "subscribe",
                to   => $from
            );
            $self->jabber_client->Subscription( type => "subscribed", to => $from );
            INFO("Processed subscription request from $from");
        }
        else {
            INFO("Ignored subscription request from $from (auto_subscribe disabled)");
        }
        return;
    }
    elsif ( $type eq 'unsubscribe' ) {
        my $from = $presence->GetFrom();
        $self->jabber_client->Subscription(
            type => "unsubscribed",
            to   => $from
        );
        INFO("Processed unsubscribe request from $from");
        return;
    }

    # Without explicitly setting a priority, XMPP::Protocol will store all JIDs with an empty
    # priority under the same key rather than in an array.
    $presence->SetPriority(0) unless $presence->GetPriority();

    $self->jabber_client->PresenceDBParse($presence);    # Since we are always an object just throw it into the db.

    my $from = $presence->GetFrom();
    $from = "." if ( !defined $from );

    my $status = $presence->GetStatus();
    $status = "." if ( !defined $status );

    DEBUG("Presence From $from t=$type s=$status");
    DEBUG( "Presence XML: " . $presence->GetXML() );
}

=item B<respond_to_self_messages>

    $bot->respond_to_self_messages($value = 1);


Tells the bot to start reacting to it\'s own messages if non-zero is passed. Default is 1.

=cut

sub respond_to_self_messages {
    my $self = shift;

    my $setting = shift;
    $setting = 1 if ( !defined $setting );

    $self->ignore_self_messages( !$setting );
    return !!$setting;
}

=item B<get_messages_this_hour>

    $bot->get_messages_this_hour();

Returns the number of messages sent so far this hour.

=cut

sub get_messages_this_hour {
    my $self = shift;

    my $yday               = (localtime)[7];
    my $hour               = (localtime)[2];
    my $messages_this_hour = $self->messages_sent_today->{$yday}->{$hour};
    return $messages_this_hour || 0;    # Assure it's not undef to avoid math warnings
}

=item B<get_safety_mode>

Validates that we are in safety mode. Returns a bool as long as we are an object, otherwise returns undef

=cut

sub get_safety_mode {
    my $self = shift;

    # Must be in safety mode and all thresholds met.
    my $mode =
         $self->safety_mode
      && $self->message_delay >= 1 / 5
      && $self->max_message_size <= 1000
      && $self->max_messages_per_hour <= 166
      && $self->ignore_self_messages;

    return $mode || 0;
}

=item B<SendGroupMessage>

    $bot->SendGroupMessage($name, $message);
    $bot->SendGroupMessage($name, $message, $from);

Tells the bot to send a message to the recipient room name.

$from is an optional JID to set as the sender of the message.
Note that most XMPP servers will not allow spoofing the from field
and may reject the message or disconnect the client.

=cut

sub SendGroupMessage {
    my $self      = shift;
    my $recipient = shift;
    my $message   = shift;
    my $from      = shift;

    $recipient .= '@' . $self->conference_server if ( $recipient !~ m{\@} );

    return $self->SendJabberMessage( $recipient, $message, 'groupchat', undef, $from );
}

=item B<SendPersonalMessage>

    $bot->SendPersonalMessage($recipient, $message);
    $bot->SendPersonalMessage($recipient, $message, $from);

How to send an individual message to someone.

$recipient must read as user@server/Resource or it will not send.

$from is an optional JID to set as the sender of the message.
Note that most XMPP servers will not allow spoofing the from field
and may reject the message or disconnect the client.

=cut

sub SendPersonalMessage {
    my $self      = shift;
    my $recipient = shift;
    my $message   = shift;
    my $from      = shift;

    return $self->SendJabberMessage( $recipient, $message, 'chat', undef, $from );
}

=item B<SendJabberMessage>

    $bot->SendJabberMessage($recipient, $message, $message_type, $subject, $from);

The master subroutine to send a message. Called either by the user, SendPersonalMessage, or SendGroupMessage. Sometimes there
is call to call it directly when you do not feel like figuring you messaged you.
Assures message size does not exceed a limit and chops it into pieces if need be.

NOTE: non-printable characters (unicode included) will be replaced with a dot before sending to the server.
Newlines (LF and CR) are preserved so that multiline messages work correctly.

    s/[^\r\n[:print:]]+/./xmsg

=cut

sub SendJabberMessage {
    my $self = shift;

    my $recipient    = shift;
    my $message      = shift;
    my $message_type = shift;
    my $subject      = shift;
    my $from         = shift;

    my $max_size = $self->max_message_size;

    # Split the message into chunks of at most max_message_size characters.
    # Prefer breaking at newlines, then spaces, then hard chop.
    my @message_chunks;
    my $remaining = $message;
    while ( length $remaining ) {
        if ( length $remaining <= $max_size ) {
            push @message_chunks, $remaining;
            last;
        }
        my $chunk = substr( $remaining, 0, $max_size );
        my $break_pos;

        # Prefer breaking at the last newline within the chunk
        my $nl_pos = rindex( $chunk, "\n" );
        if ( $nl_pos >= 0 ) {
            $break_pos = $nl_pos + 1;    # include the newline
        }
        else {
            # Fall back to the last space
            my $sp_pos = rindex( $chunk, " " );
            if ( $sp_pos >= 0 ) {
                $break_pos = $sp_pos + 1;    # include the space
            }
            else {
                $break_pos = $max_size;      # hard chop
            }
        }

        push @message_chunks, substr( $remaining, 0, $break_pos );
        $remaining = substr( $remaining, $break_pos );
    }

    DEBUG("Max message = $max_size. Splitting...") if ( $#message_chunks > 0 );
    my $return_value;
    foreach my $message_chunk (@message_chunks) {
        my $msg_return = $self->_send_individual_message( $recipient, $message_chunk, $message_type, $subject, $from );
        if ( defined $msg_return ) {
            $return_value = ( defined $return_value ? $return_value : '' ) . $msg_return;
        }
    }
    return $return_value;
}

# $self->_send_individual_message($recipient, $message_chunk, $message_type, $subject);
# Private subroutine only called directly by SetForumSubject and SendJabberMessage.
# There are a bunch of fancy things this does, but the important things are:
# 1. sleep a minimum of .2 seconds every message
# 2. Make sure we have not sent too many messages this hour and block sends if they are attempted over a certain limit (max limit is 125)
# 3. Strip out special characters that will get us booted from the server.

sub _send_individual_message {
    my $self = shift;

    my $recipient     = shift;
    my $message_chunk = shift;
    my $message_type  = shift;
    my $subject       = shift;
    my $from          = shift;

    if ( !defined $message_type ) {
        ERROR("Undefined \$message_type");
        return "No message type!\n";
    }

    if ( !defined $recipient ) {
        ERROR('$recipient not defined!');
        return "No recipient!\n";
    }

    # Check connection first — don't count messages that can't actually be sent.
    # Otherwise, messages attempted during disconnection inflate the hourly
    # counter and can exhaust the limit before real messages are sent.
    if ( !$self->IsConnected ) {
        $subject       = "" if ( !defined $subject );          # Keep warning messages quiet.
        $message_chunk = "" if ( !defined $message_chunk );    # Keep warning messages quiet.

        ERROR( "Can't send: Jabber server is down. Tried to send: \n" . "To: $recipient\n" . "Subject: $subject\n" . "Type: $message_type\n" . "Message sent:\n" . "$message_chunk" );

        return "Server is down.\n";
    }

    my $yday = (localtime)[7];
    my $hour = (localtime)[2];

    # Clean up entries from previous days to prevent unbounded memory growth
    for my $old_day ( keys %{ $self->messages_sent_today } ) {
        delete $self->messages_sent_today->{$old_day} if $old_day != $yday;
    }

    my $messages_this_hour = $self->messages_sent_today->{$yday}->{$hour} += 1;

    if ( $messages_this_hour > $self->max_messages_per_hour ) {
        $subject       = "" if ( !defined $subject );          # Keep warning messages quiet.
        $message_chunk = "" if ( !defined $message_chunk );    # Keep warning messages quiet.

        my $max_per_hour = $self->max_messages_per_hour;
        ERROR( "Can't send message because we've already tried to send $messages_this_hour of $max_per_hour messages this hour.\n" . "To: $recipient\n" . "Subject: $subject\n" . "Type: $message_type\n" . "Message sent:\n" . "$message_chunk" );

        # Send 1 panic message out to jabber if this is our last message before quieting down.
        return "Too many messages ($messages_this_hour)\n";
    }

    # Strip out anything that's not a printable character except new line, we want to be able to send multiline message, aren't we?
    # Now with unicode support?
    $message_chunk =~ s/[^\r\n[:print:]]+/./xmsg;

    my $message_length = length($message_chunk);
    DEBUG("Sending message $yday-$hour-$messages_this_hour $message_length bytes to $recipient");
    my %message_args = (
        to      => $recipient,
        body    => $message_chunk,
        type    => $message_type,
        subject => $subject,
    );
    $message_args{from} = $from if defined $from;
    $self->jabber_client->MessageSend(%message_args);

    DEBUG( "Sleeping " . $self->message_delay . " after sending message." );
    Time::HiRes::sleep $self->message_delay;    #Throttle messages.

    if ( $messages_this_hour == $self->max_messages_per_hour ) {
        $self->jabber_client->MessageSend(
            to => $recipient, body => "Cannot send more messages this hour. "
              . "$messages_this_hour of "
              . $self->max_messages_per_hour
              . " already sent."
            , type => $message_type
        );
    }
    return;                                     # Means we succeeded!
}

=item B<SetForumSubject>

    $bot->SetForumSubject($recipient, $subject);

Sets the subject of a forum

=cut

sub SetForumSubject {
    my $self = shift;

    my $recipient = shift;
    my $subject   = shift;

    if ( length $subject > $self->max_message_size ) {
        my $subject_len = length($subject);
        ERROR("Someone tried to send a subject message $subject_len bytes long!");
        $subject = substr( $subject, 0, $self->max_message_size );
        DEBUG("Truncated subject: $subject");
        return "Subject is too long!";
    }
    return $self->_send_individual_message( $recipient, "Setting subject to $subject", 'groupchat', $subject );
}

=item B<ChangeStatus>

    $bot->ChangeStatus($presence_mode, $status_string);

Sets the Bot's presence status.
$presence mode could be something like: (Chat, Available, Away, Ext. Away, Do Not Disturb).
$status_string is an optional comment to go with your presence mode. It is not required.

=cut

sub ChangeStatus {
    my $self          = shift;
    my $presence_mode = shift;
    my $status_string = shift;    # (optional)

    if ( !$self->IsConnected ) {
        WARN("Cannot change status: not connected");
        return 0;
    }

    $self->jabber_client->PresenceSend( show => $presence_mode, status => $status_string );

    return 1;
}

=item B<GetRoster>

    $bot->GetRoster();

Returns a list of the people logged into the server.
I suspect we really want to know who is in a particular forum right?
In which case we need another sub for this.
=cut

sub GetRoster {
    my $self = shift;

    if ( !$self->IsConnected ) {
        WARN("Cannot get roster: not connected");
        return ();
    }

    my @rosterlist;
    foreach my $jid ( $self->jabber_client->RosterDBJIDs() ) {
        my $username = $jid->GetJID();
        push( @rosterlist, $username );
    }
    return @rosterlist;
}

=item B<GetStatus>

    my $status = $bot->GetStatus($jid);

Returns the presence status of the given JID. Possible return values are
"unavailable" (if not connected or JID not found in the presence database),
"available" (if present with no specific show value), or the XMPP show value
(e.g. "away", "xa", "dnd", "chat").

=cut

sub GetStatus {

    my $self = shift;
    my ($jid) = shift;

    return "unavailable" if !$self->IsConnected;

    my $Pres = $self->jabber_client->PresenceDBQuery($jid);

    if ( !( defined($Pres) ) ) {

        return "unavailable";
    }

    my $show = $Pres->GetShow();
    if ($show) {

        return $show;
    }

    return "available";

}

=item B<AddUser>

    $bot->AddUser($jid);

Sends a subscription request to the given JID and auto-approves their
reciprocal subscription. This adds the user to the bot's roster and allows
mutual presence visibility.

=cut

sub AddUser {
    my $self = shift;
    my $user = shift;

    if ( !$self->IsConnected ) {
        WARN("Cannot add user '$user': not connected");
        return;
    }

    $self->jabber_client->Subscription( type => "subscribe",  to => $user );
    $self->jabber_client->Subscription( type => "subscribed", to => $user );
}

=item B<RmUser>

    $bot->RmUser($jid);

Sends an unsubscribe request for the given JID and revokes their subscription
to the bot's presence. This effectively removes the user from the bot's roster.

=cut

sub RmUser {
    my $self = shift;
    my $user = shift;

    if ( !$self->IsConnected ) {
        WARN("Cannot remove user '$user': not connected");
        return;
    }

    $self->jabber_client->Subscription( type => "unsubscribe",  to => $user );
    $self->jabber_client->Subscription( type => "unsubscribed", to => $user );
}

=back

=head1 AUTHOR

Todd Rinaldo C<< <toddr@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through the GitHub issue tracker at
L<https://github.com/cpan-authors/perl-net-jabber-bot/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Jabber::Bot

You can also look for information at:

=over 4

=item * Metacpan

L<https://metacpan.org/pod/Net::Jabber::Bot>

=item * GitHub

L<https://github.com/cpan-authors/perl-net-jabber-bot>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Todd E Rinaldo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Net::Jabber::Bot
